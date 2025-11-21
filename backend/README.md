# Re:View Backend API Documentation

Backend API for lecture synchronization using AI inference pipeline.

## Setup

### Prerequisites

- [Anaconda](https://www.anaconda.com/download) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html)
- NVIDIA GPU with CUDA support (recommended)
- 16GB+ RAM
- 10GB+ disk space

### Installation

1. **Run the setup script**:
   ```bash
   cd backend
   ./setup.sh
   # Or with custom environment name:
   # ./setup.sh -n my-env-name
   ```

   This will:
   - Create a conda environment named `swpp-backend` (or your custom name)
   - Install Python 3.12, PyTorch with CUDA 12.9
   - Install Whisper (ASR), Kokoro TTS
   - Install vLLM for translation inference
   - Install transformers and ML libraries
   - Install FastAPI and backend dependencies
   - Install flash-attn (optional, GPU-only)

2. **Activate the environment**:
   ```bash
   conda activate swpp-backend
   ```

3. **Start the server**:
   ```bash
   python main.py
   # Or with uvicorn directly:
   # uvicorn main:app --reload --host 0.0.0.0 --port 8080
   ```

4. **Access the API documentation**:
   - Swagger UI: http://localhost:8080/docs
   - ReDoc: http://localhost:8080/redoc

### Project Structure

```
backend/
├── setup.sh                 # Installation script
├── main.py                  # FastAPI application
├── README.md
├── test/                    # Test files directory
│   ├── test.py              # English lecture test (female voice)
│   ├── test_korean.py       # Korean lecture test
│   ├── test_male_voice.py   # English lecture test (male voice)
│   ├── test_lecture/        # Test input files
│   └── test_output/         # Test output files (auto-generated)
└── inference_models/        # AI inference pipeline package
    ├── __init__.py
    ├── lecture_pipeline.py  # Main pipeline orchestration
    ├── asr_processor.py     # Speech-to-text (ASR)
    ├── slide_matching_processor.py  # Slide matching
    ├── translation_processor.py  # English-to-Korean translation
    ├── tts_processor.py     # Text-to-speech (TTS)
    └── README.md
```

---

## API Endpoints

### 1. Start Synchronization Job (SSE Stream)

**`POST /api/synchronize/stream`**

Start a lecture synchronization job and receive real-time progress updates via Server-Sent Events (SSE).

#### Request

- **Content-Type**: `multipart/form-data`
- **Body Parameters**:
  - `audio` (file, required): Lecture audio file (mp3, wav, etc.)
  - `lecture_note` (file, required): Lecture slides PDF file
  - `lang` (string, optional): Lecture language code (`en` for English, `ko` for Korean). Default: `en`
  - `tts_gender` (string, optional): TTS voice gender for English lectures (`m` for male/am_michael, `f` for female/af_heart). Default: `f`. Note: This parameter only affects English lectures as Korean lectures do not generate TTS audio.

#### Response

Server-Sent Events (SSE) stream with JSON data.

**Event Types:**

1. **`progress`** - Periodic progress updates
   ```json
   {
     "job_id": "550e8400-e29b-41d4-a716-446655440000",
     "status": "processing_asr",
     "progress": 25.5,
     "message": "ASR: Transcribing audio..."
   }
   ```

2. **`complete`** - Job completed successfully
   ```json
   {
     "job_id": "550e8400-e29b-41d4-a716-446655440000",
     "status": "completed",
     "progress": 100.0,
     "message": "Processing completed successfully!"
   }
   ```

3. **`error`** - Job failed
   ```json
   {
     "job_id": "550e8400-e29b-41d4-a716-446655440000",
     "status": "failed",
     "error": "Error message here",
     "message": "Processing failed: ..."
   }
   ```

4. **`cancelled`** - Job cancelled by user
   ```json
   {
     "job_id": "550e8400-e29b-41d4-a716-446655440000",
     "status": "cancelled",
     "message": "Job cancelled by user",
     "cancelled_at": "2025-11-21T10:30:45.123456"
   }
   ```

**Status Values:**
- `pending` - Job created, waiting to start
- `uploading` - Files uploaded, waiting for processing
- `processing_asr` - ASR (speech-to-text) in progress
  - English lectures: 10-40%
  - Korean lectures: 10-50%
- `processing_matching` - Slide matching in progress
  - English lectures: 40-70%
  - Korean lectures: 50-80%
- `processing_translation` - Translation in progress (bidirectional: English↔Korean)
  - English lectures (en→ko): 70-80%
  - Korean lectures (ko→en): 80-95%
- `processing_tts` - TTS generation or timestamp creation
  - English lectures (TTS): 80-95%
  - Korean lectures (timestamps only): 95-99%
- `creating_output` - Creating final output ZIP file (95-100%)
- `completed` - Job completed successfully
- `failed` - Job failed with error
- `cancelled` - Job cancelled by user request

**Progress Range:** 0.0 to 100.0

**Note:** Progress percentages are allocated differently for English and Korean lectures to account for TTS being skipped in Korean lectures.

---

### 2. Get Job Status

**`GET /api/synchronize/status/{job_id}`**

Query the current status of a synchronization job.

#### Request

- **Path Parameter**: `job_id` (string) - Unique job identifier from the SSE stream

#### Response

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing_asr",
  "progress": 45.2,
  "message": "ASR: Processing chunk 3/10...",
  "error": null,
  "created_at": "2025-10-14T10:30:00.123456",
  "completed_at": null
}
```

#### Status Codes

- `200` - Success
- `404` - Job not found

---

### 3. Cancel Job

**`POST /api/synchronize/cancel/{job_id}`**

Cancel a running synchronization job.

#### Request

- **Path Parameter**: `job_id` (string) - Unique job identifier

#### Response

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Cancellation requested. Job will stop at next stage boundary.",
  "current_status": "processing_asr",
  "cancelled_at": "2025-11-21T10:30:45.123456"
}
```

#### Status Codes

- `200` - Cancellation request accepted
- `404` - Job not found
- `400` - Job cannot be cancelled (already completed, failed, or cancelled)

#### Important Notes

- **Stage boundary cancellation**: Jobs are cancelled at the next stage boundary (between ASR, Matching, Translation, TTS stages)
- **Cannot interrupt GPU inference**: Cancellation cannot stop a stage that's currently executing
- **Automatic cleanup**: All uploaded files and intermediate outputs are automatically cleaned up
- **SSE notification**: The SSE stream will send a `cancelled` event when cancellation completes

**Cancellation Checkpoints:**
- Before ASR starts
- After ASR completes, before Slide Matching
- After Slide Matching completes, before Translation
- After Translation completes, before TTS
- Before creating output ZIP

**Example Error Response (400):**
```json
{
  "detail": "Job cannot be cancelled. Current status: completed"
}
```

---

### 4. Download Result

**`GET /api/synchronize/download/{job_id}`**

Download the result ZIP file for a completed synchronization job.

#### Request

- **Path Parameter**: `job_id` (string) - Unique job identifier

#### Response

- **Content-Type**: `application/zip`
- **File Name**: `lecture_output.zip`

**ZIP Contents:**
- `audio.opus` - Reconstructed audio file in Opus format (English lectures only, empty for Korean lectures)
- `timestamps.json` - Timestamps with slide alignment metadata

#### Status Codes

- `200` - Success (file download)
- `404` - Job not found
- `400` - Job not completed yet or failed
- `500` - Output file not found

#### Important Notes

- **One-time download**: The file is automatically deleted after successful download
- **Retention period**: Non-downloaded files are kept for 30 minutes after completion
- After download, the job is removed from the system

---

## Output Format

### timestamps.json Structure

The `timestamps.json` file in the downloaded ZIP contains an array of timestamp entries:

**For English Lectures:**
```json
[
  {
    "text_eng": "Welcome to this lecture on deep learning.",
    "text_kor": "딥러닝에 관한 이 강의에 오신 것을 환영합니다.",
    "slide_number": 1,
    "tts_start_time": 0,
    "tts_end_time": 3200,
    "original_start_time": 120,
    "original_end_time": 4500
  },
  {
    "text_eng": "Today we will discuss neural networks.",
    "text_kor": "오늘 우리는 신경망에 대해 논의할 것입니다.",
    "slide_number": 1,
    "tts_start_time": 3400,
    "tts_end_time": 6800,
    "original_start_time": 4600,
    "original_end_time": 8200
  }
]
```

**For Korean Lectures:**
```json
[
  {
    "text_eng": "Welcome to this lecture on deep learning.",
    "text_kor": "딥러닝에 관한 이 강의에 오신 것을 환영합니다.",
    "slide_number": 1,
    "tts_start_time": 0,
    "tts_end_time": 0,
    "original_start_time": 120,
    "original_end_time": 4500
  },
  {
    "text_eng": "Today we will discuss neural networks.",
    "text_kor": "오늘 우리는 신경망에 대해 논의할 것입니다.",
    "slide_number": 1,
    "tts_start_time": 0,
    "tts_end_time": 0,
    "original_start_time": 4600,
    "original_end_time": 8200
  }
]
```

**Field Descriptions:**

- `text_eng`: English text (original for English lectures, translation for Korean lectures)
- `text_kor`: Korean text (translation for English lectures, original for Korean lectures)
- `slide_number`: Corresponding slide page number (1-indexed)
- `tts_start_time`: Sentence start time in reconstructed TTS audio in milliseconds (0 for Korean lectures)
- `tts_end_time`: Sentence end time in reconstructed TTS audio in milliseconds (0 for Korean lectures)
- `original_start_time`: Sentence start time in original lecture audio in milliseconds
- `original_end_time`: Sentence end time in original lecture audio in milliseconds

**Notes:**
- For **English lectures**: `text_eng` is the original ASR output, `text_kor` is the translation
- For **Korean lectures**: `text_kor` is the original ASR output, `text_eng` is the translation
- Korean lectures do not generate TTS audio, so `tts_start_time` and `tts_end_time` are 0
- The translation processor automatically organizes results into `text_eng` and `text_kor` fields based on the source language

---

## Architecture Notes

### Concurrency Model

- **GPU Resource Management**: Only one inference job runs at a time (enforced by semaphore)
- **Multiple Requests**: Additional requests are queued automatically
- **Background Processing**: Jobs run in background tasks
- **Progress Streaming**: Real-time updates via SSE

### Performance Optimizations

- **Image Batching**: Slide images are processed in batches (default: 4 images per batch) for faster embedding computation. Can be disabled if shared memory issues occur.
- **FP8 Quantization**: Translation model uses FP8 quantization (`tencent/Hunyuan-MT-7B-fp8`) for reduced memory footprint while maintaining translation quality.
- **Punctuation-based Segmentation**: ASR outputs are segmented by punctuation for both English and Korean, with special handling for Korean sentence endings (니다, 요).

### File Cleanup

Automatic file management:
1. **Uploaded files**: Deleted after pipeline processing (completion, failure, or cancellation)
2. **Output ZIP files**: Deleted immediately after download OR after 30 minutes if not downloaded
3. **Job metadata**: Removed after file download or timeout
4. **Cancelled jobs**: All associated files (uploaded files, intermediate outputs) are cleaned up immediately upon cancellation

### Error Handling

- `200` - Success
- `400` - Bad request (e.g., job not ready)
- `404` - Resource not found
- `500` - Internal server error

All error responses include a `detail` field with error message.

---

## Testing the API

### Prerequisites

1. **Start the server**:
   ```bash
   conda activate swpp-backend
   cd backend
   python main.py
   # Or: uvicorn main:app --reload
   ```

2. **Prepare test files**:
   - Place a lecture audio file (e.g., `lecture_recording.mp3`)
   - Place a lecture slides PDF (e.g., `lecture_slides.pdf`)
   - Update file paths in [test/test.py](test/test.py) if needed

### Method 1: Python Test Scripts (Recommended)

The easiest way to test all endpoints including SSE streaming. Four test suites are available:

**Test 1: Basic test with English lecture (female voice, default)**
```bash
cd backend
python test/test.py
```

**Test 2: Korean lecture test**
```bash
cd backend
python test/test_korean.py
```

**Test 3: English lecture with male voice**
```bash
cd backend
python test/test_male_voice.py
```

**Test 4: Job cancellation test**
```bash
cd backend
python test/test_cancellation.py
```

This test suite validates the job cancellation feature with 4 scenarios:
- Cancel job during processing (expected: successful cancellation)
- Cancel already completed job (expected: 400 error)
- Cancel non-existent job (expected: 404 error)
- Cancel job immediately after starting (expected: early cancellation)

See [test/README_CANCELLATION.md](test/README_CANCELLATION.md) for detailed documentation.

**Example output:**
```
============================================================
Re:view Backend API Test Suite
============================================================
🧪 Testing root endpoint...
✅ Root endpoint returns redirect to /docs

🧪 Testing /api/synchronize/stream endpoint...
📁 Audio: lecture_recording.mp3 (2.34 MB)
📁 PDF: lecture_slides.pdf (156.78 KB)

📤 Uploading files and starting processing...

📊 Progress updates:
------------------------------------------------------------
[  5.0%] uploading              | Files uploaded, waiting for processing...
[ 10.0%] processing_asr         | Processing ASR (chunk 1/2)...
[ 45.0%] processing_asr         | Processing ASR (chunk 2/2)...
[ 55.0%] processing_matching    | Matching slides to transcript...
[ 75.0%] processing_translation | Translating to Korean (sentence 60/120)...
[ 85.0%] processing_tts         | Generating audio (sentence 90/120)...
[ 95.0%] creating_output        | Creating download package...
------------------------------------------------------------
✅ Processing completed successfully!
🆔 Job ID: 3f8a2b1c-4d5e-6f7g-8h9i-0j1k2l3m4n5o

🧪 Testing /api/synchronize/status/3f8a2b1c-...
✅ Status endpoint working:
   Status: completed
   Progress: 100.0%

🧪 Testing /api/synchronize/download/3f8a2b1c-...
✅ Download successful: test_output.zip (1234.56 KB)
📦 ZIP contents: audio.opus, timestamps.json
✅ ZIP file structure is correct

============================================================
Test Summary
============================================================
✅ PASS  | Root endpoint
✅ PASS  | Synchronize stream
------------------------------------------------------------
Total: 2/2 tests passed

🎉 All tests passed!
```

### Method 2: cURL Examples

Test the API using cURL commands:

**English lecture with female voice (default):**
```bash
curl -X POST "http://localhost:8080/api/synchronize/stream" \
  -F "audio=@lecture_recording.mp3" \
  -F "lecture_note=@lecture_slides.pdf" \
  -F "lang=en" \
  -F "tts_gender=f"
```

**English lecture with male voice:**
```bash
curl -X POST "http://localhost:8080/api/synchronize/stream" \
  -F "audio=@lecture_recording.mp3" \
  -F "lecture_note=@lecture_slides.pdf" \
  -F "lang=en" \
  -F "tts_gender=m"
```

**Korean lecture (TTS gender parameter is ignored):**
```bash
curl -X POST "http://localhost:8080/api/synchronize/stream" \
  -F "audio=@lecture_recording.mp3" \
  -F "lecture_note=@lecture_slides.pdf" \
  -F "lang=ko"
```

---

## Common Issues

1. **SSE connection issues**
   - Fallback: Poll `/api/synchronize/status/{job_id}` periodically
   - Check network/proxy settings for SSE support

2. **Download returns 404**
   - Job may have been cleaned up (30-minute timeout)
   - File may have already been downloaded (one-time only)
   - Check status first: `/api/synchronize/status/{job_id}`

3. **Long processing times**
   - Large audio files (>1 hour) can take 10-20 minutes
   - Monitor progress via SSE or status endpoint
