"""
Translation Processor Module
Bidirectional translation (English↔Korean) using Tencent Hunyuan-MT-7B with vLLM
"""

import os
import torch
import gc
import threading
from typing import Callable
from vllm import LLM, SamplingParams

# Set multiprocessing start method before any CUDA operations
# This prevents the WARNING about overriding VLLM_WORKER_MULTIPROC_METHOD
os.environ.setdefault("VLLM_WORKER_MULTIPROC_METHOD", "spawn")

# Global lock for vLLM model initialization
# Protects vLLM initialization which can fail if multiple instances start simultaneously
_vllm_init_lock = threading.Lock()

# Global lock for translation model inference
# Protects inference operations when multiple pipelines run simultaneously
# This prevents vLLM errors when the same model runs concurrent inference
_translation_inference_lock = threading.Lock()


class TranslationProcessor:
    """
    Bidirectional translation processor (English↔Korean) using vLLM for fast parallel inference.
    """

    def __init__(
        self,
        model_name: str = "tencent/Hunyuan-MT-7B-fp8",
        device: str = "cuda",
        tensor_parallel_size: int = 1,
        max_model_len: int = 2048,
        gpu_memory_utilization: float = 0.35
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

        # Use global lock to prevent concurrent vLLM initialization
        # This prevents memory profiling errors when multiple workers load models simultaneously
        with _vllm_init_lock:
            print("Acquired vLLM initialization lock")
            # Initialize vLLM with Hunyuan-MT-7B
            self.model = LLM(
                model = self.model_name,
                tensor_parallel_size = self.tensor_parallel_size,
                max_model_len = self.max_model_len,
                gpu_memory_utilization = self.gpu_memory_utilization,
                dtype = "bfloat16" if torch.cuda.is_bf16_supported() else "float16",
                trust_remote_code = True
            )
            print("Released vLLM initialization lock")

        print("Translation model loaded successfully")

    def unload_model(self):
        """Unload model to free memory."""
        if self.model is not None:
            del self.model
            self.model = None

            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()
            print("Translation model unloaded")

    def _build_translation_prompt(self, text: str, source_lang: str, target_lang: str) -> list[dict]:
        """
        Build translation prompt for Hunyuan-MT-7B using chat format.

        Args:
            text: Text to translate (source language)
            source_lang: Source language ('en' or 'ko')
            target_lang: Target language ('en' or 'ko')

        Returns:
            Chat messages in list format
        """
        # Hunyuan-MT-7B uses chat message format
        if source_lang == "en" and target_lang == "ko":
            # English to Korean
            messages = [
                {"role": "user", "content": f"Translate the following segment into Korean, without additional explanation.\n\n{text}"}
            ]
        elif source_lang == "ko" and target_lang == "en":
            # Korean to English
            messages = [
                {"role": "user", "content": f"Translate the following segment into English, without additional explanation.\n\n{text}"}
            ]
        else:
            raise ValueError(f"Unsupported translation direction: {source_lang} → {target_lang}")

        return messages

    def translate_batch(
        self,
        texts: list[str],
        source_lang: str = "en",
        target_lang: str = "ko",
        temperature: float = 0.7,
        top_p: float = 0.6,
        top_k: int = 20,
        repetition_penalty: float = 1.05,
        max_tokens: int = 2048,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> list[str]:
        """
        Translate a batch of texts from source language to target language.

        Args:
            texts: List of texts to translate (in source language)
            source_lang: Source language ('en' or 'ko')
            target_lang: Target language ('en' or 'ko')
            temperature: Sampling temperature (default 0.7 as recommended)
            top_p: Nucleus sampling parameter (default 0.6 as recommended)
            top_k: Top-k sampling parameter (default 20 as recommended)
            repetition_penalty: Repetition penalty (default 1.05 as recommended)
            max_tokens: Maximum tokens to generate per translation
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            List of translations (in target language)
        """
        # Load model BEFORE acquiring inference lock to avoid deadlock
        # This ensures init_lock and inference_lock are never held simultaneously
        if self.model is None:
            self.load_model()

        # Use inference lock to prevent concurrent inference on the same model
        with _translation_inference_lock:
            print(f"Translating {len(texts)} sentences ({source_lang} → {target_lang})...")

            if progress_callback:
                progress_callback(0.0, "Preparing translation prompts...")

            # Build chat prompts for all texts
            chat_prompts = [self._build_translation_prompt(text, source_lang, target_lang) for text in texts]

            # Set up sampling parameters (using recommended parameters)
            sampling_params = SamplingParams(
                temperature = temperature,
                top_p = top_p,
                top_k = top_k,
                repetition_penalty = repetition_penalty,
                max_tokens = max_tokens,
                stop_token_ids = [127960]
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

            # Note: GPU memory usage is shown in vLLM's INFO logs
            # torch.cuda.memory_allocated() shows 0 because vLLM uses separate processes

            if progress_callback:
                progress_callback(100.0, "Translation completed")

            return translations

    def translate_matching_results(
        self,
        matching_results: list[dict],
        source_lang: str = "en",
        target_lang: str = "ko",
        progress_callback: Callable[[float, str], None] | None = None
    ) -> list[dict]:
        """
        Translate text field in matching results and reorganize into text_eng/text_kor fields.

        Args:
            matching_results: Results from SlideMatchingProcessor
            source_lang: Source language ('en' or 'ko')
            target_lang: Target language ('en' or 'ko')
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            Updated matching results with text_eng and text_kor fields:
            - For en→ko: 'text' → 'text_eng', translation → 'text_kor'
            - For ko→en: 'text' → 'text_kor', translation → 'text_eng'
            (The original 'text' field is removed)
        """
        if self.model is None:
            self.load_model()

        print("="*60)
        print("Translation Processing")
        print("="*60)

        # Extract source texts
        source_texts = [result['text'] for result in matching_results]

        # Translate all texts
        translations = self.translate_batch(
            texts = source_texts,
            source_lang = source_lang,
            target_lang = target_lang,
            progress_callback = progress_callback
        )

        # Reorganize results with text_eng and text_kor fields
        translated_results = []

        for result, translation in zip(matching_results, translations):
            result_with_translation = result.copy()

            # Remove original 'text' field and add text_eng/text_kor based on direction
            original_text = result_with_translation.pop('text')

            if source_lang == 'en' and target_lang == 'ko':
                # English lecture: original is English, translation is Korean
                result_with_translation['text_eng'] = original_text
                result_with_translation['text_kor'] = translation
            elif source_lang == 'ko' and target_lang == 'en':
                # Korean lecture: original is Korean, translation is English
                result_with_translation['text_kor'] = original_text
                result_with_translation['text_eng'] = translation
            else:
                raise ValueError(f"Unsupported translation direction: {source_lang} → {target_lang}")

            translated_results.append(result_with_translation)

        print(f"\n✓ Translation complete: {len(translated_results)} sentences translated ({source_lang} → {target_lang})")

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
        matching_results = matching_results
    )

    # Print results
    for result in translated_results:
        print(f"\nSlide {result['matched_page']}:")
        print(f"  EN: {result['text']}")
        print(f"  KO: {result['text_kor']}")
        print(f"  Confidence: {result['confidence_score']:.3f}")
