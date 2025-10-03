"""
Integrated Lecture Reconstruction Pipeline
Combines ASR, Slide Matching, and TTS to reconstruct lectures from audio and PDF
"""

import json
import os
from pathlib import Path
from typing import Optional, List, Dict
from datetime import datetime

from asr_processor import ASRProcessor
from slide_matching_processor import SlideMatchingProcessor
from tts_processor import TTSProcessor


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
        asr_model: str = "nvidia/parakeet-tdt-0.6b-v2",
        asr_chunk_seconds: int = 300,
        asr_batch_size: int = 4,

        # Slide matching settings
        matching_model: str = 'nvidia/llama-nemoretriever-colembed-3b-v1',
        matching_batch_size: int = 4,
        jump_penalty: float = 0.1,
        backward_weight: float = 2.0,
        use_exponential_scaling: bool = False,
        exponential_scale: float = 3.0,
        use_confidence_boost: bool = False,
        confidence_threshold: float = 0.95,
        confidence_weight: float = 1.5,

        # TTS settings
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
            asr_model: ASR model name
            asr_chunk_seconds: Chunk duration for long audio files
            asr_batch_size: ASR batch size
            matching_model: Multimodal matching model name
            matching_batch_size: Matching batch size
            jump_penalty: Slide jump penalty
            backward_weight: Backward jump penalty multiplier
            use_exponential_scaling: Use exponential scaling for matching scores
            exponential_scale: Exponential scale factor
            use_confidence_boost: Boost scores when confidence is low
            confidence_threshold: Confidence threshold
            confidence_weight: Confidence boost weight
            tts_voice: TTS voice style
            tts_speed: TTS playback speed
            tts_lang_code: TTS language code
            tts_silence_duration: Silence between sentences
            device: Device to use (cuda/cpu)
            output_dir: Output directory for results
        """
        self.output_dir = output_dir
        self.device = device

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
            jump_penalty = jump_penalty,
            backward_weight = backward_weight,
            use_exponential_scaling = use_exponential_scaling,
            exponential_scale = exponential_scale,
            use_confidence_boost = use_confidence_boost,
            confidence_threshold = confidence_threshold,
            confidence_weight = confidence_weight
        )

        self.tts = TTSProcessor(
            voice = tts_voice,
            speed = tts_speed,
            lang_code = tts_lang_code,
            silence_duration = tts_silence_duration
        )

        print("\nPipeline initialized successfully!")

    def run(
        self,
        audio_path: str,
        pdf_path: str,
        lecture_name: Optional[str] = None,
        sentence_splitter: Optional[callable] = None,
        export_audio_formats: Optional[List[str]] = None,
        save_intermediate: bool = True
    ) -> Dict[str, any]:
        """
        Run the complete lecture reconstruction pipeline.

        Args:
            audio_path: Path to lecture audio file
            pdf_path: Path to lecture PDF file
            lecture_name: Optional lecture name for output files
            sentence_splitter: Optional function to split transcript into sentences
            export_audio_formats: Optional list of audio formats to export ['opus', 'aac']
            save_intermediate: Save intermediate results

        Returns:
            Dictionary with all pipeline results
        """
        # Generate lecture name if not provided
        if lecture_name is None:
            lecture_name = f"lecture_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        # Create lecture-specific output directory
        lecture_output_dir = os.path.join(self.output_dir, lecture_name)
        os.makedirs(lecture_output_dir, exist_ok = True)

        print("\n" + "="*60)
        print(f"Running Pipeline for: {lecture_name}")
        print("="*60)

        results = {
            'lecture_name': lecture_name,
            'audio_path': audio_path,
            'pdf_path': pdf_path,
            'timestamp': datetime.now().isoformat()
        }

        # ====================================================================
        # Step 1: ASR - Transcribe audio
        # ====================================================================
        print("\n" + "="*60)
        print("STEP 1/3: ASR - Transcribing Audio")
        print("="*60)

        transcript_path = os.path.join(lecture_output_dir, "transcript.txt") if save_intermediate else None

        asr_result = self.asr.transcribe(
            audio_path = audio_path,
            chunk_seconds = self.asr_chunk_seconds,
            batch_size = self.asr_batch_size,
            output_path = transcript_path
        )

        transcript = asr_result['transcript']
        results['asr'] = asr_result

        print(f"\n✓ ASR Complete: {len(transcript)} characters")

        # Optionally unload ASR model to free memory
        self.asr.unload_model()

        # ====================================================================
        # Step 2: Slide Matching - Match transcript to slides
        # ====================================================================
        print("\n" + "="*60)
        print("STEP 2/3: Slide Matching - Matching to PDF Slides")
        print("="*60)

        # Split transcript into sentences if splitter provided
        if sentence_splitter is not None:
            sentences = sentence_splitter(transcript)
            print(f"Split transcript into {len(sentences)} sentences")
        else:
            # Use full transcript as single query
            sentences = None
            print("Using full transcript as single query")

        matching_results = self.matcher.match_transcript_to_slides(
            transcript = transcript,
            pdf_path = pdf_path,
            sentences = sentences
        )

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

        # Optionally unload matching model to free memory
        self.matcher.unload_model()

        # ====================================================================
        # Step 3: TTS - Generate audio with slide alignment
        # ====================================================================
        print("\n" + "="*60)
        print("STEP 3/3: TTS - Generating Audio with Slide Alignment")
        print("="*60)

        output_audio_path = os.path.join(lecture_output_dir, "reconstructed.wav")
        output_json_path = os.path.join(lecture_output_dir, "timestamps.json") if save_intermediate else None

        tts_result = self.tts.generate_from_matching_results(
            matching_results = matching_results,
            output_audio_path = output_audio_path,
            output_json_path = output_json_path,
            export_formats = export_audio_formats
        )

        results['tts'] = tts_result
        results['output_audio'] = output_audio_path

        print(f"\n✓ TTS Complete: {tts_result['metadata']['total_duration']:.2f}s audio generated")

        # Optionally unload TTS model
        self.tts.unload_model()

        # ====================================================================
        # Save final results
        # ====================================================================
        if save_intermediate:
            final_results_path = os.path.join(lecture_output_dir, "pipeline_results.json")
            with open(final_results_path, 'w', encoding = 'utf-8') as f:
                # Make results JSON serializable
                json_results = {
                    'lecture_name': results['lecture_name'],
                    'audio_path': results['audio_path'],
                    'pdf_path': results['pdf_path'],
                    'timestamp': results['timestamp'],
                    'asr': {
                        'transcript_length': results['asr']['length'],
                        'transcript': results['asr']['transcript'][:500] + '...' if len(results['asr']['transcript']) > 500 else results['asr']['transcript']
                    },
                    'matching': {
                        'num_matches': results['matching']['num_matches']
                    },
                    'tts': results['tts'],
                    'output_audio': results['output_audio']
                }
                json.dump(json_results, f, ensure_ascii = False, indent = 2)
            print(f"\n✓ Final results saved: {final_results_path}")

        print("\n" + "="*60)
        print("PIPELINE COMPLETE!")
        print("="*60)
        print(f"Output directory: {lecture_output_dir}")
        print(f"Reconstructed audio: {output_audio_path}")

        return results


def simple_sentence_splitter(text: str) -> List[str]:
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
    # Example usage
    pipeline = LecturePipeline(
        # ASR settings
        asr_chunk_seconds = 300,
        asr_batch_size = 4,

        # Matching settings
        jump_penalty = 0.1,
        backward_weight = 2.0,

        # TTS settings
        tts_voice = 'af_heart',
        tts_speed = 1.0,

        # General settings
        device = 'cuda',
        output_dir = './pipeline_output'
    )

    # Run pipeline
    results = pipeline.run(
        audio_path = 'lecture_recording.mp3',
        pdf_path = 'lecture_slides.pdf',
        lecture_name = 'my_lecture',
        sentence_splitter = simple_sentence_splitter,
        export_audio_formats = ['opus'],
        save_intermediate = True
    )

    print(f"\n✓ Pipeline completed successfully!")
    print(f"  - Transcript length: {results['asr']['length']} characters")
    print(f"  - Matched sentences: {results['matching']['num_matches']}")
    print(f"  - Audio duration: {results['tts']['metadata']['total_duration']:.2f}s")
