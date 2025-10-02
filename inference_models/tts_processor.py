"""
TTS Processor Module
Text-to-Speech generation using Kokoro TTS with slide alignment
"""

import json
import numpy as np
from kokoro import KPipeline
import soundfile as sf
import subprocess
import os
from typing import List, Dict, Optional
from pathlib import Path


class TTSProcessor:
    """
    Text-to-Speech processor with slide alignment and format conversion.
    """

    def __init__(
        self,
        voice: str = 'af_heart',
        speed: float = 1.0,
        lang_code: str = 'a',
        silence_duration: float = 0.2,
        sample_rate: int = 24000
    ):
        """
        Initialize TTS processor.

        Args:
            voice: Voice style (af_heart, af_bella, af_sarah, am_adam, am_michael)
            speed: Playback speed multiplier
            lang_code: Language code ('a' = American English)
            silence_duration: Silence between sentences (seconds)
            sample_rate: Audio sample rate (fixed at 24000 for Kokoro)
        """
        self.voice = voice
        self.speed = speed
        self.lang_code = lang_code
        self.silence_duration = silence_duration
        self.sample_rate = sample_rate
        self.pipeline = None

        print(f"Initializing TTS Processor")
        print(f"Voice: {voice}, Speed: {speed}, Lang: {lang_code}")

    def load_model(self):
        """Load TTS pipeline."""
        if self.pipeline is not None:
            print("Pipeline already loaded")
            return

        print(f"Loading Kokoro TTS pipeline (lang_code: {self.lang_code})...")
        self.pipeline = KPipeline(lang_code = self.lang_code)
        print("TTS pipeline loaded successfully")

    def unload_model(self):
        """Unload pipeline to free memory."""
        if self.pipeline is not None:
            del self.pipeline
            self.pipeline = None
            print("TTS pipeline unloaded")

    def generate_audio(
        self,
        sentences: List[Dict[str, any]],
        output_audio_path: str = "lecture_audio.wav",
        output_json_path: Optional[str] = None,
        export_formats: Optional[List[str]] = None
    ) -> Dict[str, any]:
        """
        Generate audio from sentences with slide alignment.

        Args:
            sentences: List of dicts with 'text' and 'slide_number' keys
            output_audio_path: Output WAV file path
            output_json_path: Optional JSON metadata output path
            export_formats: Optional list of additional formats ['opus', 'aac']

        Returns:
            Dictionary with metadata and timestamps
        """
        if self.pipeline is None:
            self.load_model()

        print(f"Generating audio for {len(sentences)} sentences...")

        # Result storage
        all_audio = []
        timestamp_data = []
        current_time = 0.0

        for idx, sentence_info in enumerate(sentences):
            text = sentence_info.get('text', '')
            slide_number = sentence_info.get('slide_number', 1)

            print(f"Processing: [{idx+1}/{len(sentences)}] [Slide {slide_number}] {text[:50]}...")

            try:
                # TTS generation
                generator = self.pipeline(text, voice = self.voice, speed = self.speed)

                # Collect audio segments
                sentence_audio_parts = []
                for graphemes, phonemes, audio in generator:
                    sentence_audio_parts.append(audio)

                # Merge segments
                if sentence_audio_parts:
                    sentence_audio = np.concatenate(sentence_audio_parts)

                    # Calculate duration
                    duration = len(sentence_audio) / self.sample_rate

                    # Save timestamp info
                    timestamp_info = {
                        "sentence_id": idx + 1,
                        "text": text,
                        "slide_number": slide_number,
                        "start_time": round(current_time, 3),
                        "end_time": round(current_time + duration, 3),
                        "duration": round(duration, 3)
                    }
                    timestamp_data.append(timestamp_info)

                    # Accumulate audio
                    all_audio.append(sentence_audio)

                    # Update time
                    current_time += duration + self.silence_duration

            except Exception as e:
                print(f"Error processing sentence {idx+1}: {e}")
                continue

        # Merge all audio
        if all_audio:
            # Add silence between sentences
            silence = np.zeros(int(self.silence_duration * self.sample_rate))
            merged_audio = []

            for audio_segment in all_audio:
                merged_audio.append(audio_segment)
                merged_audio.append(silence)

            # Remove last silence
            if merged_audio:
                merged_audio.pop()

            final_audio = np.concatenate(merged_audio)

            # Save WAV file
            Path(output_audio_path).parent.mkdir(parents = True, exist_ok = True)
            sf.write(output_audio_path, final_audio, self.sample_rate)
            print(f"\n✓ Audio file saved: {output_audio_path}")
            print(f"  - Total duration: {len(final_audio) / self.sample_rate:.2f}s")

            # File size
            wav_size = os.path.getsize(output_audio_path) / (1024 * 1024)  # MB
            print(f"  - WAV file size: {wav_size:.2f} MB")

            # Additional format conversion
            if export_formats:
                self._convert_formats(output_audio_path, export_formats, wav_size)

        # Save JSON metadata
        output_data = {
            "metadata": {
                "total_sentences": len(timestamp_data),
                "total_duration": round(current_time - self.silence_duration, 3) if timestamp_data else 0,
                "voice": self.voice,
                "speed": self.speed,
                "language_code": self.lang_code,
                "sample_rate": self.sample_rate
            },
            "timestamps": timestamp_data
        }

        if output_json_path:
            Path(output_json_path).parent.mkdir(parents = True, exist_ok = True)
            with open(output_json_path, 'w', encoding = 'utf-8') as f:
                json.dump(output_data, f, ensure_ascii = False, indent = 2)
            print(f"✓ Timestamp JSON saved: {output_json_path}")

        return output_data

    def _convert_formats(
        self,
        wav_path: str,
        formats: List[str],
        wav_size: float
    ):
        """
        Convert WAV to additional formats using ffmpeg.

        Args:
            wav_path: Input WAV file path
            formats: List of formats to convert to
            wav_size: Original WAV file size in MB
        """
        print(f"\nConverting to additional formats...")
        base_path = os.path.splitext(wav_path)[0]

        for fmt in formats:
            if fmt.lower() == 'opus':
                output_path = f"{base_path}.opus"
                cmd = [
                    'ffmpeg', '-y', '-i', wav_path,
                    '-c:a', 'libopus',
                    '-b:a', '64k',
                    '-compression_level', '10',
                    output_path
                ]

            elif fmt.lower() == 'aac':
                output_path = f"{base_path}.m4a"
                cmd = [
                    'ffmpeg', '-y', '-i', wav_path,
                    '-c:a', 'aac',
                    '-b:a', '192k',
                    '-movflags', '+faststart',
                    output_path
                ]

            else:
                print(f"  ⚠ Unsupported format: {fmt}")
                continue

            try:
                subprocess.run(cmd, check = True, capture_output = True)
                compressed_size = os.path.getsize(output_path) / (1024 * 1024)
                compression_ratio = (1 - compressed_size / wav_size) * 100
                print(f"  ✓ {fmt.upper()} conversion complete: {output_path}")
                print(f"    - File size: {compressed_size:.2f} MB (compression: {compression_ratio:.1f}%)")
            except subprocess.CalledProcessError as e:
                print(f"  ✗ {fmt.upper()} conversion failed: {e.stderr.decode() if e.stderr else str(e)}")
            except FileNotFoundError:
                print(f"  ✗ ffmpeg not found. Install ffmpeg to use format conversion.")
                break

    def generate_from_matching_results(
        self,
        matching_results: List[Dict[str, any]],
        output_audio_path: str = "lecture_audio.wav",
        output_json_path: Optional[str] = None,
        export_formats: Optional[List[str]] = None
    ) -> Dict[str, any]:
        """
        Generate audio from slide matching results.

        Args:
            matching_results: Results from SlideMatchingProcessor
            output_audio_path: Output WAV file path
            output_json_path: Optional JSON metadata output path
            export_formats: Optional list of additional formats

        Returns:
            Dictionary with metadata and timestamps
        """
        # Convert matching results to sentence format
        sentences = []
        for result in matching_results:
            sentences.append({
                'text': result['text'],
                'slide_number': result['matched_page']
            })

        return self.generate_audio(
            sentences = sentences,
            output_audio_path = output_audio_path,
            output_json_path = output_json_path,
            export_formats = export_formats
        )


if __name__ == "__main__":
    # Example usage
    processor = TTSProcessor(
        voice = 'af_heart',
        speed = 1.0,
        lang_code = 'a',
        silence_duration = 0.2
    )

    # Example sentences with slide numbers
    sentences = [
        {"text": "Welcome to this lecture on deep learning.", "slide_number": 1},
        {"text": "Today we will discuss neural networks.", "slide_number": 1},
        {"text": "Let's start with the basics.", "slide_number": 2},
    ]

    result = processor.generate_audio(
        sentences = sentences,
        output_audio_path = "example_lecture.wav",
        output_json_path = "example_timestamps.json",
        export_formats = ['opus', 'aac']
    )

    print(f"\nGenerated {result['metadata']['total_sentences']} sentences")
    print(f"Total duration: {result['metadata']['total_duration']}s")
