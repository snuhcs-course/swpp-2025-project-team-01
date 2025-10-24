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
   - Install NeMo Toolkit (ASR), Kokoro TTS
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
   # uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Access the API documentation**:
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### Project Structure

```
backend/
├── setup.sh                 # Installation script
├── main.py                  # FastAPI application
├── test.py                  # API test script
├── README.md
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

**Status Values:**
- `pending` - Job created, waiting to start
- `uploading` - Files uploaded, waiting for processing
- `processing_asr` - ASR (speech-to-text) in progress (10-40%)
- `processing_matching` - Slide matching in progress (40-70%)
- `processing_translation` - English-to-Korean translation in progress (70-80%)
- `processing_tts` - TTS (text-to-speech) generation in progress (80-95%)
- `creating_output` - Creating final output ZIP file (95-100%)
- `completed` - Job completed successfully
- `failed` - Job failed with error

**Progress Range:** 0.0 to 100.0

#### Example Usage (Dart/Flutter)

```dart
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';

Future<String?> synchronizeLecture(
  File audioFile,
  File pdfFile,
  Function(double progress, String message) onProgress,
) async {
  final uri = Uri.parse('http://localhost:8000/api/synchronize/stream');

  final request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath(
    'audio',
    audioFile.path,
    contentType: MediaType('audio', 'mpeg'),
  ));
  request.files.add(await http.MultipartFile.fromPath(
    'lecture_note',
    pdfFile.path,
    contentType: MediaType('application', 'pdf'),
  ));

  final response = await request.send();

  String? jobId;
  await for (var chunk in response.stream.transform(utf8.decoder)) {
    final lines = chunk.split('\n');
    for (var line in lines) {
      if (line.startsWith('data: ')) {
        final jsonData = line.substring(6);
        final data = jsonDecode(jsonData);

        jobId = data['job_id'];
        final progress = data['progress'] as double;
        final message = data['message'] as String;

        onProgress(progress, message);

        if (data['status'] == 'completed') {
          return jobId;
        } else if (data['status'] == 'failed') {
          throw Exception('Job failed: ${data['error']}');
        }
      }
    }
  }

  return jobId;
}
```

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

#### Example Usage (Dart/Flutter)

```dart
Future<Map<String, dynamic>> checkJobStatus(String jobId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/synchronize/status/$jobId'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 404) {
    throw Exception('Job not found');
  } else {
    throw Exception('Failed to check status: ${response.statusCode}');
  }
}
```

---

### 3. Download Result

**`GET /api/synchronize/download/{job_id}`**

Download the result ZIP file for a completed synchronization job.

#### Request

- **Path Parameter**: `job_id` (string) - Unique job identifier

#### Response

- **Content-Type**: `application/zip`
- **File Name**: `lecture_output.zip`

**ZIP Contents:**
- `audio.opus` - Reconstructed audio file in Opus format
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

#### Example Usage (Dart/Flutter)

```dart
Future<void> downloadResult(String jobId, String savePath) async {
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/synchronize/download/$jobId'),
  );

  if (response.statusCode == 200) {
    final file = File(savePath);
    await file.writeAsBytes(response.bodyBytes);
    print('Downloaded to: $savePath');
  } else if (response.statusCode == 404) {
    throw Exception('Job not found');
  } else if (response.statusCode == 400) {
    final error = jsonDecode(response.body);
    throw Exception('Cannot download: ${error['detail']}');
  } else {
    throw Exception('Download failed: ${response.statusCode}');
  }
}
```

---

## Output Format

### timestamps.json Structure

The `timestamps.json` file in the downloaded ZIP contains:

```json
{
  "metadata": {
    "total_sentences": 42,
    "total_duration": 125300,
    "voice": "af_heart",
    "speed": 1.0,
    "language_code": "a",
    "sample_rate": 24000
  },
  "timestamps": [
    {
      "sentence_id": 1,
      "text": "Welcome to this lecture on deep learning.",
      "text_kor": "딥러닝에 관한 이 강의에 오신 것을 환영합니다.",
      "slide_number": 1,
      "start_time": 0,
      "end_time": 3200,
      "duration": 3200
    },
    {
      "sentence_id": 2,
      "text": "Today we will discuss neural networks.",
      "text_kor": "오늘 우리는 신경망에 대해 논의할 것입니다.",
      "slide_number": 1,
      "start_time": 3400,
      "end_time": 6800,
      "duration": 3400
    }
  ]
}
```

**Field Descriptions:**

- `metadata`: Audio generation metadata
  - `total_sentences`: Number of sentences in the lecture
  - `total_duration`: Total audio duration in milliseconds (integer)
  - `voice`: TTS voice used
  - `speed`: Playback speed multiplier
  - `language_code`: Language code (`a` = American English)
  - `sample_rate`: Audio sample rate (24000 Hz)

- `timestamps`: Array of sentence timing information
  - `sentence_id`: Unique sentence identifier (1-indexed)
  - `text`: Sentence text content (English)
  - `text_kor`: Korean translation of the sentence (added by translation processor)
  - `slide_number`: Corresponding slide page number (1-indexed)
  - `start_time`: Sentence start time in milliseconds (integer)
  - `end_time`: Sentence end time in milliseconds (integer)
  - `duration`: Sentence duration in milliseconds (integer)

---

## Complete Usage Flow (Dart/Flutter)

```dart
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';

class LectureSyncService {
  final String baseUrl;

  LectureSyncService(this.baseUrl);

  /// Start synchronization and track progress via SSE
  Future<String?> startSync(
    File audioFile,
    File pdfFile,
    Function(double progress, String message) onProgress,
  ) async {
    final uri = Uri.parse('$baseUrl/api/synchronize/stream');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath(
      'audio',
      audioFile.path,
      contentType: MediaType('audio', 'mpeg'),
    ));
    request.files.add(await http.MultipartFile.fromPath(
      'lecture_note',
      pdfFile.path,
      contentType: MediaType('application', 'pdf'),
    ));

    final response = await request.send();

    String? jobId;
    await for (var chunk in response.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (var line in lines) {
        if (line.startsWith('data: ')) {
          final jsonData = line.substring(6);
          final data = jsonDecode(jsonData);

          jobId = data['job_id'];
          onProgress(data['progress'].toDouble(), data['message']);

          if (data['status'] == 'completed') {
            return jobId;
          } else if (data['status'] == 'failed') {
            throw Exception('Job failed: ${data['error']}');
          }
        }
      }
    }

    return jobId;
  }

  /// Check job status (alternative to SSE if needed)
  Future<Map<String, dynamic>> checkStatus(String jobId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/synchronize/status/$jobId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check status: ${response.statusCode}');
    }
  }

  /// Download result ZIP file
  Future<File> downloadResult(String jobId, String savePath) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/synchronize/download/$jobId'),
    );

    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Download failed: ${response.statusCode}');
    }
  }
}

// Usage example
void main() async {
  final service = LectureSyncService('http://localhost:8000');

  try {
    // Start sync with progress tracking
    final jobId = await service.startSync(
      File('lecture.mp3'),
      File('slides.pdf'),
      (progress, message) {
        print('Progress: ${progress.toStringAsFixed(1)}% - $message');
      },
    );

    if (jobId != null) {
      // Download result
      final zipFile = await service.downloadResult(
        jobId,
        'lecture_output.zip',
      );
      print('Downloaded: ${zipFile.path}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Architecture Notes

### Concurrency Model

- **GPU Resource Management**: Only one inference job runs at a time (enforced by semaphore)
- **Multiple Requests**: Additional requests are queued automatically
- **Background Processing**: Jobs run in background tasks
- **Progress Streaming**: Real-time updates via SSE

### File Cleanup

Automatic file management:
1. **Uploaded files**: Deleted after pipeline processing
2. **Output ZIP files**: Deleted immediately after download OR after 30 minutes if not downloaded
3. **Job metadata**: Removed after file download or timeout

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
   - Update file paths in [test.py](test.py) if needed

### Method 1: Python Test Script (Recommended)

The easiest way to test all endpoints including SSE streaming:

```bash
cd backend
python test.py
```

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
