"""
Slide Matching Processor Module
Matches lecture transcripts to PDF slide pages using multimodal embeddings
"""

import torch
from PIL import Image
import fitz  # PyMuPDF
import io
from tqdm import tqdm
from typing import Callable
import gc
import threading

from transformers import AutoModel

# Global lock for slide matching model initialization
# Protects CUDA initialization during model loading when multiple pipelines start simultaneously
_matching_init_lock = threading.Lock()

# Global lock for slide matching model inference
# Protects inference operations when multiple pipelines run simultaneously
# This prevents CUDA errors when the same model runs concurrent inference
_matching_inference_lock = threading.Lock()


class SlideMatchingProcessor:
    """
    Multimodal slide matching processor using vision-text embeddings.
    """

    def __init__(
        self,
        model_name: str = 'nvidia/llama-nemoretriever-colembed-3b-v1',
        device: str = 'cuda',
        batch_size: int = 4,
        use_image_batching: bool = True,
        image_batch_size: int = 4,
        jump_penalty: float = 1.5,
        backward_weight: float = 1.85,
        use_exponential_scaling: bool = True,
        exponential_scale: float = 2.785,
        use_confidence_boost: bool = True,
        confidence_threshold: float = 0.913,
        confidence_weight: float = 2.18,
        use_context_similarity: bool = True,
        context_weight: float = 0.04,
        context_update_rate: float = 0.24,
        min_sentence_length: int = 2
    ):
        """
        Initialize slide matching processor.

        Args:
            model_name: Pretrained multimodal model name
            device: Device to run on (cuda/cpu)
            batch_size: Batch size for text query embedding computation
            use_image_batching: Enable batched image embedding computation (default: True)
            image_batch_size: Batch size for image embedding when batching is enabled (default: 4)
            jump_penalty: Penalty for slide jumps
            backward_weight: Multiplier for backward jump penalty
            use_exponential_scaling: Apply exponential scaling to scores
            exponential_scale: Scale factor for exponential scaling
            use_confidence_boost: Boost scores when top2 is low
            confidence_threshold: Threshold for confidence boosting
            confidence_weight: Weight multiplier for confidence boost
            use_context_similarity: Enable context-aware scoring via EMA
            context_weight: Weight for context similarity contribution
            context_update_rate: Update rate for EMA
            min_sentence_length: Minimum sentence length (words) to use similarity score
        """
        self.model_name = model_name
        self.device = device
        self.batch_size = batch_size
        self.use_image_batching = use_image_batching
        self.image_batch_size = image_batch_size
        self.jump_penalty = jump_penalty
        self.backward_weight = backward_weight
        self.use_exponential_scaling = use_exponential_scaling
        self.exponential_scale = exponential_scale
        self.use_confidence_boost = use_confidence_boost
        self.confidence_threshold = confidence_threshold
        self.confidence_weight = confidence_weight
        self.use_context_similarity = use_context_similarity
        self.context_weight = context_weight
        self.context_update_rate = context_update_rate
        self.min_sentence_length = min_sentence_length
        self.model = None

        print(f"Initializing Slide Matching Processor")
        print(f"Model: {model_name}")
        print(f"Device: {device}")
        print(f"Text batch size: {batch_size}")
        print(f"Image batching: {'enabled' if use_image_batching else 'disabled'}")
        if use_image_batching:
            print(f"Image batch size: {image_batch_size}")

    def load_model(self):
        """Load multimodal model into memory."""
        # Use global lock only during model initialization
        # This prevents CUDA initialization conflicts when multiple pipelines load models simultaneously
        with _matching_init_lock:
            if self.model is not None:
                print("Model already loaded")
                return

            print('Loading NeMo Retriever model...')

            if torch.cuda.is_available():
                torch.cuda.reset_peak_memory_stats()

            self.model = AutoModel.from_pretrained(
                self.model_name,
                device_map = self.device,
                torch_dtype = torch.bfloat16,
                trust_remote_code = True,
                attn_implementation = "flash_attention_2",
            ).eval()

            print("Model loaded successfully!")

    def unload_model(self):
        """Unload model to free memory."""
        if self.model is not None:
            del self.model
            self.model = None
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()
            print("Slide matching model unloaded")

    def extract_pdf_pages(
        self,
        pdf_path: str,
        target_dpi: int = 150
    ) -> list[Image.Image]:
        """
        Extract all pages from PDF as images.

        Args:
            pdf_path: Path to PDF file
            target_dpi: DPI for page rendering

        Returns:
            List of PIL Images
        """
        print(f'Extracting pages from PDF: {pdf_path}')

        doc = fitz.open(pdf_path)
        page_images = []

        for page_num in tqdm(range(doc.page_count), desc = 'Extracting PDF pages'):
            page = doc[page_num]

            scale = target_dpi / 72
            mat = fitz.Matrix(scale, scale)
            pix = page.get_pixmap(matrix = mat)
            img_data = pix.tobytes("png")

            image = Image.open(io.BytesIO(img_data)).convert('RGB')
            page_images.append(image)

        doc.close()
        print(f'Extracted {len(page_images)} pages')
        return page_images

    def compute_embeddings(
        self,
        queries: list[str],
        images: list[Image.Image]
    ) -> tuple:
        """
        Compute embeddings for queries and images.

        Args:
            queries: List of text queries
            images: List of page images

        Returns:
            Tuple of (query_embeddings, image_embeddings)
        """
        # Load model BEFORE acquiring inference lock to avoid deadlock
        # This ensures init_lock and inference_lock are never held simultaneously
        if self.model is None:
            self.load_model()

        # Use inference lock to prevent concurrent inference on the same model
        with _matching_inference_lock:
            print('Computing embeddings...')

            print('Processing text queries...')
            with torch.no_grad():
                query_embeddings = self.model.forward_queries(
                    queries,
                    batch_size = self.batch_size
                )

            print('Processing page images...')
            if self.use_image_batching:
                # Process images in batches for faster processing
                image_embeddings = []
                num_images = len(images)
                for i in tqdm(range(0, num_images, self.image_batch_size), desc = 'Processing image batches'):
                    batch = images[i:i + self.image_batch_size]
                    with torch.no_grad():
                        emb = self.model.forward_passages(batch, batch_size = len(batch))
                        image_embeddings.append(emb)
                image_embeddings = torch.cat(image_embeddings, dim = 0)
            else:
                # Process images one by one to avoid shared memory errors
                image_embeddings = []
                for image in tqdm(images, desc = 'Processing images'):
                    with torch.no_grad():
                        emb = self.model.forward_passages([image], batch_size = 1)
                        image_embeddings.append(emb)
                image_embeddings = torch.cat(image_embeddings, dim = 0)

            print(f'Query embeddings shape: {query_embeddings.shape}')
            print(f'Image embeddings shape: {image_embeddings.shape}')

            return query_embeddings, image_embeddings

    def match_with_dp(
        self,
        query_embeddings: torch.Tensor,
        image_embeddings: torch.Tensor,
        queries: list[str]
    ) -> list[dict]:
        """
        Match queries to slides using dynamic programming.

        Args:
            query_embeddings: Query embeddings tensor
            image_embeddings: Image embeddings tensor
            queries: Original query texts

        Returns:
            List of matching results
        """
        print('Finding best matches with DP and jump penalty')

        with torch.no_grad():
            scores = self.model.get_scores(query_embeddings, image_embeddings)

        # Normalize scores
        max_scores_per_query = torch.max(scores, dim = 1, keepdim = True)[0]
        scores = scores / max_scores_per_query

        # Apply exponential scaling if enabled (Apply before confidence boost)
        if self.use_exponential_scaling:
            scores = torch.exp(self.exponential_scale * (scores - 1))
            print(f'Applied exponential scaling with scale = {self.exponential_scale}')

        # Apply confidence boost if enabled
        if self.use_confidence_boost:
            top2_scores, _ = torch.topk(scores, k = 2, dim = 1)
            top2_norm_scores = top2_scores[:, 1]

            boost_mask = (top2_norm_scores < self.confidence_threshold).unsqueeze(1)
            scores = torch.where(
                boost_mask,
                scores * self.confidence_weight,
                scores
            ) # use broadcasting

            boost_count = boost_mask.sum().item()
            print(f'Applied confidence boost to {boost_count}/{len(top2_norm_scores)} queries')

        assert scores.dtype == torch.float32
        num_queries, num_pages = scores.shape

        # Dynamic Programming with jump penalty
        dp = torch.full((num_queries, num_pages), float('-inf'), device = self.device, dtype = torch.float32)
        backtrack = torch.zeros((num_queries, num_pages), device = self.device, dtype = torch.long)

        # Initialize first query
        # Check if first sentence meets minimum length (count words)
        first_word_count = len(queries[0].split())
        first_sentence_long_enough = first_word_count >= self.min_sentence_length

        if first_sentence_long_enough:
            dp[0, :] = scores[0, :]
        else:
            # For short sentences, assign zero score (only jump penalty will apply)
            dp[0, :] = 0.0

        # Initialize context scores (EMA of similarity scores per slide)
        context_scores = torch.zeros(num_pages, device = self.device, dtype = torch.float32)
        if self.use_context_similarity and first_sentence_long_enough:
            context_scores = self.context_update_rate * (scores[0, :] - context_scores)

        # Precompute jump penalty matrix (num_pages x num_pages)
        # penalty[k, j] = penalty when jumping from slide k to slide j
        pages_idx = torch.arange(num_pages, device = self.device)
        k_grid = pages_idx.unsqueeze(1) # [num_pages, 1]
        j_grid = pages_idx.unsqueeze(0) # [1, num_pages]

        # Forward jumps: k < j, penalty = (j - k - 1) * jump_penalty
        forward_penalty = (j_grid - k_grid - 1) * self.jump_penalty

        # Backward jumps: j < k, penalty = (k - j) * jump_penalty * backward_weight
        backward_penalty = (k_grid - j_grid) * self.jump_penalty * self.backward_weight

        # Combined penalty matrix
        penalty_matrix = torch.where(k_grid < j_grid, forward_penalty, backward_penalty)

        # Fill DP table
        for i in range(1, num_queries):
            # Check if current sentence meets minimum length (count words)
            word_count = len(queries[i].split())
            sentence_long_enough = word_count >= self.min_sentence_length

            if sentence_long_enough:
                current_score = scores[i, :].unsqueeze(0) # [1, num_pages]

                if self.use_context_similarity:
                    current_score += self.context_weight * context_scores.unsqueeze(0)
            else:
                # For short sentences, use zero score (only jump penalty applies)
                current_score = torch.zeros(1, num_pages, device = self.device, dtype = torch.float32)

            # Vectorized DP transition
            prev_dp = dp[i - 1, :].unsqueeze(1) # [num_pages, 1]
            current_score_grid = current_score.expand(num_pages, num_pages) # [num_pages, num_pages]

            # scores_with_penalty[k,  j] = dp[i - 1, k] + score[i, j] - penalty[k, j]
            scores_with_penalty = prev_dp + current_score_grid - penalty_matrix

            # Find best previous page k for each current page j
            dp[i, :], backtrack[i, :] = torch.max(scores_with_penalty, dim = 0)

            # Update context scores (skip if sentence is too short)
            if self.use_context_similarity and sentence_long_enough:
                context_scores += self.context_update_rate * (scores[i, :] - context_scores)

        # Backtrack to find optimal path
        best_matches = torch.zeros(num_queries, device = self.device, dtype = torch.long)
        best_matches[-1] = torch.argmax(dp[-1, :])

        for i in range(num_queries - 2, -1, -1):
            best_matches[i] = backtrack[i + 1, best_matches[i + 1]]

        # Get confidence scores
        query_indices = torch.arange(num_queries, device = self.device)
        confidence_scores = scores[query_indices, best_matches]

        # Build results
        results = []
        for i, query in enumerate(queries):
            result = {
                "text": query,
                "matched_page": int(best_matches[i].item()) + 1,  # 1-based index
                "confidence_score": float(confidence_scores[i].item())
            }
            results.append(result)

        return results

    def match_transcript_to_slides(
        self,
        transcript: str,
        pdf_path: str,
        sentences: list[str] | None = None,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> list[dict]:
        """
        Match transcript to PDF slides.

        Args:
            transcript: Full transcript text (used if sentences not provided)
            pdf_path: Path to PDF file
            sentences: Optional pre-split sentences (if None, uses full transcript as one query)
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            List of matching results with page numbers
        """
        # Load model BEFORE acquiring inference lock to avoid deadlock
        # This ensures init_lock and inference_lock are never held simultaneously
        if self.model is None:
            self.load_model()

        print("="*60)
        print("Slide Matching")
        print("="*60)

        if progress_callback:
            progress_callback(0.0, "Extracting PDF pages...")

        # Extract PDF pages
        page_images = self.extract_pdf_pages(pdf_path)

        # Prepare queries
        if sentences is None:
            # Use full transcript as single query
            queries = [transcript]
        else:
            queries = sentences

        print(f"Matching {len(queries)} queries to {len(page_images)} slides")

        if progress_callback:
            progress_callback(30.0, "Computing embeddings...")

        # Compute embeddings
        query_embeddings, image_embeddings = self.compute_embeddings(queries, page_images)

        if progress_callback:
            progress_callback(70.0, "Matching slides...")

        # Match with DP
        results = self.match_with_dp(query_embeddings, image_embeddings, queries)

        print(f"\nMatching complete: {len(results)} results")

        if progress_callback:
            progress_callback(100.0, "Matching completed")

        if torch.cuda.is_available():
            max_memory = torch.cuda.max_memory_allocated() / 1024**3
            print(f'Max GPU memory usage: {max_memory:.2f} GB')

        return results


if __name__ == "__main__":
    # Example usage
    processor = SlideMatchingProcessor(
        use_image_batching = True,
        image_batch_size = 4,
        jump_penalty = 0.2,
        backward_weight = 2.0,
        use_exponential_scaling = True,
        exponential_scale = 2.8,
        use_confidence_boost = True,
        confidence_threshold = 0.925,
        confidence_weight = 2.25,
        use_context_similarity = True,
        context_weight = 0.05,
        context_update_rate = 0.25,
        min_sentence_length = 3
    )

    # Example: match a transcript to slides
    transcript = "This is a sample lecture transcript about deep learning."
    results = processor.match_transcript_to_slides(
        transcript = transcript,
        pdf_path = "lecture_slides.pdf"
    )

    for result in results:
        print(f"Page {result['matched_page']}: {result['text'][:50]}... (score: {result['confidence_score']:.3f})")
