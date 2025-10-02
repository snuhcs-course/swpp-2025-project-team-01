"""
Slide Matching Processor Module
Matches lecture transcripts to PDF slide pages using multimodal embeddings
"""

import torch
import numpy as np
from PIL import Image
import fitz  # PyMuPDF
import io
from tqdm import tqdm
from typing import List, Dict, Optional
from pathlib import Path
import gc

from transformers import AutoModel


class SlideMatchingProcessor:
    """
    Multimodal slide matching processor using vision-text embeddings.
    """

    def __init__(
        self,
        model_name: str = 'nvidia/llama-nemoretriever-colembed-3b-v1',
        device: str = 'cuda',
        batch_size: int = 4,
        jump_penalty: float = 0.1,
        backward_weight: float = 2.0,
        use_exponential_scaling: bool = False,
        exponential_scale: float = 3.0,
        use_confidence_boost: bool = False,
        confidence_threshold: float = 0.95,
        confidence_weight: float = 1.5
    ):
        """
        Initialize slide matching processor.

        Args:
            model_name: Pretrained multimodal model name
            device: Device to run on (cuda/cpu)
            batch_size: Batch size for embedding computation
            jump_penalty: Penalty for slide jumps
            backward_weight: Multiplier for backward jump penalty
            use_exponential_scaling: Apply exponential scaling to scores
            exponential_scale: Scale factor for exponential scaling
            use_confidence_boost: Boost scores when top2 is low
            confidence_threshold: Threshold for confidence boosting
            confidence_weight: Weight multiplier for confidence boost
        """
        self.model_name = model_name
        self.device = device
        self.batch_size = batch_size
        self.jump_penalty = jump_penalty
        self.backward_weight = backward_weight
        self.use_exponential_scaling = use_exponential_scaling
        self.exponential_scale = exponential_scale
        self.use_confidence_boost = use_confidence_boost
        self.confidence_threshold = confidence_threshold
        self.confidence_weight = confidence_weight
        self.model = None

        print(f"Initializing Slide Matching Processor")
        print(f"Model: {model_name}")
        print(f"Device: {device}")
        print(f"Batch size: {batch_size}")

    def load_model(self):
        """Load multimodal model into memory."""
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
    ) -> List[Image.Image]:
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
        queries: List[str],
        images: List[Image.Image]
    ) -> tuple:
        """
        Compute embeddings for queries and images.

        Args:
            queries: List of text queries
            images: List of page images

        Returns:
            Tuple of (query_embeddings, image_embeddings)
        """
        if self.model is None:
            self.load_model()

        print('Computing embeddings...')

        print('Processing text queries...')
        with torch.no_grad():
            query_embeddings = self.model.forward_queries(
                queries,
                batch_size = self.batch_size
            )

        print('Processing page images...')
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
        queries: List[str]
    ) -> List[Dict]:
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
        normalized_scores = scores / max_scores_per_query

        # Apply confidence boost if enabled
        if self.use_confidence_boost:
            top2_scores, _ = torch.topk(normalized_scores, k = 2, dim = 1)
            top2_norm_scores = top2_scores[:, 1]

            boost_mask = (top2_norm_scores < self.confidence_threshold).unsqueeze(1)
            normalized_scores = torch.where(
                boost_mask,
                normalized_scores * self.confidence_weight,
                normalized_scores
            )

            boost_count = boost_mask.sum().item()
            print(f'Applied confidence boost to {boost_count}/{len(top2_norm_scores)} queries')

        # Apply exponential scaling if enabled
        if self.use_exponential_scaling:
            normalized_scores = torch.exp(self.exponential_scale * (normalized_scores - 1))
            print(f'Applied exponential scaling with scale = {self.exponential_scale}')

        # Convert to numpy for DP
        scores_np = normalized_scores.cpu().numpy()
        num_queries, num_pages = scores_np.shape

        # Dynamic Programming with jump penalty
        dp = np.full((num_queries, num_pages), -np.inf)
        backtrack = np.zeros((num_queries, num_pages), dtype = int)

        # Initialize first query
        dp[0, :] = scores_np[0, :]

        # Fill DP table
        for i in range(1, num_queries):
            for j in range(num_pages):
                current_score = scores_np[i, j]

                # Try all possible previous page assignments
                for k in range(num_pages):
                    # Jump penalty
                    penalty = 0
                    if k < j:  # forward jump
                        penalty = (j - k - 1) * self.jump_penalty
                    elif j < k:  # backward jump
                        penalty = (k - j) * self.jump_penalty * self.backward_weight

                    score_with_penalty = dp[i - 1, k] + current_score - penalty

                    if score_with_penalty > dp[i, j]:
                        dp[i, j] = score_with_penalty
                        backtrack[i, j] = k

        # Backtrack to find optimal path
        best_matches = np.zeros(num_queries, dtype = int)
        best_matches[-1] = np.argmax(dp[-1, :])

        for i in range(num_queries - 2, -1, -1):
            best_matches[i] = backtrack[i + 1, best_matches[i + 1]]

        # Get confidence scores
        confidence_scores = np.array([
            scores_np[i, best_matches[i]] for i in range(num_queries)
        ])

        # Build results
        results = []
        for i, query in enumerate(queries):
            result = {
                "text": query,
                "matched_page": int(best_matches[i]) + 1,  # 1-based index
                "confidence_score": float(confidence_scores[i])
            }
            results.append(result)

        return results

    def match_transcript_to_slides(
        self,
        transcript: str,
        pdf_path: str,
        sentences: Optional[List[str]] = None
    ) -> List[Dict]:
        """
        Match transcript to PDF slides.

        Args:
            transcript: Full transcript text (used if sentences not provided)
            pdf_path: Path to PDF file
            sentences: Optional pre-split sentences (if None, uses full transcript as one query)

        Returns:
            List of matching results with page numbers
        """
        if self.model is None:
            self.load_model()

        print("="*60)
        print("Slide Matching")
        print("="*60)

        # Extract PDF pages
        page_images = self.extract_pdf_pages(pdf_path)

        # Prepare queries
        if sentences is None:
            # Use full transcript as single query
            queries = [transcript]
        else:
            queries = sentences

        print(f"Matching {len(queries)} queries to {len(page_images)} slides")

        # Compute embeddings
        query_embeddings, image_embeddings = self.compute_embeddings(queries, page_images)

        # Match with DP
        results = self.match_with_dp(query_embeddings, image_embeddings, queries)

        print(f"\nMatching complete: {len(results)} results")

        if torch.cuda.is_available():
            max_memory = torch.cuda.max_memory_allocated() / 1024**3
            print(f'Max GPU memory usage: {max_memory:.2f} GB')

        return results


if __name__ == "__main__":
    # Example usage
    processor = SlideMatchingProcessor(
        jump_penalty = 0.1,
        backward_weight = 2.0
    )

    # Example: match a transcript to slides
    transcript = "This is a sample lecture transcript about deep learning."
    results = processor.match_transcript_to_slides(
        transcript = transcript,
        pdf_path = "lecture_slides.pdf"
    )

    for result in results:
        print(f"Page {result['matched_page']}: {result['text'][:50]}... (score: {result['confidence_score']:.3f})")
