# Lecture Reconstruction Pipeline

An integrated AI pipeline that reconstructs lectures from audio recordings and PDF slides, combining automatic speech recognition (ASR), intelligent slide matching, and text-to-speech (TTS) synthesis.

## Features

- **Automatic Speech Recognition**: Transcribe lecture audio using NVIDIA Parakeet TDT 0.6B model
- **Intelligent Slide Matching**: Align transcript to PDF slides using multimodal vision-text embeddings
- **Text-to-Speech Synthesis**: Generate reconstructed audio with precise slide timing using Kokoro TTS
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
- Transformers, NeMo Toolkit (ASR)
- Kokoro TTS
- Flash Attention 2 (optional, GPU required)

## Quick Start

```python
from lecture_pipeline import LecturePipeline

# Initialize pipeline
pipeline = LecturePipeline(device='cuda', output_dir='./output')

# Process lecture
results = pipeline.run(
    audio_path='lecture_recording.mp3',
    pdf_path='lecture_slides.pdf',
    lecture_name='my_lecture'
)
```

**Output files** (in `./output/my_lecture/`):
- `transcript.txt` - Full transcription
- `matching.json` - Slide alignment data
- `reconstructed.wav` - Reconstructed audio
- `timestamps.json` - Timing metadata with slide numbers
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
    jump_penalty=0.1,         # Penalty for slide jumps (default: 0.1)
    backward_weight=2.0,      # Extra penalty for backward jumps (default: 2.0)
    use_exponential_scaling=False,  # Apply exponential scaling to scores
    exponential_scale=3.0,    # Exponential scale factor
    use_confidence_boost=False,  # Boost scores when confidence is low
    confidence_threshold=0.95,  # Confidence threshold
    confidence_weight=1.5,    # Confidence boost weight

    # TTS settings
    tts_voice='af_heart',     # Voice style (af_heart, af_bella, af_sarah, am_adam, am_michael)
    tts_speed=1.0,           # Playback speed
    tts_silence_duration=0.2,  # Silence between sentences (seconds)

    # General
    device='cuda',
    output_dir='./pipeline_output'
)

# Run complete pipeline
results = pipeline.run(
    audio_path='lecture_recording.mp3',
    pdf_path='lecture_slides.pdf',
    lecture_name='my_lecture',
    sentence_splitter=simple_sentence_splitter,  # Split transcript into sentences (or None for full transcript)
    export_audio_formats=['opus'],  # Additional export formats
    save_intermediate=True                 # Save intermediate results
)
```

### Using Individual Processors

Each processing stage can be used independently:

#### ASR Only

```python
from asr_processor import ASRProcessor

asr = ASRProcessor(device='cuda')
asr.load_model()

result = asr.transcribe(
    audio_path='lecture_recording.mp3',
    chunk_seconds=300,    # Auto-split long files (default: 300)
    batch_size=4,         # Batch processing for memory efficiency (default: 4)
    output_path='transcript.txt'
)

print(result['transcript'])
asr.unload_model()
```

#### Slide Matching Only

```python
from slide_matching_processor import SlideMatchingProcessor

matcher = SlideMatchingProcessor(
    device='cuda',
    batch_size=4,          # Batch size for embedding computation (default: 4)
    jump_penalty=0.1,      # Default: 0.1
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

The system consists of three independent processors orchestrated by `LecturePipeline`:

### 1. ASR Stage (Speech → Text)
- **Model**: NVIDIA Parakeet TDT 0.6B via NeMo Toolkit
- **Features**:
  - Automatic audio chunking for long files (>5 minutes)
  - Batch processing to optimize GPU memory
- **Output**: Full transcript text

### 2. Slide Matching Stage (Text → Slides)
- **Model**: NVIDIA NeMo Retriever ColEmbedder (3B multimodal)
- **Features**:
  - Vision-text embedding alignment
  - Dynamic programming for temporal coherence
  - Configurable jump penalties (forward/backward)
  - Optional exponential scaling and confidence boosting
- **Output**: Sentence-to-slide alignment with confidence scores

### 3. TTS Stage (Text + Slides → Audio)
- **Model**: Kokoro TTS pipeline
- **Features**:
  - Natural voice synthesis with multiple voice options
  - Precise timing generation for each sentence
  - Automatic silence insertion between sentences
  - Multi-format export (WAV, Opus, AAC)
- **Output**: Reconstructed audio with timestamp metadata

### Memory Management

The pipeline uses aggressive memory management to handle large models on limited GPU memory:

```python
# Each processor supports load/unload
processor.load_model()    # Load model into GPU memory
# ... do work ...
processor.unload_model()  # Free GPU memory
```

The `LecturePipeline` automatically unloads models between stages to prevent VRAM overflow.

## Configuration Options

### ASR Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `asr_model` | `nvidia/parakeet-tdt-0.6b-v2` | ASR model name |
| `asr_chunk_seconds` | `300` | Chunk duration for long audio (seconds) |
| `asr_batch_size` | `4` | Batch size (adjust based on VRAM) |

### Slide Matching Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `matching_model` | `nvidia/llama-nemoretriever-colembed-3b-v1` | Multimodal model name |
| `matching_batch_size` | `4` | Batch size for embedding computation |
| `jump_penalty` | `0.1` | Penalty for slide jumps |
| `backward_weight` | `2.0` | Multiplier for backward jump penalty |
| `use_exponential_scaling` | `False` | Apply exponential scaling to scores |
| `exponential_scale` | `3.0` | Exponential scale factor |
| `use_confidence_boost` | `False` | Boost scores when confidence is low |
| `confidence_threshold` | `0.95` | Threshold for confidence boosting |
| `confidence_weight` | `1.5` | Weight multiplier for confidence boost |

### TTS Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `tts_voice` | `af_heart` | Voice style |
| `tts_speed` | `1.0` | Playback speed multiplier |
| `tts_lang_code` | `a` | Language code ('a' = American English) |
| `tts_silence_duration` | `0.2` | Silence between sentences (seconds) |

**Available TTS voices**: `af_heart`, `af_bella`, `af_sarah`, `am_adam`, `am_michael`

## Output Formats

### Transcript File (`.txt`)
Plain text transcription of the lecture audio.

### Matching Results (`.json`)
```json
{
  "lecture_name": "my_lecture",
  "total_sentences": 150,
  "results": [
    {
      "sentence_id": 1,
      "text": "Welcome to the lecture.",
      "matched_slide": 1,
      "confidence_score": 0.95
    },
    ...
  ]
}
```

### Timestamps File (`.json`)
```json
{
  "metadata": {
    "total_sentences": 150,
    "total_duration": 3600.5,
    "voice": "af_heart",
    "speed": 1.0
  },
  "timestamps": [
    {
      "sentence_id": 1,
      "text": "Welcome to the lecture.",
      "slide_number": 1,
      "start_time": 0.0,
      "end_time": 2.5,
      "duration": 2.5
    },
    ...
  ]
}
```

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
    jump_penalty=0.2,           # Increase to discourage jumps
    backward_weight=3.0,        # Increase to heavily penalize backward jumps
    use_exponential_scaling=True,
    exponential_scale=3.0       # Amplify score differences
)
```
