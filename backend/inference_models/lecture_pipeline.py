"""
Integrated Lecture Reconstruction Pipeline
Combines ASR, Slide Matching, and TTS to reconstruct lectures from audio and PDF
"""

import json
import os
from pathlib import Path
from typing import Callable, Any
from datetime import datetime
from dataclasses import dataclass, asdict

from .asr_processor import ASRProcessor
from .slide_matching_processor import SlideMatchingProcessor
from .translation_processor import TranslationProcessor
from .tts_processor import TTSProcessor


@dataclass
class PipelineOutput:
    """
    Structured output for API responses.
    Contains paths to generated files and metadata for client delivery.
    """
    # Core outputs for client delivery
    audio_file: str  # Path to Opus audio file
    timestamps_file: str  # Path to timestamps.json

    # Metadata for client
    lecture_name: str = ""
    total_duration: int = 0  # milliseconds
    total_sentences: int = 0
    audio_sample_rate: int = 24000

    # Processing info
    timestamp: str = ""
    output_directory: str = ""

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return asdict(self)

    def get_client_files(self) -> dict[str, str]:
        """
        Get only the files that should be sent to client.
        Returns dict with format: {file_type: file_path}
        """
        return {
            'audio': self.audio_file,
            'timestamps': self.timestamps_file
        }


class LecturePipeline:
    """
    Integrated pipeline for lecture reconstruction.

    Pipeline flow:
    1. ASR: Transcribe lecture audio to text
    2. Slide Matching: Match transcript sentences to PDF slides
    3. TTS: Generate new audio with slide alignment
    """

    def __init__(
        self,
        # ASR settings
        asr_model: str = "turbo",
        asr_chunk_seconds: int = 300,
        asr_batch_size: int = 4,

        # Slide matching settings
        matching_model: str = 'nvidia/llama-nemoretriever-colembed-3b-v1',
        matching_batch_size: int = 4,
        use_image_batching: bool = False, # for stability
        image_batch_size: int = 4,
        jump_penalty: float = 0.2,
        backward_weight: float = 2.0,
        use_exponential_scaling: bool = True,
        exponential_scale: float = 2.8,
        use_confidence_boost: bool = True,
        confidence_threshold: float = 0.925,
        confidence_weight: float = 2.25,
        use_context_similarity: bool = True,
        context_weight: float = 0.05,
        context_update_rate: float = 0.25,

        # Translation settings
        translation_model: str = "tencent/Hunyuan-MT-7B-fp8",
        translation_tensor_parallel_size: int = 1,
        enable_translation: bool = True,

        # TTS settings
        enable_tts: bool = True,
        tts_voice: str = 'af_heart',
        tts_speed: float = 1.0,
        tts_lang_code: str = 'a',
        tts_silence_duration: float = 0.2,

        # General settings
        device: str = 'cuda',
        output_dir: str = './pipeline_output'
    ):
        """
        Initialize the integrated lecture pipeline.

        Args:
            asr_model: Whisper model name (turbo, large-v3, etc.)
            asr_chunk_seconds: Chunk duration for long audio files
            asr_batch_size: ASR batch size
            matching_model: Multimodal matching model name
            matching_batch_size: Matching batch size for text queries
            use_image_batching: Enable batched image embedding computation
            image_batch_size: Batch size for image embedding when batching is enabled
            jump_penalty: Slide jump penalty
            backward_weight: Backward jump penalty multiplier
            use_exponential_scaling: Use exponential scaling for matching scores
            exponential_scale: Exponential scale factor
            use_confidence_boost: Boost scores when confidence is low
            confidence_threshold: Confidence threshold
            confidence_weight: Confidence boost weight
            use_context_similarity: Enable context-aware scoring via EMA
            context_weight: weight for context similarity contribution
            context_update_rate: Update rate for EMA
            translation_model: Translation model name
            translation_tensor_parallel_size: Number of GPUs for translation tensor parallelism
            enable_translation: Enable translation (direction determined per request)
            enable_tts: Enable TTS generation (only for English lectures)
            tts_voice: TTS voice style
            tts_speed: TTS playback speed
            tts_lang_code: TTS language code
            tts_silence_duration: Silence between sentences
            device: Device to use (cuda/cpu)
            output_dir: Output directory for results
        """
        self.output_dir = output_dir
        self.device = device
        self.enable_translation = enable_translation
        self.enable_tts = enable_tts

        # Initialize processors
        print("="*60)
        print("Initializing Lecture Reconstruction Pipeline")
        print("="*60)

        self.asr = ASRProcessor(
            model_name = asr_model,
            device = device
        )
        self.asr_chunk_seconds = asr_chunk_seconds
        self.asr_batch_size = asr_batch_size

        self.matcher = SlideMatchingProcessor(
            model_name = matching_model,
            device = device,
            batch_size = matching_batch_size,
            use_image_batching = use_image_batching,
            image_batch_size = image_batch_size,
            jump_penalty = jump_penalty,
            backward_weight = backward_weight,
            use_exponential_scaling = use_exponential_scaling,
            exponential_scale = exponential_scale,
            use_confidence_boost = use_confidence_boost,
            confidence_threshold = confidence_threshold,
            confidence_weight = confidence_weight,
            use_context_similarity = use_context_similarity,
            context_weight = context_weight,
            context_update_rate = context_update_rate
        )

        # Initialize translation processor if enabled
        # Translation direction will be passed as parameter per request
        if self.enable_translation:
            self.translator = TranslationProcessor(
                model_name = translation_model,
                device = device,
                tensor_parallel_size = translation_tensor_parallel_size
            )
            print("\nTranslation processor initialized (direction will be specified per request)")
        else:
            self.translator = None
            print("\nTranslation disabled - No translations will be generated")

        # Initialize TTS processor if enabled
        if self.enable_tts:
            self.tts = TTSProcessor(
                voice = tts_voice,
                speed = tts_speed,
                lang_code = tts_lang_code,
                silence_duration = tts_silence_duration
            )
            print("\nTTS processor initialized (will be used for English lectures)")
        else:
            self.tts = None
            print("\nTTS disabled - Original timestamps will be preserved")

        print("\nPipeline initialized successfully!")

    def run(
        self,
        audio_path: str,
        pdf_path: str,
        language: str = "en",
        lecture_name: str | None = None,
        sentence_splitter: Callable[[str], list[str]] | None = None,
        save_intermediate: bool = True,
        progress_callback: Callable[[str, float, str], None] | None = None
    ) -> PipelineOutput:
        """
        Run the complete lecture reconstruction pipeline.

        Args:
            audio_path: Path to lecture audio file
            pdf_path: Path to lecture PDF file
            language: Language code for ASR transcription ('en' for English, 'ko' for Korean)
            lecture_name: Optional lecture name for output files
            sentence_splitter: Optional function to split transcript into sentences
            save_intermediate: Save intermediate results (WAV, transcript, matching.json)
            progress_callback: Optional callback function(stage: str, progress: float, message: str)
                             stage is one of: "processing_asr", "processing_matching", "processing_translation", "processing_tts"
                             progress is 0-100 representing percentage completion within that stage

        Returns:
            PipelineOutput object with paths to Opus audio and timestamps.json
        """
        # Generate lecture name if not provided
        if lecture_name is None:
            lecture_name = f"lecture_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        # Create lecture-specific output directory
        lecture_output_dir = os.path.join(self.output_dir, lecture_name)
        os.makedirs(lecture_output_dir, exist_ok = True)

        print("\n" + "="*60)
        print(f"Running Pipeline for: {lecture_name}")
        print(f"Lecture Language: {language}")
        print("="*60)

        # Configure translation direction and TTS based on lecture language
        is_korean_lecture = (language == "ko")
        should_run_tts = self.enable_tts and not is_korean_lecture  # TTS only for English lectures

        # Determine translation direction
        if is_korean_lecture:
            # Korean lecture → translate to English
            source_lang = "ko"
            target_lang = "en"
            print("Translation: Korean → English")
        else:
            # English lecture → translate to Korean
            source_lang = "en"
            target_lang = "ko"
            print("Translation: English → Korean")

        if is_korean_lecture:
            print("Korean lecture mode: ASR + Matching + English Translation (No TTS)")
        else:
            print("English lecture mode: ASR + Matching + Korean Translation + TTS")

        results = {
            'lecture_name': lecture_name,
            'audio_path': audio_path,
            'pdf_path': pdf_path,
            'timestamp': datetime.now().isoformat(),
            'lecture_language': language
        }

        # ====================================================================
        # Step 1: ASR - Transcribe audio
        # ====================================================================
        print("\n" + "="*60)
        print(f"STEP 1/{4 if self.enable_translation else 3}: ASR - Transcribing Audio")
        print("="*60)

        if progress_callback:
            progress_callback("processing_asr", 10.0, "Starting ASR processing...")

        transcript_path = os.path.join(lecture_output_dir, "transcript.txt") if save_intermediate else None

        # Create a wrapper callback for ASR progress
        def asr_progress_callback(progress: float, message: str):
            if progress_callback:
                # Map ASR progress (0-100) to pipeline progress
                # Korean: 10-50% (40% range), English: 10-40% (30% range)
                if is_korean_lecture:
                    pipeline_progress = 10.0 + (progress * 0.4)
                else:
                    pipeline_progress = 10.0 + (progress * 0.3)
                progress_callback("processing_asr", pipeline_progress, f"ASR: {message}")

        asr_result = self.asr.transcribe(
            audio_path = audio_path,
            language = language,
            chunk_seconds = self.asr_chunk_seconds,
            batch_size = self.asr_batch_size,
            output_path = transcript_path,
            progress_callback = asr_progress_callback
        )

        transcript = asr_result['transcript']
        segment_timestamps = asr_result.get('segment_timestamps', [])
        results['asr'] = asr_result

        print(f"\n✓ ASR Complete: {len(transcript)} characters")
        print(f"✓ Segment timestamps extracted: {len(segment_timestamps)} segments")

        if progress_callback:
            if is_korean_lecture:
                progress_callback("processing_asr", 50.0, "ASR processing completed")
            else:
                progress_callback("processing_asr", 40.0, "ASR processing completed")

        # Optionally unload ASR model to free memory
        self.asr.unload_model()

        # ====================================================================
        # Step 2: Slide Matching - Match transcript to slides
        # ====================================================================
        print("\n" + "="*60)
        print(f"STEP 2/{4 if self.enable_translation else 3}: Slide Matching - Matching to PDF Slides")
        print("="*60)

        if progress_callback:
            if is_korean_lecture:
                progress_callback("processing_matching", 50.0, "Starting slide matching...")
            else:
                progress_callback("processing_matching", 40.0, "Starting slide matching...")

        # Use ASR segments directly as sentences (already split by punctuation)
        # Extract segment texts for matching
        if segment_timestamps:
            sentences = [seg['text'] for seg in segment_timestamps]
            print(f"Using {len(sentences)} ASR segments for matching")
        elif sentence_splitter is not None:
            # Fallback: use sentence splitter if no segments available
            sentences = sentence_splitter(transcript)
            print(f"Fallback: Split transcript into {len(sentences)} sentences")
        else:
            # Use full transcript as single query
            sentences = None
            print("Using full transcript as single query")

        # Create a wrapper callback for matching progress
        def matching_progress_callback(progress: float, message: str):
            if progress_callback:
                # Map matching progress (0-100) to pipeline progress
                # Korean: 50-80% (30% range), English: 40-70% (30% range)
                if is_korean_lecture:
                    pipeline_progress = 50.0 + (progress * 0.3)
                else:
                    pipeline_progress = 40.0 + (progress * 0.3)
                progress_callback("processing_matching", pipeline_progress, f"Matching: {message}")

        matching_results = self.matcher.match_transcript_to_slides(
            transcript = transcript,
            pdf_path = pdf_path,
            sentences = sentences,
            progress_callback = matching_progress_callback
        )

        # Add original audio timestamps directly from segments (1:1 correspondence)
        if segment_timestamps and len(segment_timestamps) == len(matching_results):
            for i, result in enumerate(matching_results):
                result['original_start_time'] = segment_timestamps[i]['start']
                result['original_end_time'] = segment_timestamps[i]['end']
            print(f"✓ Added original audio timestamps to {len(matching_results)} results")
        else:
            print(f"Warning: Segment count mismatch - segments: {len(segment_timestamps)}, results: {len(matching_results)}")

        results['matching'] = {
            'num_matches': len(matching_results),
            'results': matching_results
        }

        # Save matching results if requested
        if save_intermediate:
            matching_json_path = os.path.join(lecture_output_dir, "matching.json")
            with open(matching_json_path, 'w', encoding = 'utf-8') as f:
                json.dump(matching_results, f, ensure_ascii = False, indent = 2)
            print(f"\n✓ Matching results saved: {matching_json_path}")

        print(f"\n✓ Slide Matching Complete: {len(matching_results)} matches")

        if progress_callback:
            if is_korean_lecture:
                progress_callback("processing_matching", 80.0, "Slide matching completed")
            else:
                progress_callback("processing_matching", 70.0, "Slide matching completed")

        # Optionally unload matching model to free memory
        self.matcher.unload_model()

        # ====================================================================
        # Step 3: Translation (Optional)
        # ====================================================================
        if self.enable_translation:
            print("\n" + "="*60)
            if is_korean_lecture:
                print("STEP 3/3: Translation - Translating to English")
            else:
                print("STEP 3/4: Translation - Translating to Korean")
            print("="*60)

            if progress_callback:
                if is_korean_lecture:
                    progress_callback("processing_translation", 80.0, "Starting translation...")
                else:
                    progress_callback("processing_translation", 70.0, "Starting translation...")

            # Create a wrapper callback for translation progress
            def translation_progress_callback(progress: float, message: str):
                if progress_callback:
                    # Map translation progress (0-100) to pipeline progress
                    # Korean: 80-95% (15% range), English: 70-80% (10% range)
                    if is_korean_lecture:
                        pipeline_progress = 80.0 + (progress * 0.15)
                    else:
                        pipeline_progress = 70.0 + (progress * 0.1)
                    progress_callback("processing_translation", pipeline_progress, f"Translation: {message}")

            matching_results = self.translator.translate_matching_results(
                matching_results = matching_results,
                source_lang = source_lang,
                target_lang = target_lang,
                progress_callback = translation_progress_callback
            )

            results['translation'] = {
                'num_translated': len(matching_results)
            }

            # Save translated matching results if requested
            if save_intermediate:
                translated_json_path = os.path.join(lecture_output_dir, "matching_with_translation.json")
                with open(translated_json_path, 'w', encoding = 'utf-8') as f:
                    json.dump(matching_results, f, ensure_ascii = False, indent = 2)
                print(f"\n✓ Translated results saved: {translated_json_path}")

            print(f"\n✓ Translation Complete: {len(matching_results)} sentences translated")

            if progress_callback:
                if is_korean_lecture:
                    progress_callback("processing_translation", 95.0, "Translation completed")
                else:
                    progress_callback("processing_translation", 80.0, "Translation completed")

            # Optionally unload translation model to free memory
            self.translator.unload_model()

        # ====================================================================
        # Step 4: TTS - Generate audio with slide alignment (English lectures only)
        # ====================================================================
        output_json_path = os.path.join(lecture_output_dir, "timestamps.json")

        if should_run_tts:
            # English lecture: Generate TTS audio
            print("\n" + "="*60)
            print(f"STEP {4 if self.enable_translation else 3}/{4 if self.enable_translation else 3}: TTS - Generating Audio with Slide Alignment")
            print("="*60)

            tts_start_progress = 80.0 if self.enable_translation else 70.0
            if progress_callback:
                progress_callback("processing_tts", tts_start_progress, "Starting TTS generation...")

            # Generate WAV file first (intermediate)
            output_wav_path = os.path.join(lecture_output_dir, "reconstructed.wav")

            # Create a wrapper callback for TTS progress
            def tts_progress_callback(progress: float, message: str):
                if progress_callback:
                    # Map TTS progress (0-100) to pipeline progress
                    # If translation enabled: 80-95, else: 70-95
                    progress_range = 0.15 if self.enable_translation else 0.25
                    pipeline_progress = tts_start_progress + (progress * progress_range)
                    progress_callback("processing_tts", pipeline_progress, f"TTS: {message}")

            tts_result = self.tts.generate_from_matching_results(
                matching_results = matching_results,
                output_audio_path = output_wav_path,
                output_json_path = output_json_path,
                export_formats = ['opus'],  # Always export to Opus for client
                progress_callback = tts_progress_callback
            )

            # Post-process TTS result to standardize timestamp format
            # TTS processor now generates timestamps with text_eng/text_kor and all timing fields
            with open(output_json_path, 'r', encoding='utf-8') as f:
                tts_output = json.load(f)

            # Extract timestamps array from TTS output
            tts_timestamps = tts_output.get('timestamps', [])

            # Rename TTS time fields to follow naming convention
            timestamps_data = []
            for entry in tts_timestamps:
                timestamp_entry = {
                    'text_eng': entry.get('text_eng', ''),
                    'text_kor': entry.get('text_kor', ''),
                    'slide_number': entry.get('slide_number', 1),
                    'tts_start_time': entry.get('start_time', 0),  # Rename: start_time -> tts_start_time (ms)
                    'tts_end_time': entry.get('end_time', 0),  # Rename: end_time -> tts_end_time (ms)
                    'original_start_time': entry.get('original_start_time', 0),  # Original audio start time (ms)
                    'original_end_time': entry.get('original_end_time', 0)  # Original audio end time (ms)
                }
                timestamps_data.append(timestamp_entry)

            # Save updated timestamps.json with standardized field names
            with open(output_json_path, 'w', encoding='utf-8') as f:
                json.dump(timestamps_data, f, ensure_ascii=False, indent=2)

            print(f"\n✓ TTS Complete: {tts_result['metadata']['total_duration']}ms audio generated")

            if progress_callback:
                progress_callback("processing_tts", 95.0, "TTS generation completed")

            # Optionally unload TTS model
            self.tts.unload_model()
        else:
            # Korean lecture: Skip TTS, create timestamps.json from original timestamps
            print("\n" + "="*60)
            print("Skipping TTS - Creating timestamps from original audio")
            print("="*60)

            if progress_callback:
                progress_callback("processing_tts", 95.0, "Creating timestamps from original audio...")

            # Create timestamps.json with original audio timestamps
            # For Korean lectures: text_eng and text_kor are already in matching_results
            timestamps_data = []
            for result in matching_results:
                # Convert seconds to milliseconds (integer)
                original_start_ms = int(round(result.get('original_start_time', 0) * 1000))
                original_end_ms = int(round(result.get('original_end_time', 0) * 1000))

                timestamp_entry = {
                    'text_eng': result.get('text_eng', ''),
                    'text_kor': result.get('text_kor', ''),
                    'slide_number': result['matched_page'],
                    'tts_start_time': 0,  # No TTS for Korean lectures
                    'tts_end_time': 0,  # No TTS for Korean lectures
                    'original_start_time': original_start_ms,  # Original audio start time (ms)
                    'original_end_time': original_end_ms  # Original audio end time (ms)
                }

                timestamps_data.append(timestamp_entry)

            # Save timestamps.json
            with open(output_json_path, 'w', encoding='utf-8') as f:
                json.dump(timestamps_data, f, ensure_ascii=False, indent=2)

            print(f"\n✓ Timestamps created: {len(timestamps_data)} entries with original audio timing")

            # Create a dummy tts_result for consistency
            tts_result = {
                'metadata': {
                    'total_duration': matching_results[-1].get('original_end_time', 0) if matching_results else 0,
                    'total_sentences': len(matching_results),
                    'sample_rate': 24000  # Default sample rate
                }
            }

            if progress_callback:
                progress_callback("processing_tts", 99.0, "Timestamps created from original audio")

        # ====================================================================
        # Prepare output paths
        # ====================================================================
        # For English lectures: TTS generates audio
        # For Korean lectures: No audio file (client already has original)
        if should_run_tts:
            output_opus_path = os.path.join(lecture_output_dir, "reconstructed.opus")
        else:
            output_opus_path = None  # No audio file for Korean lectures

        # Save intermediate files if requested
        if save_intermediate:
            final_results_path = os.path.join(lecture_output_dir, "pipeline_results.json")
            with open(final_results_path, 'w', encoding = 'utf-8') as f:
                # Make results JSON serializable
                json_results = {
                    'lecture_name': results['lecture_name'],
                    'audio_path': results['audio_path'],
                    'pdf_path': results['pdf_path'],
                    'timestamp': results['timestamp'],
                    'lecture_language': results['lecture_language'],
                    'asr': {
                        'transcript_length': results['asr']['length'],
                        'transcript': results['asr']['transcript'][:500] + '...' if len(results['asr']['transcript']) > 500 else results['asr']['transcript']
                    },
                    'matching': {
                        'num_matches': results['matching']['num_matches']
                    },
                    'tts': tts_result,
                    'output_audio': output_opus_path
                }
                json.dump(json_results, f, ensure_ascii = False, indent = 2)
            print(f"\n✓ Final results saved: {final_results_path}")
        else:
            # If not saving intermediate files, remove WAV file
            if should_run_tts:
                output_wav_path = os.path.join(lecture_output_dir, "reconstructed.wav")
                if os.path.exists(output_wav_path):
                    os.remove(output_wav_path)
                    print(f"\n✓ Intermediate WAV file removed (kept Opus only)")

        print("\n" + "="*60)
        print("PIPELINE COMPLETE!")
        print("="*60)
        print(f"Output directory: {lecture_output_dir}")
        if output_opus_path:
            print(f"Client audio file: {output_opus_path}")
        else:
            print("Client audio file: None (using original audio)")
        print(f"Client timestamps file: {output_json_path}")

        # Return structured output for API
        return PipelineOutput(
            audio_file = output_opus_path if output_opus_path else "",  # Empty string if no audio
            timestamps_file = output_json_path,
            lecture_name = lecture_name,
            total_duration = tts_result['metadata']['total_duration'],
            total_sentences = tts_result['metadata']['total_sentences'],
            audio_sample_rate = tts_result['metadata']['sample_rate'],
            timestamp = results['timestamp'],
            output_directory = lecture_output_dir
        )


def simple_sentence_splitter(text: str) -> list[str]:
    """
    Simple sentence splitter (splits on '. ', '! ', '? ').
    For production use, consider using NLTK or spaCy.

    Args:
        text: Input text

    Returns:
        List of sentences
    """
    import re
    # Split on sentence boundaries
    sentences = re.split(r'[.!?]+\s+', text)
    # Filter out empty sentences
    sentences = [s.strip() for s in sentences if s.strip()]
    return sentences


if __name__ == "__main__":
    # Example usage - English lecture
    pipeline = LecturePipeline(
        # ASR settings
        asr_model = "turbo",
        asr_language = "en",  # or "ko" for Korean
        asr_chunk_seconds = 300,
        asr_batch_size = 4,

        # Matching settings
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

        # TTS settings
        tts_voice = 'af_heart',
        tts_speed = 1.0,

        # General settings
        device = 'cuda',
        output_dir = './pipeline_output'
    )

    # Run pipeline
    output = pipeline.run(
        audio_path = 'test_lecture/lecture_recording.mp3',
        pdf_path = 'test_lecture/lecture_slides.pdf',
        lecture_name = 'my_lecture',
        sentence_splitter = simple_sentence_splitter,
        save_intermediate = True
    )

    print(f"\n✓ Pipeline completed successfully!")
    print(f"  - Lecture name: {output.lecture_name}")
    print(f"  - Total sentences: {output.total_sentences}")
    print(f"  - Audio duration: {output.total_duration:.2f}s")
    print(f"\n✓ Client files:")
    for file_type, file_path in output.get_client_files().items():
        print(f"  - {file_type}: {file_path}")
