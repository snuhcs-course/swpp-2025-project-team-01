"""
ASR Processor Module
Automatic Speech Recognition using NVIDIA Parakeet TDT model
"""

import torch
import nemo.collections.asr as nemo_asr
import librosa
import soundfile as sf
import os
import gc
from typing import Optional, List, Dict
from pathlib import Path


class ASRProcessor:
    """
    Automatic Speech Recognition processor with automatic chunking support.
    """

    def __init__(
        self,
        model_name: str = "nvidia/parakeet-tdt-0.6b-v2",
        device: str = "cuda"
    ):
        """
        Initialize ASR processor.

        Args:
            model_name: Pretrained ASR model name
            device: Device to run on (cuda/cpu)
        """
        self.model_name = model_name
        self.device = device
        self.model = None

    def load_model(self):
        """Load ASR model into memory."""
        if self.model is not None:
            print("Model already loaded")
            return

        print(f"Loading ASR model: {self.model_name}")
        if torch.cuda.is_available():
            torch.cuda.reset_peak_memory_stats()

        self.model = nemo_asr.models.ASRModel.from_pretrained(
            model_name = self.model_name
        )
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
        temp_dir: str = "temp_chunks"
    ) -> Optional[str]:
        """
        Split audio file and transcribe in batches.

        Args:
            input_file: Input audio file path
            chunk_seconds: Chunk duration in seconds
            batch_size: Batch size for processing
            temp_dir: Temporary directory for chunks

        Returns:
            Full transcript or None if no splitting needed
        """
        print(f"Loading audio file: {input_file}")

        # Load audio file as mono
        audio, sr = librosa.load(input_file, sr = None, mono = True)
        total_duration = len(audio) / sr

        print(f"Total duration: {total_duration:.1f}s ({total_duration/60:.1f}min)")

        # If file is short enough, don't split
        if total_duration <= chunk_seconds:
            print("File is short enough, no splitting needed")
            return None

        # Create temp directory
        os.makedirs(temp_dir, exist_ok = True)

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
        print(f"Processing with batch size {batch_size}")

        # Batch processing
        print("Starting batch processing...")

        # Clear GPU memory
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.synchronize()
        gc.collect()

        try:
            # Process all chunks at once with batch_size
            with torch.no_grad():
                outputs = self.model.transcribe(
                    chunk_files,
                    batch_size = batch_size
                )

            # Extract transcripts
            transcripts = []
            for idx, output in enumerate(outputs, 1):
                transcript = output.text if hasattr(output, 'text') else str(output)
                transcripts.append(transcript)
                print(f"Chunk {idx}/{len(chunk_files)}: {len(transcript)} characters")

            # Show GPU memory usage
            if torch.cuda.is_available():
                allocated = torch.cuda.memory_allocated() / 1024**3
                print(f"\nGPU memory usage: {allocated:.2f} GB")

        except Exception as e:
            print(f"Batch processing error: {e}")
            print(f"Error type: {type(e).__name__}")

            # Clean up on error
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            gc.collect()

            return ""

        # Clean up temp files
        print("\nCleaning up temporary files...")
        for chunk_file in chunk_files:
            try:
                os.remove(chunk_file)
            except:
                pass

        try:
            os.rmdir(temp_dir)
        except:
            pass

        # Merge results
        full_transcript = ' '.join(filter(None, transcripts))
        return full_transcript

    def transcribe(
        self,
        audio_path: str,
        chunk_seconds: int = 300,
        batch_size: int = 4,
        output_path: Optional[str] = None
    ) -> Dict[str, any]:
        """
        Transcribe audio file with automatic chunking.

        Args:
            audio_path: Path to audio file
            chunk_seconds: Chunk duration for long files
            batch_size: Batch size for processing (adjust based on VRAM)
            output_path: Optional path to save transcript

        Returns:
            Dictionary with transcript and metadata
        """
        if self.model is None:
            self.load_model()

        print("="*60)
        print("ASR Transcription")
        print("="*60)

        # Try auto-split transcription
        split_result = self._auto_split_transcribe(
            audio_path,
            chunk_seconds = chunk_seconds,
            batch_size = batch_size
        )

        if split_result is None:
            # Process original file directly
            print("Processing original file directly:")
            with torch.no_grad():
                output = self.model.transcribe([audio_path])
            transcript = output[0].text
        else:
            # Use split result
            transcript = split_result

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
            "length": len(transcript)
        }

        return result


if __name__ == "__main__":
    # Example usage
    processor = ASRProcessor()

    # Example: transcribe a file
    result = processor.transcribe(
        audio_path = "lecture_recording.mp3",
        chunk_seconds = 300,
        batch_size = 4,
        output_path = "transcript_result.txt"
    )

    print(f"\nTotal transcript length: {result['length']} characters")
