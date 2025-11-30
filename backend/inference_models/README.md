# Lecture Reconstruction Pipeline

An integrated AI pipeline that reconstructs lectures from audio recordings and PDF slides, combining automatic speech recognition (ASR), intelligent slide matching, and text-to-speech (TTS) synthesis.

## Features

- **Automatic Speech Recognition**: Transcribe lecture audio with language-optimized models
  - English: NVIDIA Parakeet TDT 0.6B v2 (higher accuracy)
  - Korean: OpenAI Whisper Turbo (multilingual support)
  - Segment-level timestamps with punctuation-based splitting
- **Intelligent Slide Matching**: Align transcript to PDF slides using multimodal vision-text embeddings
- **Bidirectional Translation**: Translate transcripts (English↔Korean) using Tencent Hunyuan-MT-7B with vLLM
- **Text-to-Speech Synthesis**: Generate reconstructed audio with precise slide timing using Kokoro TTS (English lectures only)
- **Original Audio Timestamps**: Preserve timing information from original lecture audio for each sentence
- **Memory-Efficient Design**: Automatic model loading/unloading between stages for optimal GPU usage
- **Flexible Architecture**: Use the complete pipeline or individual processors independently

## Installation

### Prerequisites

- NVIDIA GPU with CUDA support (recommended)
- Conda package manager
- ffmpeg (for audio format conversion)

```bash
# Install ffmpeg
sudo apt install ffmpeg  # Linux
brew install ffmpeg      # macOS
```

### Setup

```bash
# Clone the repository
git clone https://github.com/snuhcs-course/swpp-2025-project-team-01.git
cd inference_models

# Create conda environment (takes 10-15 minutes)
./setup.sh              # Creates environment named 'swpp-ai'
./setup.sh -n myenv     # Or create with custom name

# Activate environment
conda activate swpp-ai
```

The setup script installs:
- PyTorch 2.8.0 with CUDA 12.9
- NVIDIA NeMo toolkit with ASR support (for Parakeet)
- OpenAI Whisper (multilingual ASR)
- vLLM 0.10.2 (for translation inference)
- Kokoro TTS
- Flash Attention 2 (optional, GPU required)

## Quick Start

```python
from lecture_pipeline import LecturePipeline

# Initialize pipeline
pipeline = LecturePipeline(device='cuda', output_dir='./output')

# Process English lecture
results = pipeline.run(
    audio_path='lecture_recording.mp3',
    pdf_path='lecture_slides.pdf',
    language='en',  # 'en' for English, 'ko' for Korean
    lecture_name='my_lecture'
)
```

**Output files** (in `./output/my_lecture/`):
- `reconstructed.opus` - Reconstructed audio (compressed, default format)
- `timestamps.json` - Timing metadata with slide numbers

**Intermediate files** (saved when `save_intermediate=True`):
- `transcript.txt` - Full transcription
- `matching.json` - Slide alignment data
- `reconstructed.wav` - Uncompressed audio
- `pipeline_results.json` - Complete pipeline results

## Usage

### Integrated Pipeline (Recommended)

The `LecturePipeline` class provides end-to-end lecture reconstruction:

```python
from lecture_pipeline import LecturePipeline, simple_sentence_splitter

pipeline = LecturePipeline(
    # ASR settings
    asr_chunk_seconds=300,    # Split long audio into 5-min chunks
    asr_batch_size=4,         # Batch size for ASR processing

    # Matching settings
    jump_penalty=0.2,         # Penalty for slide jumps (default: 0.2)
    backward_weight=2.0,      # Extra penalty for backward jumps (default: 2.0)
    use_exponential_scaling=True,  # Apply exponential scaling to scores (default: True)
    exponential_scale=2.8,    # Exponential scale factor (default: 2.8)
    use_confidence_boost=True,  # Boost scores when confidence is low (default: True)
    confidence_threshold=0.925,  # Confidence threshold (default: 0.925)
    confidence_weight=2.25,    # Confidence boost weight (default: 2.25)
    use_context_similarity=True,  # Enable context-aware scoring via EMA (default: True)
    context_weight=0.05,      # Weight for context similarity contribution (default: 0.05)
    context_update_rate=0.25,  # Update rate for EMA (default: 0.25)

    # Translation settings
    translation_model='tencent/Hunyuan-MT-7B',  # Translation model name
    translation_tensor_parallel_size=1,  # Number of GPUs for tensor parallelism
    enable_translation=True,  # Enable translation (default: True)

    # TTS settings
    enable_tts=True,          # Enable TTS generation (default: True, only for English lectures)
    tts_voice='af_heart',     # Voice style (af_heart, af_bella, af_sarah, am_adam, am_michael)
    tts_speed=1.0,           # Playback speed
    tts_silence_duration=0.2,  # Silence between sentences (seconds)

    # General
    device='cuda',
    output_dir='./pipeline_output'
)

# Run complete pipeline for English lecture
results = pipeline.run(
    audio_path='lecture_recording.mp3',
    pdf_path='lecture_slides.pdf',
    language='en',            # 'en' for English, 'ko' for Korean
    lecture_name='my_lecture',
    sentence_splitter=simple_sentence_splitter,  # Split transcript into sentences (or None for full transcript)
    save_intermediate=True,                # Save intermediate results
    progress_callback=None,                # Optional: callback for progress updates
    cancellation_checker=None              # Optional: callback to check for cancellation requests
)
```

### Using Individual Processors

Each processing stage can be used independently:

#### ASR Only

**Recommended: Use language-specific factory method**
```python
from asr_processor import ASRProcessor

# Automatically selects optimal model for language
asr = ASRProcessor.create_for_language('en', device='cuda')  # Parakeet for English
# OR
asr = ASRProcessor.create_for_language('ko', device='cuda')  # Whisper for Korean

asr.load_model()

# Transcribe lecture
result = asr.transcribe(
    audio_path='lecture_recording.mp3',
    language='en',        # 'en' for English, 'ko' for Korean
    chunk_seconds=300,    # Auto-split long files (default: 300)
    batch_size=4,         # Batch processing (Whisper only, default: 4)
    output_path='transcript.txt'
)

print(result['transcript'])
asr.unload_model()
```

**Advanced: Manual model selection**
```python
# Explicitly specify model type
asr_parakeet = ASRProcessor(
    model_name='nvidia/parakeet-tdt-0.6b-v2',
    model_type='parakeet',
    device='cuda'
)

asr_whisper = ASRProcessor(
    model_name='turbo',
    model_type='whisper',
    device='cuda'
)
```

#### Slide Matching Only

```python
from slide_matching_processor import SlideMatchingProcessor

matcher = SlideMatchingProcessor(
    device='cuda',
    batch_size=4,          # Batch size for embedding computation (default: 4)
    jump_penalty=0.2,      # Default: 0.2
    backward_weight=2.0    # Default: 2.0
)
matcher.load_model()

# With sentence list
matches = matcher.match_transcript_to_slides(
    transcript='Full lecture transcript...',
    pdf_path='lecture_slides.pdf',
    sentences=['First sentence.', 'Second sentence.', ...]
)

matcher.unload_model()
```

#### Translation Only

```python
from translation_processor import TranslationProcessor

translator = TranslationProcessor(
    model_name='tencent/Hunyuan-MT-7B',
    device='cuda',
    tensor_parallel_size=1,
    max_model_len=2048,
    gpu_memory_utilization=0.35
)
translator.load_model()

# Example 1: Translate English to Korean
matching_results_en = [
    {
        'text': 'Welcome to the lecture.',
        'matched_page': 1,
        'confidence_score': 0.95
    },
    {
        'text': 'Today we discuss AI.',
        'matched_page': 2,
        'confidence_score': 0.92
    }
]

translated_results_en = translator.translate_matching_results(
    matching_results=matching_results_en,
    source_lang='en',
    target_lang='ko'
)

# Original 'text' field is removed and reorganized into text_eng/text_kor
for result in translated_results_en:
    print(f"EN: {result['text_eng']}")  # Original English text
    print(f"KO: {result['text_kor']}")  # Korean translation

# Example 2: Translate Korean to English
matching_results_ko = [
    {
        'text': '강의에 오신 것을 환영합니다.',
        'matched_page': 1,
        'confidence_score': 0.95
    }
]

translated_results_ko = translator.translate_matching_results(
    matching_results=matching_results_ko,
    source_lang='ko',
    target_lang='en'
)

# Original 'text' field is removed and reorganized into text_eng/text_kor
for result in translated_results_ko:
    print(f"KO: {result['text_kor']}")  # Original Korean text
    print(f"EN: {result['text_eng']}")  # English translation

translator.unload_model()
```

#### TTS Only

```python
from tts_processor import TTSProcessor

tts = TTSProcessor(
    voice='af_heart',           # Default: 'af_heart'
    speed=1.0,                  # Default: 1.0
    lang_code='a',              # Default: 'a' (American English)
    silence_duration=0.2        # Default: 0.2 seconds
)
tts.load_model()

# Generate audio from sentences with slide numbers
sentences = [
    {'text': 'Welcome to the lecture.', 'slide_number': 1},
    {'text': 'Today we discuss AI.', 'slide_number': 2},
    # ...
]

result = tts.generate_audio(
    sentences=sentences,
    output_audio_path='output.wav',
    output_json_path='timestamps.json',
    export_formats=['opus', 'aac']
)

tts.unload_model()
```

## Pipeline Architecture

The system consists of four independent processors orchestrated by `LecturePipeline`:

### 1. ASR Stage (Speech → Text)
- **Models**:
  - English: NVIDIA Parakeet TDT 0.6B v2 via NeMo (higher accuracy for English)
  - Korean: OpenAI Whisper Turbo (multilingual support)
  - Automatic language-based model selection
- **Features**:
  - Supports English and Korean transcription
  - Automatic audio chunking for long files (>5 minutes)
  - Model-specific unified locks (RLock) prevent duplicate model loading on GPU
  - Independent locks per model enable parallel English/Korean processing
  - Segment-level timestamp extraction (punctuation-based split)
  - Special handling for Korean sentence endings (니다, 요)
- **Output**: Full transcript text + segment timestamps with original audio timing

### 2. Slide Matching Stage (Text → Slides)
- **Model**: NVIDIA NeMo Retriever ColEmbedder (3B multimodal)
- **Features**:
  - Uses ASR segments directly as sentences (punctuation-based split)
  - Vision-text embedding alignment
  - Dynamic programming for temporal coherence
  - Configurable jump penalties (forward/backward)
  - Optional exponential scaling and confidence boosting
- **Output**: Sentence-to-slide alignment with confidence scores + original audio timestamps

### 3. Translation Stage (Bidirectional: English ↔ Korean)
- **Model**: Tencent Hunyuan-MT-7B via vLLM
- **Features**:
  - Bidirectional translation support (English↔Korean)
  - Fast parallel translation inference using vLLM
  - Batch processing for efficiency
  - Configurable GPU memory utilization
  - Optional: can be disabled via `enable_translation=False`
  - Translation direction determined per request based on lecture language
  - Automatic field reorganization: removes `text` field and creates `text_eng`/`text_kor` fields
- **Output**: Matching results with bilingual text fields
  - English lectures: `text` → `text_eng` (original), translation → `text_kor`
  - Korean lectures: `text` → `text_kor` (original), translation → `text_eng`

### 4. TTS Stage (Text + Slides → Audio)
- **Model**: Kokoro TTS pipeline
- **Features**:
  - Natural voice synthesis with multiple voice options
  - Precise timing generation for each sentence
  - Automatic silence insertion between sentences
  - Multi-format export (WAV, Opus, AAC)
  - **Only runs for English lectures** (Korean lectures use original audio)
- **Output**: Reconstructed audio with timestamp metadata (English lectures only)

### Memory Management

The pipeline uses aggressive memory management to handle large models on limited GPU memory:

```python
# Each processor supports load/unload
processor.load_model()    # Load model into GPU memory
# ... do work ...
processor.unload_model()  # Free GPU memory
```

The `LecturePipeline` automatically unloads models between stages to prevent VRAM overflow.

### Cancellation Support

The pipeline supports graceful cancellation at stage boundaries:

```python
import asyncio

# Define a cancellation checker
cancel_requested = False

def check_cancellation():
    if cancel_requested:
        raise asyncio.CancelledError("Job cancelled by user")

# Run pipeline with cancellation support
try:
    results = pipeline.run(
        audio_path='lecture.mp3',
        pdf_path='slides.pdf',
        language='en',
        cancellation_checker=check_cancellation
    )
except asyncio.CancelledError:
    print("Pipeline was cancelled")
    # Clean up resources
```

**Cancellation Checkpoints:**
- Before ASR starts
- After ASR completes, before Slide Matching
- After Slide Matching completes, before Translation
- After Translation completes, before TTS

**Important Notes:**
- Cancellation occurs at stage boundaries only
- Cannot interrupt GPU inference mid-stage
- Already completed stages are not rolled back
- Resources are automatically cleaned up on cancellation

This feature is primarily used by the FastAPI backend to support user-initiated job cancellation via the `/api/synchronize/cancel/{job_id}` endpoint.

## Configuration Options

### ASR Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `asr_model` | `turbo` | ASR model name (not used when ASR auto-selects by language) |
| `asr_chunk_seconds` | `300` | Chunk duration for long audio (seconds) |
| `asr_batch_size` | `4` | Batch size for Whisper (Parakeet processes sequentially) |

**Important Notes**:
- The `language` parameter is passed per request to `pipeline.run()` or `asr.transcribe()`, not during initialization
- **LecturePipeline automatically selects the optimal ASR model** based on language:
  - English (`en`) → NVIDIA Parakeet TDT 0.6B v2 (higher accuracy)
  - Korean (`ko`) → OpenAI Whisper Turbo (multilingual support)
- The `asr_model` parameter in LecturePipeline is ignored when using automatic language-based model selection
- For manual ASR processor usage, use `ASRProcessor.create_for_language('en'|'ko')` for automatic model selection, or specify `model_name` and `model_type` explicitly

### Slide Matching Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `matching_model` | `nvidia/llama-nemoretriever-colembed-3b-v1` | Multimodal model name |
| `matching_batch_size` | `4` | Batch size for embedding computation |
| `jump_penalty` | `0.2` | Penalty for slide jumps |
| `backward_weight` | `2.0` | Multiplier for backward jump penalty |
| `use_exponential_scaling` | `True` | Apply exponential scaling to scores |
| `exponential_scale` | `2.8` | Exponential scale factor |
| `use_confidence_boost` | `True` | Boost scores when confidence is low |
| `confidence_threshold` | `0.925` | Threshold for confidence boosting |
| `confidence_weight` | `2.25` | Weight multiplier for confidence boost |
| `use_context_similarity` | `True` | Enable context-aware scoring via EMA |
| `context_weight` | `0.05` | Weight for context similarity contribution |
| `context_update_rate` | `0.25` | Update rate for EMA |

### Translation Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `translation_model` | `tencent/Hunyuan-MT-7B` | Translation model name |
| `translation_tensor_parallel_size` | `1` | Number of GPUs for tensor parallelism |
| `enable_translation` | `True` | Enable translation (direction determined per request) |

### TTS Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enable_tts` | `True` | Enable TTS generation (only for English lectures) |
| `tts_voice` | `af_heart` | Voice style |
| `tts_speed` | `1.0` | Playback speed multiplier |
| `tts_lang_code` | `a` | Language code ('a' = American English) |
| `tts_silence_duration` | `0.2` | Silence between sentences (seconds) |

**Available TTS voices**: `af_heart`, `af_bella`, `af_sarah`, `am_adam`, `am_michael`

**Note**: TTS is only used for English lectures. Korean lectures skip TTS and use original audio timestamps.

## Output Formats

### Transcript File (`.txt`)
Plain text transcription of the lecture audio.

### Matching Results (`.json`)

**After Translation (Both English and Korean Lectures):**
```json
[
  {
    "text_eng": "Welcome to the lecture.",
    "text_kor": "강의에 오신 것을 환영합니다.",
    "matched_page": 1,
    "confidence_score": 0.95,
    "original_start_time": 0.12,
    "original_end_time": 3.45
  },
  {
    "text_eng": "Today we discuss AI.",
    "text_kor": "오늘 우리는 AI에 대해 논의합니다.",
    "matched_page": 2,
    "confidence_score": 0.92,
    "original_start_time": 3.68,
    "original_end_time": 6.92
  }
]
```

**Notes:**
- For **English lectures**: `text_eng` is the original ASR output, `text_kor` is the Korean translation
- For **Korean lectures**: `text_kor` is the original ASR output, `text_eng` is the English translation
- The original `text` field is removed by the translation processor and reorganized into `text_eng`/`text_kor` fields
- `original_start_time` and `original_end_time` are in seconds (float), extracted from ASR segment timestamps

### Timestamps File (`.json`)

**For English Lectures:**
```json
[
  {
    "text_eng": "Welcome to the lecture.",
    "text_kor": "강의에 오신 것을 환영합니다.",
    "slide_number": 1,
    "tts_start_time": 0,
    "tts_end_time": 2500,
    "original_start_time": 120,
    "original_end_time": 3450
  },
  ...
]
```

**For Korean Lectures:**
```json
[
  {
    "text_eng": "Welcome to the lecture.",
    "text_kor": "강의에 오신 것을 환영합니다.",
    "slide_number": 1,
    "tts_start_time": 0,
    "tts_end_time": 0,
    "original_start_time": 120,
    "original_end_time": 3450
  },
  ...
]
```

**Notes:**
- For **English lectures**: `text_eng` is the original ASR output, `text_kor` is the Korean translation
- For **Korean lectures**: `text_kor` is the original ASR output, `text_eng` is the English translation
- `tts_start_time` and `tts_end_time` are timestamps for **reconstructed TTS audio** in milliseconds (0 for Korean lectures)
- `original_start_time` and `original_end_time` are timestamps from the **original lecture audio** in milliseconds

### Audio Files
- **WAV** (`.wav`): Uncompressed audio, 24kHz sample rate
- **Opus** (`.opus`): High-quality compressed audio (requires ffmpeg)
- **AAC** (`.m4a`): Compressed audio for compatibility (requires ffmpeg)

## Performance Tips

### GPU Memory Optimization

```python
# Reduce batch sizes if running out of memory
pipeline = LecturePipeline(
    asr_batch_size=2,      # Reduce from default 4
    matching_batch_size=2  # Reduce from default 4
)

# Or use individual processors and manually manage memory
asr = ASRProcessor()
asr.load_model()
result = asr.transcribe('audio.mp3')
asr.unload_model()  # Free memory before next stage
```

### Processing Long Audio Files

```python
# ASR automatically chunks long files
pipeline = LecturePipeline(
    asr_chunk_seconds=180,  # Use 3-minute chunks for very long files
    asr_batch_size=2        # Process fewer chunks at once
)
```

### Slide Matching Accuracy

```python
# Adjust penalties for better temporal coherence
pipeline = LecturePipeline(
    jump_penalty=0.3,           # Increase from default 0.2 to discourage jumps
    backward_weight=3.0,        # Increase from default 2.0 to heavily penalize backward jumps
    exponential_scale=3.0,      # Increase from default 2.8 to amplify score differences
    context_weight=0.1          # Increase from default 0.05 for stronger context influence
)
```

### Translation Memory Optimization

```python
# Reduce GPU memory usage for translation
pipeline = LecturePipeline(
    translation_tensor_parallel_size=1,  # Use 1 GPU (default)
    enable_translation=True              # Enable translation
)

# Or disable translation if not needed
pipeline = LecturePipeline(
    enable_translation=False  # Skip translation stage entirely
)
```
