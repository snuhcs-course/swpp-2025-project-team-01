# Re:View
<p align="center">
  <img height="227" alt="Re:view main logo" src="https://github.com/user-attachments/assets/b34a752c-187a-4d65-986d-7333fd275d5a" />
</p>
Re:View takes in raw lecture recordings and lecture slides to refine them into structured, accessible study materials.

## Overview

Re:View is a mobile application that takes in raw lecture recordings and lecture slides to reconstruct them into a complete easy-to-follow lecture. By combining audio cleanup, accurate transcription, and slide-to-sentence alignment, our application provides realistic lecture experience from the reconstructed lecture presented in a video-like format. Re:View also provides refined lecture transcripts along with automatic annotations for those with hearing disabilities. To summarize, Re:View is a seamless review tool that makes learning easier, more efficient, and more inclusive for everyone involved in education, regardless of their role.

## Features

- **AI-Powered Lecture Reconstruction**: Combines ASR, slide matching, and TTS to create synchronized lecture materials
- **Bilingual Support**: English and Korean lectures with automatic bidirectional translation
- **Intuitive Mobile Experience**: Portrait/landscape modes with real-time slide-transcript synchronization
- **Cross-Platform Support**: Built with Flutter for seamless deployment across Android and iOS
- **Accessibility-First Design**: Refined transcripts and automatic annotations for hearing-impaired users
- **Customizable Interface**: Light/dark themes, adjustable playback speed, and TTS settings
- **Organized Library**: Subject-based organization with tags, favorites, and powerful search

## Architecture

<img height="516" alt="Architecture diagram" src="https://github.com/user-attachments/assets/c3a4b8a8-f457-41cf-8240-1e2e4d0b622d" />

**Frontend**: Flutter mobile app with Hive-based state management

**Backend**: FastAPI server with AI inference pipeline (NVIDIA Parakeet, OpenAI Whisper, Hunyuan MT, Kokoro TTS)

## Getting Started

### Frontend (Mobile App)
```bash
cd frontend
flutter pub get
flutter run
```

### Backend (AI Pipeline)
```bash
cd backend
./setup.sh                    # One-time setup (creates conda environment)
conda activate swpp-backend
python main.py                # Server runs on http://localhost:8080
```


## Wiki

For detailed project documentation, design documents, and specifications:
- [Wiki Home](https://github.com/snuhcs-course/swpp-2025-project-team-01/wiki)
- [Design Documentation](https://github.com/snuhcs-course/swpp-2025-project-team-01/wiki/Design-Documentation)
- [Requirements & Specifications](https://github.com/snuhcs-course/swpp-2025-project-team-01/wiki/Requirements-&-Specifications)
