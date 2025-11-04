"""
ASR Processor Module
Automatic Speech Recognition using OpenAI Whisper Turbo model
"""

import torch
import whisper
import librosa
import soundfile as sf
import os
import gc
import threading
from typing import Any, Callable
from pathlib import Path

# Global lock for ASR model initialization
# Protects CUDA initialization during model loading when multiple pipelines start simultaneously
_asr_init_lock = threading.Lock()

# Global lock for ASR model inference
# Protects inference operations when multiple pipelines run simultaneously
# This prevents CUDA errors when the same model runs concurrent inference
_asr_inference_lock = threading.Lock()


class ASRProcessor:
    """
    Automatic Speech Recognition processor with automatic chunking support.
    Uses OpenAI Whisper Turbo for multilingual transcription.
    """

    def __init__(
        self,
        model_name: str = "turbo",
        device: str = "cuda",
        language: str = "en"
    ):
        """
        Initialize ASR processor.

        Args:
            model_name: Whisper model name (turbo, large-v3, large-v2, etc.)
            device: Device to run on (cuda/cpu)
            language: Language code for transcription ('en' for English, 'ko' for Korean)
        """
        self.model_name = model_name
        self.device = device
        self.language = language
        self.model = None

    def load_model(self):
        """Load ASR model into memory."""
        # Use global lock only during model initialization
        # This prevents CUDA initialization conflicts when multiple pipelines load models simultaneously
        with _asr_init_lock:
            if self.model is not None:
                print("Model already loaded")
                return

            print(f"Loading Whisper ASR model: {self.model_name} (language: {self.language})")
            if torch.cuda.is_available():
                torch.cuda.reset_peak_memory_stats()

            self.model = whisper.load_model(self.model_name, device=self.device)
            print("ASR model loaded successfully")

    def unload_model(self):
        """Unload model to free memory."""
        if self.model is not None:
            del self.model
            self.model = None
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()
            print("ASR model unloaded")

    def _auto_split_transcribe(
        self,
        input_file: str,
        chunk_seconds: int = 300,
        batch_size: int = 3,
        temp_dir: str | None = None,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> tuple[str, list[dict[str, Any]]] | None:
        """
        Split audio file and transcribe in batches with timestamps.

        Args:
            input_file: Input audio file path
            chunk_seconds: Chunk duration in seconds
            batch_size: Batch size for processing (Note: Whisper processes sequentially)
            temp_dir: Temporary directory for chunks (auto-generated if None)
            progress_callback: Optional callback function(progress: float, message: str)

        Returns:
            Tuple of (full transcript, segment timestamps) or None if no splitting needed
            Segment timestamps is a list of dicts with 'text', 'start', 'end' keys (times in seconds)
            Segments are automatically split by Whisper's segmentation
        """
        print(f"Loading audio file: {input_file}")

        if progress_callback:
            progress_callback(5.0, "Loading audio file...")

        # Load audio file as mono and resample to 16kHz (Whisper requirement)
        audio, sr = librosa.load(input_file, sr = 16000, mono = True)
        total_duration = len(audio) / sr

        print(f"Total duration: {total_duration:.1f}s ({total_duration/60:.1f}min)")

        if progress_callback:
            progress_callback(10.0, f"Audio loaded: {total_duration/60:.1f} minutes")

        # If file is short enough, don't split
        if total_duration <= chunk_seconds:
            print("File is short enough, no splitting needed")
            return None

        # Create unique temp directory if not specified
        if temp_dir is None:
            import uuid
            temp_dir = f"temp_chunks_{uuid.uuid4().hex[:8]}"

        # Create temp directory
        os.makedirs(temp_dir, exist_ok = True)
        print(f"Using temporary directory: {temp_dir}")

        # Split audio
        chunk_samples = chunk_seconds * sr
        chunk_files = []

        print(f"Splitting into {chunk_seconds}s chunks...")

        chunk_num = 0
        for i in range(0, len(audio), chunk_samples):
            chunk = audio[i:i + chunk_samples]

            # Skip chunks shorter than 1 second
            if len(chunk) < sr:
                continue

            chunk_num += 1
            chunk_file = os.path.join(temp_dir, f"chunk_{chunk_num:03d}.wav")

            # Save chunk
            sf.write(chunk_file, chunk, sr)
            chunk_files.append(chunk_file)

            chunk_duration = len(chunk) / sr
            print(f"Chunk {chunk_num}: {chunk_duration:.1f}s")

        print(f"Total {len(chunk_files)} chunks created")
        print(f"Processing chunks sequentially...")

        if progress_callback:
            progress_callback(20.0, f"Transcribing {len(chunk_files)} chunks...")

        # Clear GPU memory
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.synchronize()
        gc.collect()

        try:
            # Process chunks sequentially with Whisper
            transcripts = []
            all_segment_timestamps = []
            chunk_offset = 0.0  # Track cumulative time offset

            for idx, chunk_file in enumerate(chunk_files, 1):
                print(f"Processing chunk {idx}/{len(chunk_files)}...")

                with torch.no_grad():
                    # Transcribe with word-level timestamps
                    result = self.model.transcribe(
                        chunk_file,
                        language=self.language,
                        word_timestamps=True
                    )

                transcript = result['text']
                transcripts.append(transcript)
                print(f"Chunk {idx}/{len(chunk_files)}: {len(transcript)} characters")

                # Extract segment-level timestamps
                if 'segments' in result:
                    for segment in result['segments']:
                        all_segment_timestamps.append({
                            'text': segment['text'].strip(),
                            'start': segment['start'] + chunk_offset,
                            'end': segment['end'] + chunk_offset
                        })

                # Update chunk offset for next chunk
                chunk_duration = len(audio[(idx - 1) * chunk_samples:idx * chunk_samples]) / sr
                chunk_offset += chunk_duration

                # Report progress per chunk
                if progress_callback:
                    chunk_progress = 20.0 + (idx / len(chunk_files)) * 70.0
                    progress_callback(chunk_progress, f"Processed chunk {idx}/{len(chunk_files)}")

            # Show GPU memory usage
            if torch.cuda.is_available():
                allocated = torch.cuda.memory_allocated() / 1024**3
                print(f"\nGPU memory usage: {allocated:.2f} GB")

        except Exception as e:
            print(f"Batch processing error: {e}")
            print(f"Error type: {type(e).__name__}")

            # Clean up temp files on error
            print("\nCleaning up temporary files after error...")
            for chunk_file in chunk_files:
                try:
                    if os.path.exists(chunk_file):
                        os.remove(chunk_file)
                except:
                    pass

            try:
                if os.path.exists(temp_dir):
                    os.rmdir(temp_dir)
            except:
                pass

            # Clean up GPU memory on error
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()

            # Re-raise with context
            raise RuntimeError(f"ASR batch processing failed: {str(e)}") from e

        # Clean up temp files
        print("\nCleaning up temporary files...")
        for chunk_file in chunk_files:
            try:
                if os.path.exists(chunk_file):
                    os.remove(chunk_file)
            except Exception as e:
                print(f"Warning: Failed to delete {chunk_file}: {e}")

        try:
            if os.path.exists(temp_dir):
                os.rmdir(temp_dir)
                print(f"Removed temporary directory: {temp_dir}")
        except Exception as e:
            print(f"Warning: Failed to delete temp directory {temp_dir}: {e}")

        # Merge results
        full_transcript = ' '.join(filter(None, transcripts))
        return (full_transcript, all_segment_timestamps)

    def transcribe(
        self,
        audio_path: str,
        chunk_seconds: int = 300,
        batch_size: int = 4,
        output_path: str | None = None,
        progress_callback: Callable[[float, str], None] | None = None
    ) -> dict[str, Any]:
        """
        Transcribe audio file with automatic chunking.

        Args:
            audio_path: Path to audio file
            chunk_seconds: Chunk duration for long files
            batch_size: Batch size for processing (adjust based on VRAM)
            output_path: Optional path to save transcript
            progress_callback: Optional callback function(progress: float, message: str)
                             progress is 0-100 representing percentage completion

        Returns:
            Dictionary with transcript, word_timestamps, and metadata
        """
        # Load model BEFORE acquiring inference lock to avoid deadlock
        # This ensures init_lock and inference_lock are never held simultaneously
        if self.model is None:
            self.load_model()

        # Use inference lock to prevent concurrent inference on the same model
        with _asr_inference_lock:
            print("="*60)
            print("ASR Transcription")
            print("="*60)

            if progress_callback:
                progress_callback(0.0, "Loading audio file...")

            # Try auto-split transcription
            split_result = self._auto_split_transcribe(
                audio_path,
                chunk_seconds = chunk_seconds,
                batch_size = batch_size,
                progress_callback = progress_callback
            )

            segment_timestamps = []

            if split_result is None:
                # Process original file directly (short audio)
                print("Processing original file directly:")

                if progress_callback:
                    progress_callback(50.0, "Transcribing audio...")

                with torch.no_grad():
                    result = self.model.transcribe(
                        audio_path,
                        language=self.language,
                        word_timestamps=True
                    )

                transcript = result['text']

                # Extract segment-level timestamps (Whisper automatically segments by natural speech boundaries)
                if 'segments' in result:
                    segment_timestamps = [
                        {
                            'text': seg['text'].strip(),
                            'start': seg['start'],
                            'end': seg['end']
                        }
                        for seg in result['segments']
                    ]

                if progress_callback:
                    progress_callback(95.0, "Transcription complete")
            else:
                # Use split result (already reported progress in _auto_split_transcribe)
                transcript, segment_timestamps = split_result

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
                "segment_timestamps": segment_timestamps  # Add segment-level timestamps (split by punctuation)
            }

            print(f"\n✓ Extracted {len(segment_timestamps)} segment-level timestamps")

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
