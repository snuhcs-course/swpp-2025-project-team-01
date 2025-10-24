"""
Translation Processor Module
English-to-Korean translation using Tencent Hunyuan-MT-7B with vLLM
"""

import os
import torch
import gc
from typing import Callable
from vllm import LLM, SamplingParams

# Set multiprocessing start method before any CUDA operations
# This prevents the WARNING about overriding VLLM_WORKER_MULTIPROC_METHOD
os.environ.setdefault("VLLM_WORKER_MULTIPROC_METHOD", "spawn")


class TranslationProcessor:
    """
    English-to-Korean translation processor using vLLM for fast parallel inference.
    """

    def __init__(
        self,
        model_name: str = "tencent/Hunyuan-MT-7B",
        device: str = "cuda",
        tensor_parallel_size: int = 1,
        max_model_len: int = 2048,
        gpu_memory_utilization: float = 0.85
    ):
        """
        Initialize translation processor.

        Args:
            model_name: Pretrained translation model name
            device: Device to run on (cuda/cpu)
            tensor_parallel_size: Number of GPUs for tensor parallelism
            max_model_len: Maximum sequence length
            gpu_memory_utilization: GPU memory utilization ratio
        """
        self.model_name = model_name
        self.device = device
        self.tensor_parallel_size = tensor_parallel_size
        self.max_model_len = max_model_len
        self.gpu_memory_utilization = gpu_memory_utilization
        self.model = None

        print(f"Initializing Translation Processor")
        print(f"Model: {model_name}")
        print(f"Device: {device}")
        print(f"Tensor Parallel Size: {tensor_parallel_size}")

    def load_model(self):
        """Load translation model into memory."""
        if self.model is not None:
            print("Model already loaded")
            return

        print(f"Loading translation model: {self.model_name}")
        print("This may take a few minutes...")

        if torch.cuda.is_available():
            torch.cuda.reset_peak_memory_stats()

        # Initialize vLLM with Hunyuan-MT-7B
        self.model = LLM(
            model = self.model_name,
            tensor_parallel_size = self.tensor_parallel_size,
            max_model_len = self.max_model_len,
            gpu_memory_utilization = self.gpu_memory_utilization,
            trust_remote_code = True,
            dtype = "bfloat16" if torch.cuda.is_bf16_supported() else "float16",
        )

        print("Translation model loaded successfully")

    def unload_model(self):
        """Unload model to free memory."""
        if self.model is not None:
            # vLLM models need to be destroyed properly
            del self.model
            self.model = None

            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()
            print("Translation model unloaded")

    def _build_translation_prompt(self, text: str) -> list[dict]:
        """
        Build translation prompt for Hunyuan-MT-7B using chat format.

        Args:
            text: English text to translate

        Returns:
            Chat messages in list format
        """
        # Hunyuan-MT-7B uses chat message format
        # Note: No system prompt is used (as recommended in example_usage.py)
        messages = [
            {"role": "user", "content": f"Translate the following English text to Korean, without additional explanation.\n\n{text}"}
        ]
        return messages

    def translate_batch(
        self,
        texts: list[str],
        batch_size: int = 32,
        temperature: float = 0.7,
        top_p: float = 0.6,
        top_k: int = 20,
        repetition_penalty: float = 1.05,
        max_tokens: int = 512,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> list[str]:
        """
        Translate a batch of English texts to Korean.

        Args:
            texts: List of English texts to translate
            batch_size: Batch size for processing (vLLM handles internally)
            temperature: Sampling temperature (default 0.7 as recommended)
            top_p: Nucleus sampling parameter (default 0.6 as recommended)
            top_k: Top-k sampling parameter (default 20 as recommended)
            repetition_penalty: Repetition penalty (default 1.05 as recommended)
            max_tokens: Maximum tokens to generate per translation
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            List of Korean translations
        """
        if self.model is None:
            self.load_model()

        print(f"Translating {len(texts)} sentences to Korean...")

        if progress_callback:
            progress_callback(0.0, "Preparing translation prompts...")

        # Build chat prompts for all texts
        chat_prompts = [self._build_translation_prompt(text) for text in texts]

        # Set up sampling parameters (using recommended parameters from example_usage.py)
        sampling_params = SamplingParams(
            temperature = temperature,
            top_p = top_p,
            top_k = top_k,
            repetition_penalty = repetition_penalty,
            max_tokens = max_tokens,
        )

        if progress_callback:
            progress_callback(10.0, f"Translating {len(texts)} sentences...")

        # Generate translations in parallel using chat format
        # vLLM handles batching and parallelization automatically
        # vLLM will apply the model's chat template automatically when given chat messages
        outputs = self.model.chat(chat_prompts, sampling_params = sampling_params)

        if progress_callback:
            progress_callback(80.0, "Processing translation results...")

        # Extract translations
        translations = []
        for idx, output in enumerate(outputs):
            translation = output.outputs[0].text.strip()
            translations.append(translation)

            # Log progress
            if (idx + 1) % 10 == 0 or idx == len(outputs) - 1:
                print(f"Translated: {idx + 1}/{len(texts)} sentences")

                if progress_callback:
                    translation_progress = 80.0 + (idx + 1) / len(texts) * 20.0
                    progress_callback(translation_progress, f"Processed {idx + 1}/{len(texts)} translations")

        # Show GPU memory usage
        if torch.cuda.is_available():
            allocated = torch.cuda.memory_allocated() / 1024**3
            max_allocated = torch.cuda.max_memory_allocated() / 1024**3
            print(f"\nGPU memory usage: {allocated:.2f} GB")
            print(f"Peak GPU memory usage: {max_allocated:.2f} GB")

        if progress_callback:
            progress_callback(100.0, "Translation completed")

        return translations

    def translate_matching_results(
        self,
        matching_results: list[dict],
        batch_size: int = 32,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> list[dict]:
        """
        Translate text field in matching results to Korean.

        Args:
            matching_results: Results from SlideMatchingProcessor
            batch_size: Batch size for processing
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            Updated matching results with 'text_kor' field added
        """
        if self.model is None:
            self.load_model()

        print("="*60)
        print("Translation Processing")
        print("="*60)

        # Extract English texts
        english_texts = [result['text'] for result in matching_results]

        # Translate all texts
        korean_translations = self.translate_batch(
            texts = english_texts,
            batch_size = batch_size,
            progress_callback = progress_callback
        )

        # Add translations to results
        translated_results = []
        for result, translation in zip(matching_results, korean_translations):
            result_with_translation = result.copy()
            result_with_translation['text_kor'] = translation
            translated_results.append(result_with_translation)

        print(f"\n✓ Translation complete: {len(translated_results)} sentences translated")

        return translated_results


if __name__ == "__main__":
    # Example usage
    processor = TranslationProcessor(
        tensor_parallel_size=1,
        max_model_len=2048
    )

    # Example matching results from slide matching
    matching_results = [
        {"text": "Welcome to this lecture on deep learning.", "matched_page": 1, "confidence_score": 0.95},
        {"text": "Today we will discuss neural networks.", "matched_page": 1, "confidence_score": 0.92},
        {"text": "Let's start with the basics.", "matched_page": 2, "confidence_score": 0.88},
    ]

    # Translate
    translated_results = processor.translate_matching_results(
        matching_results = matching_results,
        batch_size = 32
    )

    # Print results
    for result in translated_results:
        print(f"\nSlide {result['matched_page']}:")
        print(f"  EN: {result['text']}")
        print(f"  KO: {result['text_kor']}")
        print(f"  Confidence: {result['confidence_score']:.3f}")
