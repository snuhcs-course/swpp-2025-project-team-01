from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import RedirectResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.background import BackgroundTask
from sse_starlette.sse import EventSourceResponse
from pathlib import Path
import shutil
import io
import zipfile
from datetime import datetime, timedelta
import asyncio
import aiofiles
from contextlib import asynccontextmanager
from typing import Callable
from enum import Enum
import uuid

# Import from inference_models subdirectory
from inference_models.lecture_pipeline import LecturePipeline, PipelineOutput, simple_sentence_splitter

# Job Status Enum
class JobStatus(str, Enum):
    PENDING = "pending"
    UPLOADING = "uploading"
    PROCESSING_ASR = "processing_asr"
    PROCESSING_MATCHING = "processing_matching"
    PROCESSING_TRANSLATION = "processing_translation"
    PROCESSING_TTS = "processing_tts"
    CREATING_OUTPUT = "creating_output"
    COMPLETED = "completed"
    FAILED = "failed"

# Job Information
class JobInfo:
    def __init__(self, job_id: str):
        self.job_id = job_id
        self.status = JobStatus.PENDING
        self.progress = 0.0  # 0.0 to 100.0
        self.message = ""
        self.error: str | None = None
        self.output_path: Path | None = None
        self.created_at = datetime.now()
        self.completed_at: datetime | None = None
        self.downloaded = False  # Track if file has been downloaded by client

# Global variables
pipeline: LecturePipeline | None = None
ml_inference_semaphore: asyncio.Semaphore | None = None
jobs: dict[str, JobInfo] = {}  # job_id -> JobInfo
job_cleanup_task: asyncio.Task | None = None

UPLOAD_DIR = Path('./uploads')
OUTPUT_DIR = Path('./pipeline_output')
JOB_RETENTION_MINUTES = 30  # Keep completed jobs for 30 minutes if not downloaded

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan - initialize and cleanup resources."""
    global ml_inference_semaphore, pipeline, job_cleanup_task

    UPLOAD_DIR.mkdir(exist_ok = True)
    OUTPUT_DIR.mkdir(exist_ok = True)

    ml_inference_semaphore = asyncio.Semaphore(1)

    print('🚀 Initializing ML pipeline...')
    try:
        pipeline = await asyncio.to_thread(get_pipeline)
        print('✅ ML pipeline loaded successfully')
    except Exception as e:
        print(f'⚠️  Warning: Failed to pre-load pipeline: {e}')
        print('   Pipeline will be loaded lazily on first request')

    # Start background cleanup task
    job_cleanup_task = asyncio.create_task(cleanup_old_jobs())
    print('🧹 Started job cleanup task')

    yield

    # Cancel cleanup task
    if job_cleanup_task:
        job_cleanup_task.cancel()
        try:
            await job_cleanup_task
        except asyncio.CancelledError:
            pass

    if pipeline is not None:
        print("🧹 Cleaning up ML pipeline...")
        try:
            await asyncio.to_thread(pipeline.asr.unload_model)
            await asyncio.to_thread(pipeline.matcher.unload_model)
            await asyncio.to_thread(pipeline.tts.unload_model)
            print('✅ ML pipeline cleaned up')
        except Exception as e:
            print(f'⚠️  Warning during cleanup: {e}')


app = FastAPI(
    title = 'Re:view Lecture API',
    lifespan = lifespan
)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins = ["*"],  # Configure this for production
    allow_credentials = True,
    allow_methods = ["*"],
    allow_headers = ["*"],
)

def get_pipeline() -> LecturePipeline:
    """
    Get or initialize the pipeline singleton.

    Note: This is typically called during server startup via lifespan event.
    If pipeline initialization fails during startup, it will be retried here
    on the first request (lazy loading fallback).
    """
    global pipeline
    if pipeline is None:
        print('📦 Loading ML pipeline (lazy initialization)...')
        pipeline = LecturePipeline(
            # ASR settings
            asr_chunk_seconds = 300,
            asr_batch_size = 4,

            # Matching settings
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

            # Translation settings
            translation_model = "tencent/Hunyuan-MT-7B",
            translation_tensor_parallel_size = 1,
            enable_translation = True,

            # TTS settings
            tts_voice = 'af_heart',
            tts_speed = 1.0,

            # General settings
            device = 'cuda',
            output_dir = str(OUTPUT_DIR)
        )
        print('✅ ML pipeline loaded (lazy)')
    return pipeline

async def run_pipeline_in_executor(
    audio_path: str,
    pdf_path: str,
    lecture_name: str,
    progress_callback: Callable[[JobStatus, float, str], None] | None = None
) -> PipelineOutput:
    """
    Run ML pipeline in a thread pool to avoid blocking event loop.
    This is necessary because the pipeline operations are CPU/GPU intensive.

    Args:
        audio_path: Path to audio file
        pdf_path: Path to PDF file
        lecture_name: Name for this lecture
        progress_callback: Optional callback to report progress (status, progress, message)
    """
    pipeline_instance = get_pipeline()

    # Wrapper to convert pipeline progress to job progress
    def pipeline_progress_wrapper(stage: str, progress: float, message: str):
        if progress_callback:
            # Convert stage string to JobStatus
            status_map = {
                "processing_asr": JobStatus.PROCESSING_ASR,
                "processing_matching": JobStatus.PROCESSING_MATCHING,
                "processing_translation": JobStatus.PROCESSING_TRANSLATION,
                "processing_tts": JobStatus.PROCESSING_TTS
            }
            status = status_map.get(stage, JobStatus.PROCESSING_ASR)
            progress_callback(status, progress, message)

    # Run the pipeline with progress callback
    output = await asyncio.to_thread(
        pipeline_instance.run,
        audio_path = audio_path,
        pdf_path = pdf_path,
        lecture_name = lecture_name,
        sentence_splitter = simple_sentence_splitter,
        save_intermediate = False,
        progress_callback = pipeline_progress_wrapper
    )

    return output

async def cleanup_old_jobs():
    """Background task to clean up old completed jobs (non-downloaded files after 30 minutes)."""
    global jobs
    while True:
        try:
            await asyncio.sleep(60)  # Check every 1 minute
            current_time = datetime.now()
            jobs_to_remove = []

            for job_id, job_info in jobs.items():
                if job_info.status in [JobStatus.COMPLETED, JobStatus.FAILED]:
                    if job_info.completed_at:
                        age = current_time - job_info.completed_at
                        # Clean up if not downloaded after retention period
                        if not job_info.downloaded and age > timedelta(minutes=JOB_RETENTION_MINUTES):
                            jobs_to_remove.append(job_id)
                            # Clean up output file
                            if job_info.output_path and job_info.output_path.exists():
                                await asyncio.to_thread(job_info.output_path.unlink)
                                print(f"🧹 Deleted non-downloaded file: {job_id} (age: {age.total_seconds()/60:.1f} min)")

            for job_id in jobs_to_remove:
                del jobs[job_id]
                print(f"🧹 Cleaned up old job: {job_id}")
        except Exception as e:
            print(f"⚠️  Error in cleanup task: {e}")

async def process_lecture_job(job_id: str, audio_path: Path, pdf_path: Path, lecture_name: str):
    """Background task to process a lecture synchronization job."""
    global jobs
    job_info = jobs[job_id]

    try:
        # Update job status
        job_info.status = JobStatus.UPLOADING
        job_info.progress = 5.0
        job_info.message = "Files uploaded, waiting for processing..."

        # Define progress callback
        def update_progress(status: JobStatus, progress: float, message: str):
            job_info.status = status
            job_info.progress = progress
            job_info.message = message

        # Wait for semaphore and run pipeline
        async with ml_inference_semaphore:
            job_info.message = "Starting pipeline..."
            output: PipelineOutput = await run_pipeline_in_executor(
                audio_path = str(audio_path),
                pdf_path = str(pdf_path),
                lecture_name = lecture_name,
                progress_callback = update_progress
            )

        # Verify output files exist
        audio_file_path = Path(output.audio_file)
        timestamps_file_path = Path(output.timestamps_file)

        if not audio_file_path.exists():
            raise Exception('Audio file generation failed')
        if not timestamps_file_path.exists():
            raise Exception('Timestamps file generation failed')

        # Create ZIP file
        job_info.status = JobStatus.CREATING_OUTPUT
        job_info.progress = 95.0
        job_info.message = "Creating download package..."

        zip_path = OUTPUT_DIR / f"{job_id}.zip"
        await asyncio.to_thread(
            create_zip_file_to_disk,
            str(audio_file_path),
            str(timestamps_file_path),
            str(zip_path)
        )

        # Clean up intermediate output directory
        output_dir = Path(output.output_directory)
        if output_dir.exists():
            await asyncio.to_thread(shutil.rmtree, output_dir)

        # Mark as completed
        job_info.status = JobStatus.COMPLETED
        job_info.progress = 100.0
        job_info.message = "Processing completed successfully!"
        job_info.output_path = zip_path
        job_info.completed_at = datetime.now()

    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"❌ Job {job_id} failed with error:")
        print(error_details)

        job_info.status = JobStatus.FAILED
        job_info.error = str(e)
        job_info.message = f"Processing failed: {str(e)}"
        job_info.completed_at = datetime.now()

        # Clean up on error
        try:
            output_dir = OUTPUT_DIR / lecture_name
            if output_dir.exists():
                await asyncio.to_thread(shutil.rmtree, output_dir)
                print(f"🧹 Cleaned up output directory for failed job: {job_id}")
        except Exception as cleanup_error:
            print(f"⚠️  Error during output directory cleanup: {cleanup_error}")

    finally:
        # Clean up uploaded files
        try:
            if audio_path.exists():
                await asyncio.to_thread(audio_path.unlink)
                print(f"🧹 Cleaned up uploaded audio file: {job_id}")
        except Exception as e:
            print(f"⚠️  Error deleting audio file: {e}")

        try:
            if pdf_path.exists():
                await asyncio.to_thread(pdf_path.unlink)
                print(f"🧹 Cleaned up uploaded PDF file: {job_id}")
        except Exception as e:
            print(f"⚠️  Error deleting PDF file: {e}")

@app.post('/api/synchronize/stream')
async def synchronize_stream(
    audio: UploadFile = File(..., description = 'Lecture audio file (mp3, wav, etc.)'),
    lecture_note: UploadFile = File(..., description = 'Lecture slides PDF')
):
    """
    Synchronize lecture audio with slides with real-time progress updates via SSE.

    This endpoint returns Server-Sent Events (SSE) with progress updates.
    Once completed, use the job_id to download the result via /api/synchronize/download/{job_id}

    Args:
        audio: Lecture audio file
        lecture_note: Lecture slides PDF file

    Returns:
        SSE stream with progress updates and final job_id

    SSE Event Format:
        - data: JSON object with {status, progress, message, job_id}
        - Final event includes job_id for downloading results
    """
    # Generate unique job ID and lecture name
    job_id = str(uuid.uuid4())
    lecture_name = f"lecture_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{job_id[:8]}"

    # Preserve original file extensions
    audio_ext = Path(audio.filename).suffix or '.mp3'
    pdf_ext = Path(lecture_note.filename).suffix or '.pdf'

    audio_path = UPLOAD_DIR / f'{lecture_name}_audio{audio_ext}'
    pdf_path = UPLOAD_DIR / f'{lecture_name}_pdf{pdf_ext}'

    # Create job info
    job_info = JobInfo(job_id)
    jobs[job_id] = job_info

    try:
        # Save uploaded files
        async with aiofiles.open(audio_path, 'wb') as f:
            content = await audio.read()
            await f.write(content)

        async with aiofiles.open(pdf_path, 'wb') as f:
            content = await lecture_note.read()
            await f.write(content)

        # Start background processing
        asyncio.create_task(process_lecture_job(job_id, audio_path, pdf_path, lecture_name))

        # SSE generator with disconnect detection
        async def event_generator():
            import json
            try:
                while True:
                    job = jobs.get(job_id)
                    if not job:
                        yield {
                            "event": "error",
                            "data": json.dumps({"error": "Job not found"})
                        }
                        break

                    # Send current status
                    yield {
                        "event": "progress",
                        "data": json.dumps({
                            "job_id": job_id,
                            "status": job.status,
                            "progress": job.progress,
                            "message": job.message
                        })
                    }

                    # Check if done
                    if job.status == JobStatus.COMPLETED:
                        yield {
                            "event": "complete",
                            "data": json.dumps({
                                "job_id": job_id,
                                "status": job.status,
                                "progress": job.progress,
                                "message": job.message
                            })
                        }
                        break
                    elif job.status == JobStatus.FAILED:
                        yield {
                            "event": "error",
                            "data": json.dumps({
                                "job_id": job_id,
                                "status": job.status,
                                "error": job.error,
                                "message": job.message
                            })
                        }
                        break

                    # Wait before next update
                    await asyncio.sleep(0.5)

            except asyncio.CancelledError:
                # Client disconnected
                print(f"🔌 SSE client disconnected for job: {job_id}")
                raise
            except Exception as e:
                print(f"⚠️  SSE error for job {job_id}: {e}")
                raise

        return EventSourceResponse(event_generator())

    except Exception as e:
        # Clean up on error
        if job_id in jobs:
            del jobs[job_id]
        if audio_path.exists():
            await asyncio.to_thread(audio_path.unlink)
        if pdf_path.exists():
            await asyncio.to_thread(pdf_path.unlink)
        raise HTTPException(status_code = 500, detail = f'Failed to start synchronization: {str(e)}')

def create_zip_file(audio_file: str, timestamp_file: str) -> io.BytesIO:
    """Create ZIP file with audio and timestamps in memory. Run in executor."""
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        zip_file.write(audio_file, arcname = 'audio.opus')
        zip_file.write(timestamp_file, arcname = 'timestamps.json')
    zip_buffer.seek(0)
    return zip_buffer

def create_zip_file_to_disk(audio_file: str, timestamp_file: str, output_path: str) -> None:
    """Create ZIP file with audio and timestamps to disk. Run in executor."""
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        zip_file.write(audio_file, arcname = 'audio.opus')
        zip_file.write(timestamp_file, arcname = 'timestamps.json')

@app.get('/api/synchronize/status/{job_id}')
async def get_job_status(job_id: str):
    """
    Get the current status of a synchronization job.

    Args:
        job_id: The unique job identifier

    Returns:
        JSON object with job status information
    """
    job = jobs.get(job_id)
    if not job:
        raise HTTPException(status_code = 404, detail = 'Job not found')

    return {
        "job_id": job_id,
        "status": job.status,
        "progress": job.progress,
        "message": job.message,
        "error": job.error,
        "created_at": job.created_at.isoformat(),
        "completed_at": job.completed_at.isoformat() if job.completed_at else None
    }

@app.get('/api/synchronize/download/{job_id}')
async def download_result(job_id: str):
    """
    Download the result ZIP file for a completed synchronization job.

    Args:
        job_id: The unique job identifier

    Returns:
        ZIP file containing audio.opus and timestamps.json

    Raises:
        404: Job not found
        400: Job not completed yet or failed
        500: Output file not found
    """
    job = jobs.get(job_id)
    if not job:
        raise HTTPException(status_code = 404, detail = 'Job not found')

    if job.status == JobStatus.FAILED:
        raise HTTPException(
            status_code = 400,
            detail = f'Job failed: {job.error}'
        )

    if job.status != JobStatus.COMPLETED:
        raise HTTPException(
            status_code = 400,
            detail = f'Job not completed yet. Current status: {job.status}'
        )

    if not job.output_path or not job.output_path.exists():
        raise HTTPException(
            status_code = 500,
            detail = 'Output file not found'
        )

    # Mark as downloaded
    job.downloaded = True
    output_path = job.output_path

    # Cleanup function to run after file is sent
    def cleanup_after_send():
        """Cleanup function that runs after FileResponse completes sending the file."""
        try:
            if output_path and output_path.exists():
                output_path.unlink()
                print(f"🧹 Deleted downloaded file: {job_id}")
        except Exception as e:
            print(f"⚠️  Error deleting file {job_id}: {e}")

        try:
            if job_id in jobs:
                del jobs[job_id]
                print(f"🧹 Removed job after download: {job_id}")
        except Exception as e:
            print(f"⚠️  Error removing job {job_id}: {e}")

    return FileResponse(
        path = str(output_path),
        media_type = 'application/zip',
        filename = 'lecture_output.zip',
        background = BackgroundTask(cleanup_after_send)  # Cleanup after file is fully sent
    )

@app.get('/')
async def root():
    """Redirect to API documentation."""
    return RedirectResponse(url = '/docs')

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host = '0.0.0.0', port = 8080) # 8080 for port forwarding