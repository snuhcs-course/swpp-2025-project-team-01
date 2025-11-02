# Re:View
<p align="center">
  <img width="677" height="227" alt="Screenshot 2025-09-30 at 1 27 15 AM" src="https://github.com/user-attachments/assets/b34a752c-187a-4d65-986d-7333fd275d5a" />
</p>
Re:View takes in raw lecture recordings and lecture slides to refine them into structured, accessible study materials.

## Demo Video

Watch our demo video: [Re:View Demo](https://drive.google.com/file/d/1iEudkYxvhdlsZyZ28f13FbiwtDkjRCmZ/view?usp=drive_link)

## How to Run the Demo

### Environment
- **Flutter Version**: 3.35.4 (stable channel)
- **Dart Version**: 3.9.2
- **Development Tools**: VS Code with Flutter extensions
- **Testing Device/Emulator**: Android (API 36)

### Prerequisites
- Flutter SDK 3.35.4 or higher
- Dart SDK 3.9.2 or higher
- Android Studio or VS Code with Flutter/Dart plugins
- Android SDK (API level 21 or higher)
- Git for version control

### Setup Instructions

1. **Clone the repository and checkout the demo branch**
   ```bash
   git clone https://github.com/snuhcs-course/swpp-2025-project-team-01.git
   cd swpp-2025-project-team-01
   git checkout iteration-3-demo
   ```

2. **Navigate to frontend directory**
   ```bash
   cd frontend
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```
   This command downloads all the required packages specified in `pubspec.yaml` (e.g., pdfx, audioplayers, shared_preferences, etc.)

4. **Run the application**
   ```bash
   flutter run
   ```

### Demo Scenario

Follow these steps to reproduce the demo video:

1. Launch the app (w/ logo)
2. Tutorial screen pops up - tap 'NEXT' to continue (x4), lastly tap 'DONE'
3. Tap upper left 'menu' button to open menu sidebar, then press '강의 생성'
4. Provide inputs for the lecture:
- Subject ('unclassified' supported)
- Lecture Week (required)
- Lecture Title (required)
- Lecture Slide PDF (required)
- Lecture Audio m4a (required)
- Correponding Slide Range (required, but provided by default)
4. Tap on 'Create'
5. Allow 'Running on Background', 'notifications'
6. Drag on the lower widget to make it collapse to a circular one
7. Move to the home screen of emulator, to verify background processing
8. Tap upper left 'menu' button to open menu sidebar, then press '태그 수정'
9. Tap on different themes to apply them
  - '봄' (default) -> '여름' -> '겨울' -> ...
10. Tap on upper left 'back' button to return to home screeen
11. Again, tap upper left 'menu' button to open menu sidebar, then press '과목 수정'
12. Drag and drop the subjects to change their order
-  Drag '외계행성과 생명' to the top of '소프트웨어 개발의 원리와 실습'
-  Collapse loading widget
-  Press '수정 완료' to apply & return to home screen
13. When lecture generation is finished, tap on the lecture and play the lecture:
- Press language switch button (ENG/KOR) to see Korean transcript
- Press playback speed button to adjust tts speed
- Change screen to horizontal mode
- Tap on the TTS/Org audio button to hear original audio
- Tap on the right toggle to view transcript
- Tap on the subtitle button to turn on subtitles
- Tapping on the language button will also be reflected in subtitles
14. Return to home screen
15. Again, tap upper left 'menu' button to open menu sidebar, then press '설정'
16. Tap on 'Accessibility' and turn on the switch for '고대비'
17. Re-enter player mode to see high-contrast has been toggled on for pdf as well.

## What Our Demo Demonstrates

### Features Implemented in Iteration 3

#### 1. Multi-audio Lecture Processing
- **Lecture Retrieval & Storage**: Stable request & retrieval of synchronized lecture
- **Background Lecture Processing**: Background lecture processing is now supported, notifications when finished

#### 2. Support Korean Translation (Transcript)
- **Incorporated Translation Model**: Allow real-time switch of language in player transcripts

#### 3. Support original audio sync & switches
- **Original Audio Timestamps**: Allow real-time switch to original audio in case TTS is inaccurate, or the user simply wishes to hear original lecture audio

#### 4. Testing
- **Unit Test**: Cover 100% of backend, 70% of frontend code, incorporated with CI

#### 5. Misc
- **Loading Widget**: Shows user-friendly progress widget when loading, collapsible & movable within screen
- **Tutorial**: Shows app tutorial to users when the app is first launched after installation
- **Support 'unclassified' lectures**: User may choose not to designate any subject for a lecture
- **Enhanced Accessibility Features**: Extended 'high contrast' option to player screen
- **Playback Speed Button**: Now supports playback speed adjustments in player screen
- **Dark Mode**: Extended dark mode to support more screens
- **UI Modifications**: Added app logo, custom font (NanumSquare), customized tag color themes, refined UI wireframe
- **Refactoring**: More global use of cache managers, modularizing player screen code etc


### Goals Achieved

In Iteration 3, we focused on enhancing the core lecture processing capabilities and user experience. We successfully implemented multi-audio lecture processing with stable retrieval, storage, and background processing notifications, allowing users to manage multiple lectures seamlessly. Language accessibility was significantly improved through integrated Korean translation support with real-time transcript switching and original audio synchronization for verification purposes. The development process was strengthened with comprehensive testing coverage (100% backend, 70% frontend) integrated into our CI pipeline. Additionally, we refined the user interface with intuitive loading widgets, an onboarding tutorial, app branding elements, and extended dark mode and high contrast accessibility features across the application, while conducting substantial code refactoring to improve maintainability.
