"""
Global CUDA Initialization Lock
Prevents concurrent CUDA model initialization across all processors to avoid PyTorch meta tensor errors.
"""

import threading

# Global lock shared by all model processors (ASR, Slide Matching, Translation, TTS)
# This ensures only one model can initialize CUDA resources at a time
# Inference operations can still run in parallel once models are loaded
_cuda_init_lock = threading.Lock()


def get_cuda_init_lock():
    """Get the global CUDA initialization lock."""
    return _cuda_init_lock
