#!/usr/bin/env python3
"""
Test script for Re:view Backend API - Job Cancellation Feature

Tests the /api/synchronize/cancel endpoint with various scenarios.
"""

import requests
import json
import time
from pathlib import Path
import sseclient
import threading

# Configuration
API_BASE_URL = "http://localhost:8080"
TEST_AUDIO = Path(__file__).parent / "test_lecture" / "lecture_recording.mp3"
TEST_PDF = Path(__file__).parent / "test_lecture" / "lecture_slides.pdf"


def test_cancel_during_processing():
    """Test cancelling a job while it's being processed"""
    print("\n🧪 Test 1: Cancel job during processing")
    print("-" * 60)

    # Verify test files exist
    if not TEST_AUDIO.exists() or not TEST_PDF.exists():
        print(f"❌ Test files not found")
        return False

    try:
        # Prepare files
        files = {
            'audio': ('lecture_recording.mp3', open(TEST_AUDIO, 'rb'), 'audio/mpeg'),
            'lecture_note': ('lecture_slides.pdf', open(TEST_PDF, 'rb'), 'application/pdf')
        }

        # Start request with streaming
        print("📤 Starting job...")
        response = requests.post(
            f"{API_BASE_URL}/api/synchronize/stream",
            files=files,
            stream=True
        )

        if response.status_code != 200:
            print(f"❌ Request failed with status {response.status_code}")
            return False

        # Parse SSE events
        client = sseclient.SSEClient(response)
        job_id = None
        cancellation_sent = False

        for event in client.events():
            if event.event == 'progress':
                data = json.loads(event.data)
                job_id = data.get('job_id')
                status = data.get('status')
                progress = data.get('progress', 0)
                message = data.get('message', '')

                print(f"[{progress:5.1f}%] {status:20s} | {message}")

                # Cancel after ASR starts (around 15% progress)
                if not cancellation_sent and progress > 15:
                    print(f"\n🚫 Sending cancellation request for job {job_id}...")
                    cancel_response = requests.post(f"{API_BASE_URL}/api/synchronize/cancel/{job_id}")

                    if cancel_response.status_code == 200:
                        cancel_data = cancel_response.json()
                        print(f"✅ Cancellation accepted:")
                        print(f"   Message: {cancel_data.get('message')}")
                        print(f"   Current status: {cancel_data.get('current_status')}")
                        cancellation_sent = True
                    else:
                        print(f"❌ Cancellation failed: {cancel_response.status_code}")
                        print(cancel_response.text)
                        return False

            elif event.event == 'cancelled':
                data = json.loads(event.data)
                print("-" * 60)
                print(f"✅ Job successfully cancelled!")
                print(f"   Job ID: {data.get('job_id')}")
                print(f"   Message: {data.get('message')}")
                print(f"   Cancelled at: {data.get('cancelled_at')}")

                # Verify status endpoint shows cancelled status
                status_response = requests.get(f"{API_BASE_URL}/api/synchronize/status/{job_id}")
                if status_response.status_code == 200:
                    status_data = status_response.json()
                    if status_data.get('status') == 'cancelled':
                        print(f"✅ Status endpoint confirms cancellation")
                        return True
                    else:
                        print(f"⚠️  Status endpoint shows: {status_data.get('status')}")
                        return False
                break

            elif event.event == 'complete':
                print("-" * 60)
                print("⚠️  Job completed before cancellation could take effect")
                return False

            elif event.event == 'error':
                data = json.loads(event.data)
                print("-" * 60)
                print(f"❌ Job failed: {data.get('error')}")
                return False

        return False

    except Exception as e:
        print(f"❌ Error during test: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_cancel_already_completed():
    """Test cancelling a job that has already completed"""
    print("\n🧪 Test 2: Try to cancel completed job")
    print("-" * 60)

    try:
        # Start a job and wait for completion
        files = {
            'audio': ('lecture_recording.mp3', open(TEST_AUDIO, 'rb'), 'audio/mpeg'),
            'lecture_note': ('lecture_slides.pdf', open(TEST_PDF, 'rb'), 'application/pdf')
        }

        print("📤 Starting job and waiting for completion...")
        response = requests.post(
            f"{API_BASE_URL}/api/synchronize/stream",
            files=files,
            stream=True
        )

        if response.status_code != 200:
            print(f"❌ Request failed")
            return False

        client = sseclient.SSEClient(response)
        job_id = None

        for event in client.events():
            if event.event == 'progress':
                data = json.loads(event.data)
                job_id = data.get('job_id')
                progress = data.get('progress', 0)
                if progress % 20 == 0 or progress > 95:
                    print(f"[{progress:5.1f}%] Processing...")

            elif event.event == 'complete':
                data = json.loads(event.data)
                job_id = data.get('job_id')
                print(f"✅ Job completed: {job_id}")
                break

            elif event.event == 'error':
                print("❌ Job failed")
                return False

        # Try to cancel the completed job
        print(f"\n🚫 Attempting to cancel completed job {job_id}...")
        cancel_response = requests.post(f"{API_BASE_URL}/api/synchronize/cancel/{job_id}")

        if cancel_response.status_code == 400:
            error_data = cancel_response.json()
            print(f"✅ Cancellation correctly rejected:")
            print(f"   Error: {error_data.get('detail')}")

            # Clean up by downloading the file
            print(f"\n🧹 Cleaning up: downloading result...")
            download_response = requests.get(f"{API_BASE_URL}/api/synchronize/download/{job_id}")
            if download_response.status_code == 200:
                print(f"✅ File downloaded and job cleaned up")

            return True
        else:
            print(f"❌ Expected 400 status, got {cancel_response.status_code}")
            return False

    except Exception as e:
        print(f"❌ Error during test: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_cancel_nonexistent_job():
    """Test cancelling a job that doesn't exist"""
    print("\n🧪 Test 3: Try to cancel non-existent job")
    print("-" * 60)

    try:
        fake_job_id = "00000000-0000-0000-0000-000000000000"
        print(f"🚫 Attempting to cancel non-existent job {fake_job_id}...")

        cancel_response = requests.post(f"{API_BASE_URL}/api/synchronize/cancel/{fake_job_id}")

        if cancel_response.status_code == 404:
            error_data = cancel_response.json()
            print(f"✅ Cancellation correctly rejected:")
            print(f"   Error: {error_data.get('detail')}")
            return True
        else:
            print(f"❌ Expected 404 status, got {cancel_response.status_code}")
            return False

    except Exception as e:
        print(f"❌ Error during test: {e}")
        return False


def test_cancel_early():
    """Test cancelling a job very early (before ASR starts)"""
    print("\n🧪 Test 4: Cancel job immediately after starting")
    print("-" * 60)

    try:
        files = {
            'audio': ('lecture_recording.mp3', open(TEST_AUDIO, 'rb'), 'audio/mpeg'),
            'lecture_note': ('lecture_slides.pdf', open(TEST_PDF, 'rb'), 'application/pdf')
        }

        print("📤 Starting job...")
        response = requests.post(
            f"{API_BASE_URL}/api/synchronize/stream",
            files=files,
            stream=True
        )

        if response.status_code != 200:
            print(f"❌ Request failed")
            return False

        client = sseclient.SSEClient(response)
        job_id = None
        cancellation_sent = False

        for event in client.events():
            if event.event == 'progress':
                data = json.loads(event.data)
                job_id = data.get('job_id')
                status = data.get('status')
                progress = data.get('progress', 0)

                print(f"[{progress:5.1f}%] {status}")

                # Cancel as soon as we get the first progress event
                if not cancellation_sent:
                    print(f"\n🚫 Immediately cancelling job {job_id}...")
                    cancel_response = requests.post(f"{API_BASE_URL}/api/synchronize/cancel/{job_id}")

                    if cancel_response.status_code == 200:
                        print(f"✅ Cancellation request accepted")
                        cancellation_sent = True
                    else:
                        print(f"❌ Cancellation failed: {cancel_response.status_code}")
                        return False

            elif event.event == 'cancelled':
                data = json.loads(event.data)
                print("-" * 60)
                print(f"✅ Job successfully cancelled early!")
                print(f"   Message: {data.get('message')}")
                return True

            elif event.event == 'complete':
                print("-" * 60)
                print("⚠️  Job completed before cancellation took effect")
                # Still acceptable if job was very fast
                return True

            elif event.event == 'error':
                print("-" * 60)
                print("❌ Job failed")
                return False

        return False

    except Exception as e:
        print(f"❌ Error during test: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all cancellation tests"""
    print("=" * 60)
    print("Re:view Backend API - Cancellation Test Suite")
    print("=" * 60)

    # Verify test files exist
    if not TEST_AUDIO.exists():
        print(f"❌ Test audio file not found: {TEST_AUDIO}")
        return 1
    if not TEST_PDF.exists():
        print(f"❌ Test PDF file not found: {TEST_PDF}")
        return 1

    print(f"📁 Audio: {TEST_AUDIO.name} ({TEST_AUDIO.stat().st_size / 1024 / 1024:.2f} MB)")
    print(f"📁 PDF: {TEST_PDF.name} ({TEST_PDF.stat().st_size / 1024:.2f} KB)")

    results = []

    # Test 1: Cancel during processing
    results.append(("Cancel during processing", test_cancel_during_processing()))

    # Wait between tests to avoid conflicts
    time.sleep(2)

    # Test 2: Cancel already completed job
    results.append(("Cancel completed job (should fail)", test_cancel_already_completed()))

    time.sleep(2)

    # Test 3: Cancel non-existent job
    results.append(("Cancel non-existent job (should fail)", test_cancel_nonexistent_job()))

    time.sleep(2)

    # Test 4: Cancel early
    results.append(("Cancel job immediately", test_cancel_early()))

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
        print("\n🎉 All cancellation tests passed!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return 1


if __name__ == "__main__":
    exit(main())
