"""
ASR Processor Module
Automatic Speech Recognition using OpenAI Whisper Turbo or NVIDIA Parakeet models
"""

import torch
import whisper
import librosa
import soundfile as sf
import os
import gc
import threading
import re
from typing import Any, Callable
from pathlib import Path

from .cuda_lock import get_cuda_init_lock

# Whisper model locks (separate for parallel processing)
_whisper_init_lock = threading.Lock()
_whisper_inference_lock = threading.Lock()

# Parakeet model lock (unified lock for both init and inference due to model instability)
# This ensures Parakeet init and inference never happen simultaneously
# Using RLock to allow nested acquisition within the same thread (transcribe -> load_model)
_parakeet_lock = threading.RLock()


def _merge_segments_by_punctuation(segments: list[dict[str, Any]], language: str = "en") -> list[dict[str, Any]]:
    """
    Merge Whisper segments into sentence-level segments based on punctuation.

    Uses word-level timestamps from Whisper to accurately split text by sentence boundaries.

    Simple rule: Split on punctuation (.!?。!?) UNLESS the next word starts with lowercase
    (which indicates continuation like "tf.nn" or "Dr. Smith")

    Args:
        segments: List of Whisper segment dicts with 'text', 'start', 'end', and optionally 'words'
        language: Language code (unused, kept for compatibility)

    Returns:
        List of sentence-level segments with 'text', 'start', 'end'
    """
    if not segments:
        return []

    # Sentence-ending punctuation marks (supports English, Korean, and other languages)
    sentence_ending_pattern = re.compile(r'[.!?。!?]+\s*$')

    sentence_segments = []
    current_sentence = []
    current_start = None
    current_end = None

    for segment in segments:
        text = segment.get('text', '').strip()
        if not text:
            continue

        # Get word-level timestamps if available
        words = segment.get('words', [])

        if words:
            # Process each word with its timestamp
            for idx, word_info in enumerate(words):
                word_text = word_info.get('word', '').strip()
                word_start = word_info.get('start', segment['start'])
                word_end = word_info.get('end', segment['end'])

                if not word_text:
                    continue

                if word_text.endswith('니다'):
                    word_text += '.'
                
                if word_text.endswith('요') and len(word_text) >= 3:
                    word_text += '.'

                # Initialize sentence start time
                if current_start is None:
                    current_start = word_start

                current_sentence.append(word_text)
                current_end = word_end

                # Check if word ends with sentence-ending punctuation
                if sentence_ending_pattern.search(word_text):
                    # Get next word to check if it starts with lowercase
                    next_word_text = None
                    if idx + 1 < len(words):
                        next_word_text = words[idx + 1].get('word', '').strip()

                    # Determine if this is a real sentence boundary
                    is_sentence_end = True
                    if next_word_text:
                        # If next word starts with lowercase, don't split (e.g., "tf.nn", "Dr. smith")
                        # Strip leading punctuation/spaces to get the first actual character
                        first_char = next_word_text.lstrip()
                        if first_char and first_char[0].islower():
                            is_sentence_end = False

                    if is_sentence_end:
                        # Complete current sentence
                        sentence_text = ' '.join(current_sentence).strip()
                        if sentence_text:
                            sentence_segments.append({
                                'text': sentence_text,
                                'start': current_start,
                                'end': current_end
                            })

                        # Reset for next sentence
                        current_sentence = []
                        current_start = None
                        current_end = None

        else:
            # Fallback: No word-level timestamps, use simple splitting with estimation
            segment_start = segment['start']
            segment_end = segment['end']
            segment_duration = segment_end - segment_start
            text_length = len(text)
            time_per_char = segment_duration / text_length if text_length > 0 else 0

            # Split by punctuation with lookahead to check for lowercase continuation
            # Pattern: punctuation followed by space and NOT followed by lowercase
            sentence_split_pattern = re.compile(r'([.!?。!?]+)\s+(?![a-z])')

            parts = sentence_split_pattern.split(text)

            char_offset = 0
            i = 0
            while i < len(parts):
                part = parts[i]
                if not part.strip():
                    char_offset += len(part)
                    i += 1
                    continue

                # Check if this is punctuation or text
                if sentence_ending_pattern.search(part):
                    # This is punctuation, attach to current sentence
                    if current_sentence:
                        current_sentence[-1] += part
                    char_offset += len(part)
                    i += 1
                    continue

                # This is text content
                sentence_text = part.strip()
                if not sentence_text:
                    char_offset += len(part)
                    i += 1
                    continue

                # Calculate timestamps
                sentence_start_idx = char_offset
                sentence_end_idx = char_offset + len(part)

                sentence_start_time = segment_start + (sentence_start_idx * time_per_char)
                sentence_end_time = segment_start + (sentence_end_idx * time_per_char)

                if current_start is None:
                    current_start = sentence_start_time

                current_sentence.append(sentence_text)
                current_end = sentence_end_time

                # Check if next part is punctuation (sentence end)
                if i + 1 < len(parts) and sentence_ending_pattern.search(parts[i + 1]):
                    # Complete sentence with punctuation
                    punct = parts[i + 1]
                    current_sentence[-1] += punct
                    char_offset += len(part) + len(punct)

                    # Add sentence
                    final_text = ' '.join(current_sentence).strip()
                    if final_text:
                        sentence_segments.append({
                            'text': final_text,
                            'start': current_start,
                            'end': current_end
                        })

                    current_sentence = []
                    current_start = None
                    current_end = None
                    i += 2
                else:
                    char_offset += len(part)
                    i += 1

    # Add any remaining text as the last sentence
    if current_sentence:
        final_text = ' '.join(current_sentence).strip()
        if final_text:
            sentence_segments.append({
                'text': final_text,
                'start': current_start,
                'end': current_end
            })

    return sentence_segments


class ASRProcessor:
    """
    Automatic Speech Recognition processor with automatic chunking support.
    Supports both OpenAI Whisper and NVIDIA Parakeet models.

    Model selection:
    - Parakeet: English-only, high accuracy, fast
    - Whisper: Multilingual support (English, Korean, etc.)
    """

    def __init__(
        self,
        model_name: str = "turbo",
        model_type: str = "whisper",
        device: str = "cuda"
    ):
        """
        Initialize ASR processor.

        Args:
            model_name: Model name
                - For whisper: "turbo", "large-v3", "large-v2", etc.
                - For parakeet: "nvidia/parakeet-tdt-0.6b-v2"
            model_type: Model type ("whisper" or "parakeet")
            device: Device to run on (cuda/cpu)
        """
        self.model_name = model_name
        self.model_type = model_type
        self.device = device
        self.model = None

        # Assign model-specific locks
        if self.model_type == "parakeet":
            # Parakeet uses unified lock for both init and inference
            self.init_lock = _parakeet_lock
            self.inference_lock = _parakeet_lock
        else:  # whisper
            # Whisper uses separate locks for parallel processing
            self.init_lock = _whisper_init_lock
            self.inference_lock = _whisper_inference_lock

    def load_model(self):
        """Load ASR model into memory."""
        # Use global CUDA lock first to prevent concurrent model initialization across all processors
        # Then use model-specific lock for thread safety within the same model type
        with get_cuda_init_lock():
            with self.init_lock:
                if self.model is not None:
                    print(f"[{self.model_type.upper()}] Model already loaded")
                    return

                print(f"[{self.model_type.upper()}] Loading ASR model: {self.model_name}")
                if torch.cuda.is_available():
                    torch.cuda.reset_peak_memory_stats()

                if self.model_type == "parakeet":
                    # Load NVIDIA Parakeet model via NeMo
                    try:
                        import nemo.collections.asr as nemo_asr
                        self.model = nemo_asr.models.ASRModel.from_pretrained(
                            model_name=self.model_name
                        )
                        print(f"[PARAKEET] Model loaded successfully: {self.model_name}")
                    except ImportError:
                        raise ImportError(
                            "NeMo toolkit not installed. Please install with: pip install nemo_toolkit[asr]"
                        )
                else:
                    # Load Whisper model
                    self.model = whisper.load_model(self.model_name, device=self.device)
                    print(f"[WHISPER] Model loaded successfully: {self.model_name}")

                if torch.cuda.is_available():
                    allocated = torch.cuda.memory_allocated() / 1024**3
                    print(f"[{self.model_type.upper()}] GPU memory after loading: {allocated:.2f} GB")

    def unload_model(self):
        """Unload model to free memory."""
        if self.model is not None:
            del self.model
            self.model = None
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()
            print(f"[{self.model_type.upper()}] ASR model unloaded")

    @classmethod
    def create_for_language(cls, language: str, device: str = "cuda"):
        """
        Create ASR processor optimized for specific language.

        Args:
            language: Language code ('en' for English, 'ko' for Korean)
            device: Device to run on (cuda/cpu)

        Returns:
            ASRProcessor instance with appropriate model

        Raises:
            ValueError: If language is not supported
        """
        if language == "en":
            # Use Parakeet for English (higher accuracy)
            return cls(
                model_name="nvidia/parakeet-tdt-0.6b-v2",
                model_type="parakeet",
                device=device
            )
        elif language == "ko":
            # Use Whisper for Korean (multilingual support)
            return cls(
                model_name="turbo",
                model_type="whisper",
                device=device
            )
        else:
            raise ValueError(f"Unsupported language: {language}. Supported: 'en', 'ko'")

    def _prepare_audio_chunks(
        self,
        input_file: str,
        chunk_seconds: int,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> tuple[list[str], str, int, float]:
        """
        Prepare audio chunks for transcription (shared preprocessing for both models).

        Both Whisper and Parakeet require 16kHz mono audio.

        Args:
            input_file: Input audio file path
            chunk_seconds: Chunk duration in seconds
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            Tuple of (chunk_files, temp_dir, sample_rate, total_duration)
        """
        import uuid

        if progress_callback:
            progress_callback(5.0, "Loading audio file...")

        # Load audio as mono 16kHz (both models require this)
        audio_data, sample_rate = librosa.load(input_file, sr=16000, mono=True)

        # Calculate duration
        total_duration = len(audio_data) / sample_rate
        print(f"[{self.model_type.upper()}] Audio loaded - Duration: {total_duration:.1f}s ({total_duration/60:.1f}min), SR: {sample_rate}Hz")

        if progress_callback:
            progress_callback(10.0, f"Audio loaded: {total_duration/60:.1f} minutes")

        # Create temp directory
        temp_dir = f"temp_{self.model_type}_chunks_{uuid.uuid4().hex[:8]}"
        os.makedirs(temp_dir, exist_ok=True)

        # Split into chunks
        chunk_samples = int(chunk_seconds * sample_rate)
        chunk_files = []
        chunk_num = 0

        needs_chunking = total_duration > chunk_seconds
        if needs_chunking:
            print(f"[{self.model_type.upper()}] Splitting into {chunk_seconds}s chunks...")
        else:
            print(f"[{self.model_type.upper()}] Processing as single chunk")

        for i in range(0, len(audio_data), chunk_samples):
            chunk = audio_data[i:i + chunk_samples]

            # Skip chunks shorter than 1 second
            if len(chunk) < sample_rate:
                continue

            chunk_num += 1
            chunk_file = os.path.join(temp_dir, f"chunk_{chunk_num:03d}.wav")
            sf.write(chunk_file, chunk, sample_rate)
            chunk_files.append(chunk_file)

            chunk_duration = len(chunk) / sample_rate
            print(f"[{self.model_type.upper()}] Chunk {chunk_num}: {chunk_duration:.1f}s")

        print(f"[{self.model_type.upper()}] Total {len(chunk_files)} chunk(s) created")

        return chunk_files, temp_dir, sample_rate, total_duration

    def _transcribe_parakeet(
        self,
        input_file: str,
        chunk_seconds: int = 300,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> tuple[str, list[dict[str, Any]]]:
        """
        Transcribe audio using NVIDIA Parakeet model with chunking support.

        Args:
            input_file: Input audio file path
            chunk_seconds: Chunk duration in seconds (default: 300s = 5min)
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            Tuple of (full transcript, segment timestamps)
        """
        print(f"[PARAKEET] Transcribing: {input_file}")

        temp_dir = None
        chunk_files = []

        try:
            # STEP 1 & 2: Prepare audio chunks (unified preprocessing)
            chunk_files, temp_dir, sample_rate, total_duration = self._prepare_audio_chunks(
                input_file,
                chunk_seconds,
                progress_callback=progress_callback
            )

            if progress_callback:
                progress_callback(20.0, f"Transcribing {len(chunk_files)} chunk(s)...")

            # Clear GPU memory before processing
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()

            # STEP 3: Process chunks sequentially
            transcripts = []
            all_segment_timestamps = []
            chunk_offset = 0.0
            chunk_duration_seconds = chunk_seconds  # Expected chunk duration

            for idx, chunk_file in enumerate(chunk_files, 1):
                print(f"[PARAKEET] Processing chunk {idx}/{len(chunk_files)}...")

                # Transcribe chunk
                output = self.model.transcribe([chunk_file], timestamps=True)

                if not output or len(output) == 0:
                    print(f"[PARAKEET] Warning: Chunk {idx} returned empty output, skipping")
                    continue

                transcript_obj = output[0]
                transcript = transcript_obj.text
                transcripts.append(transcript)
                print(f"[PARAKEET] Chunk {idx}/{len(chunk_files)}: {len(transcript)} characters")

                # Extract segment timestamps and adjust with chunk offset
                if hasattr(transcript_obj, 'timestamp') and transcript_obj.timestamp:
                    segments = transcript_obj.timestamp.get('segment', [])
                    for seg in segments:
                        all_segment_timestamps.append({
                            'text': seg['segment'].strip(),
                            'start': seg['start'] + chunk_offset,
                            'end': seg['end'] + chunk_offset
                        })

                # Update chunk offset for next chunk
                # Last chunk might be shorter than chunk_duration_seconds
                if idx < len(chunk_files):
                    chunk_offset += chunk_duration_seconds
                else:
                    # For last chunk, calculate remaining duration
                    chunk_offset += (total_duration - (idx - 1) * chunk_duration_seconds)

                # Report progress
                if progress_callback:
                    chunk_progress = 20.0 + (idx / len(chunk_files)) * 70.0
                    progress_callback(chunk_progress, f"Processed chunk {idx}/{len(chunk_files)}")

                # Clear GPU memory after each chunk
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()
                    torch.cuda.synchronize()
                gc.collect()

            # Show GPU memory usage
            if torch.cuda.is_available():
                allocated = torch.cuda.memory_allocated() / 1024**3
                print(f"[PARAKEET] GPU memory usage: {allocated:.2f} GB")

            # STEP 4: Merge results
            full_transcript = ' '.join(filter(None, transcripts))

            if progress_callback:
                progress_callback(100.0, "Parakeet transcription complete")

            print(f"[PARAKEET] Transcription complete: {len(full_transcript)} characters, {len(all_segment_timestamps)} segments")
            return (full_transcript, all_segment_timestamps)

        except Exception as e:
            print(f"[PARAKEET] Transcription error: {e}")
            raise RuntimeError(f"Parakeet transcription failed: {str(e)}") from e
        finally:
            # Clean up chunk files
            for chunk_file in chunk_files:
                try:
                    if os.path.exists(chunk_file):
                        os.remove(chunk_file)
                except Exception as e:
                    print(f"[PARAKEET] Warning: Failed to delete chunk {chunk_file}: {e}")

            # Clean up temp directory
            if temp_dir and os.path.exists(temp_dir):
                try:
                    os.rmdir(temp_dir)
                    print(f"[PARAKEET] Removed temporary directory: {temp_dir}")
                except Exception as e:
                    print(f"[PARAKEET] Warning: Failed to delete temp directory {temp_dir}: {e}")

    def _auto_split_transcribe(
        self,
        input_file: str,
        language: str = "en",
        chunk_seconds: int = 300,
        batch_size: int = 3,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> tuple[str, list[dict[str, Any]]]:
        """
        Split audio file and transcribe in batches with timestamps (Whisper only).

        Args:
            input_file: Input audio file path
            language: Language code for transcription ('en' for English, 'ko' for Korean)
            chunk_seconds: Chunk duration in seconds
            batch_size: Batch size for processing (Note: Whisper processes sequentially)
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            Tuple of (full transcript, segment timestamps)
            Segment timestamps is a list of dicts with 'text', 'start', 'end' keys (times in seconds)
            Segments are split by punctuation unless next word starts with lowercase
        """
        print(f"[WHISPER] Transcribing: {input_file}")

        temp_dir = None
        chunk_files = []

        try:
            # STEP 1 & 2: Prepare audio chunks (unified preprocessing)
            chunk_files, temp_dir, sample_rate, total_duration = self._prepare_audio_chunks(
                input_file,
                chunk_seconds,
                progress_callback=progress_callback
            )

            if progress_callback:
                progress_callback(20.0, f"Transcribing {len(chunk_files)} chunk(s)...")

            # Clear GPU memory
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()

            # STEP 3: Process chunks sequentially with Whisper
            transcripts = []
            all_segment_timestamps = []
            chunk_offset = 0.0
            chunk_duration_seconds = chunk_seconds

            for idx, chunk_file in enumerate(chunk_files, 1):
                print(f"[WHISPER] Processing chunk {idx}/{len(chunk_files)}...")

                with torch.no_grad():
                    # Transcribe with word-level timestamps
                    result = self.model.transcribe(
                        chunk_file,
                        language=language,
                        word_timestamps=True
                    )

                transcript = result['text']
                transcripts.append(transcript)
                print(f"[WHISPER] Chunk {idx}/{len(chunk_files)}: {len(transcript)} characters")

                # Extract and merge segments by punctuation
                if 'segments' in result:
                    # Merge segments into sentence-level segments
                    sentence_segments = _merge_segments_by_punctuation(result['segments'], language=language)

                    # Add chunk offset to timestamps
                    for segment in sentence_segments:
                        all_segment_timestamps.append({
                            'text': segment['text'],
                            'start': segment['start'] + chunk_offset,
                            'end': segment['end'] + chunk_offset
                        })

                # Update chunk offset for next chunk
                if idx < len(chunk_files):
                    chunk_offset += chunk_duration_seconds
                else:
                    # For last chunk, calculate remaining duration
                    chunk_offset += (total_duration - (idx - 1) * chunk_duration_seconds)

                # Report progress per chunk
                if progress_callback:
                    chunk_progress = 20.0 + (idx / len(chunk_files)) * 70.0
                    progress_callback(chunk_progress, f"Processed chunk {idx}/{len(chunk_files)}")

            # Show GPU memory usage
            if torch.cuda.is_available():
                allocated = torch.cuda.memory_allocated() / 1024**3
                print(f"[WHISPER] GPU memory usage: {allocated:.2f} GB")

            # STEP 4: Merge results
            full_transcript = ' '.join(filter(None, transcripts))

            if progress_callback:
                progress_callback(100.0, "Whisper transcription complete")

            print(f"[WHISPER] Transcription complete: {len(full_transcript)} characters, {len(all_segment_timestamps)} segments")
            return (full_transcript, all_segment_timestamps)

        except Exception as e:
            print(f"[WHISPER] Transcription error: {e}")
            raise RuntimeError(f"Whisper transcription failed: {str(e)}") from e

        finally:
            # Clean up chunk files
            for chunk_file in chunk_files:
                try:
                    if os.path.exists(chunk_file):
                        os.remove(chunk_file)
                except Exception as e:
                    print(f"[WHISPER] Warning: Failed to delete chunk {chunk_file}: {e}")

            # Clean up temp directory
            if temp_dir and os.path.exists(temp_dir):
                try:
                    os.rmdir(temp_dir)
                    print(f"[WHISPER] Removed temporary directory: {temp_dir}")
                except Exception as e:
                    print(f"[WHISPER] Warning: Failed to delete temp directory {temp_dir}: {e}")

    def transcribe(
        self,
        audio_path: str,
        language: str = "en",
        chunk_seconds: int = 300,
        batch_size: int = 4,
        output_path: str | None = None,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> dict[str, Any]:
        """
        Transcribe audio file with automatic chunking.

        Args:
            audio_path: Path to audio file
            language: Language code for transcription ('en' for English, 'ko' for Korean)
            chunk_seconds: Chunk duration for long files (applies to both Whisper and Parakeet)
            batch_size: Batch size for processing (adjust based on VRAM, Whisper only)
            output_path: Optional path to save transcript
            progress_callback: Optional callback function(progress: float, message: str)
                             progress is 0-100 representing percentage completion

        Returns:
            Dictionary with transcript, word_timestamps, and metadata
        """
        # Validate language for Parakeet (English only)
        if self.model_type == "parakeet" and language != "en":
            raise ValueError(
                f"Parakeet model only supports English. Got language='{language}'. "
                f"Use Whisper model for other languages."
            )

        # Use model-specific inference lock to prevent concurrent inference AND model loading
        # This prevents race conditions where multiple requests try to load the model simultaneously
        with self.inference_lock:
            # Load model inside lock to prevent concurrent loading
            if self.model is None:
                self.load_model()
            print("="*60)
            print(f"[{self.model_type.upper()}] ASR Transcription (language: {language})")
            print("="*60)

            if progress_callback:
                progress_callback(0.0, "Loading audio file...")

            segment_timestamps = []

            # Choose transcription method based on model type
            if self.model_type == "parakeet":
                # Parakeet: Chunked transcription (unified preprocessing)
                print(f"[PARAKEET] Using chunked transcription (chunk_seconds={chunk_seconds})")
                transcript, segment_timestamps = self._transcribe_parakeet(
                    audio_path,
                    chunk_seconds=chunk_seconds,
                    progress_callback=progress_callback
                )
            else:
                # Whisper: Chunked transcription (unified preprocessing)
                print(f"[WHISPER] Using chunked transcription (chunk_seconds={chunk_seconds})")
                transcript, segment_timestamps = self._auto_split_transcribe(
                    audio_path,
                    language=language,
                    chunk_seconds=chunk_seconds,
                    batch_size=batch_size,
                    progress_callback=progress_callback
                )

            if progress_callback:
                progress_callback(100.0, "Finalizing transcription...")

            print()
            print("="*60)
            print("Transcription Result:")
            print("="*60)
            print(transcript)

            if torch.cuda.is_available():
                max_memory = torch.cuda.max_memory_allocated() / 1024**3
                print(f"\nMax GPU memory usage: {max_memory:.2f} GB")

            # Save to file if requested
            if output_path:
                Path(output_path).parent.mkdir(parents = True, exist_ok = True)
                with open(output_path, "w", encoding = "utf-8") as f:
                    f.write(transcript)
                print(f"\nTranscript saved to: {output_path}")

            result = {
                "transcript": transcript,
                "audio_path": audio_path,
                "length": len(transcript),
                "segment_timestamps": segment_timestamps  # Sentence-level timestamps (punctuation-based with lowercase check)
            }

            print(f"\n✓ Extracted {len(segment_timestamps)} sentence-level timestamps")

            return result


if __name__ == "__main__":
    # Example usage
    # English transcription
    processor_en = ASRProcessor(model_name="turbo", language="en")
    result_en = processor_en.transcribe(
        audio_path = "lecture_recording.mp3",
        chunk_seconds = 300,
        batch_size = 4,
        output_path = "transcript_result_en.txt"
    )
    print(f"\nEnglish transcript length: {result_en['length']} characters")

    # Korean transcription
    processor_ko = ASRProcessor(model_name="turbo", language="ko")
    result_ko = processor_ko.transcribe(
        audio_path = "lecture_recording_ko.mp3",
        chunk_seconds = 300,
        batch_size = 4,
        output_path = "transcript_result_ko.txt"
    )
    print(f"\nKorean transcript length: {result_ko['length']} characters")
