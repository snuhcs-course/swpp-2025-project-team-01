#!/usr/bin/env python3
"""
Simple test script for Re:view Backend API

Tests the /api/synchronize/stream endpoint with SSE progress monitoring.
"""

import requests
import json
import time
from pathlib import Path
import sseclient

# Configuration
API_BASE_URL = "http://localhost:8080" # 8080 for port forwarding
TEST_AUDIO = Path(__file__).parent / "test_lecture" / "kor_lecture_recording.m4a"
TEST_PDF = Path(__file__).parent / "test_lecture" / "kor_lecture_slides.pdf"
OUTPUT_FILE = Path(__file__).parent / "kor_test_output.zip"

def test_root_endpoint():
    """Test root endpoint - should redirect to /docs"""
    print("🧪 Testing root endpoint...")
    try:
        response = requests.get(f"{API_BASE_URL}/", allow_redirects=False)
        if response.status_code == 307:
            print(f"✅ Root endpoint returns redirect to {response.headers.get('location')}")
            return True
        else:
            print(f"❌ Unexpected status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_synchronize_stream():
    """Test synchronize endpoint with SSE streaming"""
    print("\n🧪 Testing /api/synchronize/stream endpoint...")

    # Verify test files exist
    if not TEST_AUDIO.exists():
        print(f"❌ Test audio file not found: {TEST_AUDIO}")
        return False
    if not TEST_PDF.exists():
        print(f"❌ Test PDF file not found: {TEST_PDF}")
        return False

    print(f"📁 Audio: {TEST_AUDIO.name} ({TEST_AUDIO.stat().st_size / 1024 / 1024:.2f} MB)")
    print(f"📁 PDF: {TEST_PDF.name} ({TEST_PDF.stat().st_size / 1024:.2f} KB)")

    try:
        # Prepare files
        files = {
            'audio': ('lecture_recording.mp3', open(TEST_AUDIO, 'rb'), 'audio/mpeg'),
            'lecture_note': ('lecture_slides.pdf', open(TEST_PDF, 'rb'), 'application/pdf')
        }

        # Start request with streaming
        print("\n📤 Uploading files and starting processing...")
        response = requests.post(
            f"{API_BASE_URL}/api/synchronize/stream",
            files=files,
            data = {'lang':'ko'},
            stream=True
        )

        if response.status_code != 200:
            print(f"❌ Request failed with status {response.status_code}")
            print(response.text)
            return False

        # Parse SSE events
        client = sseclient.SSEClient(response)
        job_id = None
        last_progress = 0

        print("\n📊 Progress updates:")
        print("-" * 60)

        for event in client.events():
            if event.event == 'progress':
                data = json.loads(event.data)
                job_id = data.get('job_id')
                status = data.get('status')
                progress = data.get('progress', 0)
                message = data.get('message', '')

                # Show progress updates when progress changes significantly
                if progress - last_progress >= 5 or status != data.get('status'):
                    print(f"[{progress:5.1f}%] {status:20s} | {message}")
                    last_progress = progress

            elif event.event == 'complete':
                data = json.loads(event.data)
                job_id = data.get('job_id')
                print("-" * 60)
                print(f"✅ {data.get('message', 'Completed!')}")
                print(f"🆔 Job ID: {job_id}")
                break

            elif event.event == 'error':
                data = json.loads(event.data)
                print("-" * 60)
                print(f"❌ Error: {data.get('error', 'Unknown error')}")
                print(f"   Message: {data.get('message', '')}")
                return False

        # Test status endpoint
        if job_id:
            print(f"\n🧪 Testing /api/synchronize/status/{job_id}...")
            status_response = requests.get(f"{API_BASE_URL}/api/synchronize/status/{job_id}")
            if status_response.status_code == 200:
                status_data = status_response.json()
                print(f"✅ Status endpoint working:")
                print(f"   Status: {status_data.get('status')}")
                print(f"   Progress: {status_data.get('progress')}%")
            else:
                print(f"❌ Status endpoint failed: {status_response.status_code}")

        # Test download endpoint
        if job_id:
            print(f"\n🧪 Testing /api/synchronize/download/{job_id}...")
            download_response = requests.get(f"{API_BASE_URL}/api/synchronize/download/{job_id}")
            if download_response.status_code == 200:
                # Save to file
                OUTPUT_FILE.write_bytes(download_response.content)
                file_size = OUTPUT_FILE.stat().st_size / 1024
                print(f"✅ Download successful: {OUTPUT_FILE.name} ({file_size:.2f} KB)")

                # Verify ZIP contents
                import zipfile
                with zipfile.ZipFile(OUTPUT_FILE, 'r') as zip_file:
                    contents = zip_file.namelist()
                    print(f"📦 ZIP contents: {', '.join(contents)}")
                    if 'audio.opus' in contents and 'timestamps.json' in contents:
                        print("✅ ZIP file structure is correct")
                    else:
                        print("⚠️  Unexpected ZIP contents")
            else:
                print(f"❌ Download failed: {download_response.status_code}")
                print(download_response.text)
                return False

        return True

    except Exception as e:
        print(f"❌ Error during test: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("Re:view Backend API Test Suite")
    print("=" * 60)

    results = []

    # Test 1: Root endpoint
    results.append(("Root endpoint", test_root_endpoint()))

    # Test 2: Synchronize stream endpoint (full pipeline)
    results.append(("Synchronize stream", test_synchronize_stream()))

    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status:8s} | {test_name}")

    print("-" * 60)
    print(f"Total: {passed}/{total} tests passed")

    if passed == total:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return 1

if __name__ == "__main__":
    exit(main())
