"""
Inference Models Package
Contains ASR, Slide Matching, and TTS processors for lecture reconstruction.
"""

from .lecture_pipeline import LecturePipeline, PipelineOutput, simple_sentence_splitter
from .asr_processor import ASRProcessor
from .slide_matching_processor import SlideMatchingProcessor
from .tts_processor import TTSProcessor

__all__ = [
    'LecturePipeline',
    'PipelineOutput',
    'simple_sentence_splitter',
    'ASRProcessor',
    'SlideMatchingProcessor',
    'TTSProcessor',
]
