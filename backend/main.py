from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse, RedirectResponse
import sys
from pathlib import Path
import shutil
import io
import zipfile
from datetime import datetime
import asyncio
import aiofiles
from contextlib import asynccontextmanager

# Add inference_models directory to path
sys.path.append(str(Path(__file__).parent.parent / "inference_models"))
from lecture_pipeline import LecturePipeline, PipelineOutput, simple_sentence_splitter

# Global variable
pipeline: LecturePipeline | None = None
ml_inference_semaphore: asyncio.Semaphore | None = None
UPLOAD_DIR = Path('./uploads')
OUTPUT_DIR = Path('./pipeline_output')

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan - initialize and cleanup resources."""
    global ml_inference_semaphore, pipeline

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
    
    yield

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
    lecture_name: str
) -> PipelineOutput:
    """
    Run ML pipeline in a thread pool to avoid blocking event loop.
    This is necessary because the pipeline operations are CPU/GPU intensive.
    """
    pipeline_instance = get_pipeline()

    output = await asyncio.to_thread(
        pipeline_instance.run,
        audio_path = audio_path,
        pdf_path = pdf_path,
        lecture_name = lecture_name,
        simple_sentence_splitter = simple_sentence_splitter,
        save_intermediate = False
    )
    return output

@app.post('/api/synchronize')
async def synchronize(
    audio: UploadFile = File(..., description = 'Lecture audio file (mp3, wav, etc.)'),
    lecture_note: UploadFile = File(..., description = 'Lecture slides PDF')
):
    """
    Synchronize lecture audio with slides.

    Returns a ZIP file containing:
    - audio.opus: Reconstructed audio file
    - timestamps.json: Timestamps with slide alignment

    Args:
        audio: Lecture audio file
        lecture_note: Lecture slides PDF file

    Returns:
        ZIP file with audio.opus and timestamps.json

    Note:
        Due to GPU resource constraints, only one inference can run at a time.
        Concurrent requests will be queued automatically.
    """

    # Generate unique lecture name based on timestamp
    lecture_name = f"lecture_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    # Preserve original file extensions
    audio_ext = Path(audio.filename).suffix or '.mp3'
    pdf_ext = Path(lecture_note.filename).suffix or '.pdf'

    audio_path = UPLOAD_DIR / f'{lecture_name}_audio{audio_ext}'
    pdf_path = UPLOAD_DIR / f'{lecture_name}_pdf{pdf_ext}'

    try:
        async with aiofiles.open(audio_path, 'wb') as f:
            content = await audio.read()
            await f.write(content)

        async with aiofiles.open(pdf_path, 'wb') as f:
            content = await lecture_note.read()
            await f.write(content)

        async with ml_inference_semaphore:
            output: PipelineOutput = await run_pipeline_in_executor(
                audio_path = str(audio_path),
                pdf_path = str(pdf_path),
                lecture_name = lecture_name
            )

        # Verify output files exist before creating ZIP
        audio_file_path = Path(output.audio_file)
        timestamps_file_path = Path(output.timestamps_file)

        if not audio_file_path.exists():
            raise HTTPException(status_code = 500, detail = 'Audio file generation failed')
        if not timestamps_file_path.exists():
            raise HTTPException(status_code = 500, detail = 'Timestamps file generation failed')

        zip_buffer = await asyncio.to_thread(
            create_zip_file,
            str(audio_file_path),
            str(timestamps_file_path)
        )

        output_dir = Path(output.output_directory)
        if output_dir.exists():
            await asyncio.to_thread(shutil.rmtree, output_dir)
        
        return StreamingResponse(
            zip_buffer,
            media_type = 'application/zip',
            headers = {
                'Content-Disposition': f'attachment; filename=lecture_output.zip'
            }
        )
    except Exception as e:
        # Clean up on error
        output_dir = OUTPUT_DIR / lecture_name
        if output_dir.exists():
            await asyncio.to_thread(shutil.rmtree, output_dir)
        raise HTTPException(status_code = 500, detail = f'Synchronization failed: {str(e)}')
    
    finally:
        if audio_path.exists():
            await asyncio.to_thread(audio_path.unlink)
        if pdf_path.exists():
            await asyncio.to_thread(pdf_path.unlink)

def create_zip_file(audio_file: str, timestamp_file: str) -> io.BytesIO:
    """Create ZIP file with audio and timestamps. Run in executor."""
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        zip_file.write(audio_file, arcname = 'audio.opus')
        zip_file.write(timestamp_file, arcname = 'timestamps.json')
    zip_buffer.seek(0)
    return zip_buffer

@app.get('/')
async def root():
    """Redirect to API documentation."""
    return RedirectResponse(url = '/docs')

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host = '0.0.0.0', port = 8000)