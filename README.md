# Re:View
<p align="center">
  <img width="677" height="227" alt="Screenshot 2025-09-30 at 1 27 15 AM" src="https://github.com/user-attachments/assets/b34a752c-187a-4d65-986d-7333fd275d5a" />
</p>
Re:View takes in raw lecture recordings and lecture slides to refine them into structured, accessible study materials.

## Demo Video

Watch our demo video: [Re:View Demo](https://drive.google.com/file/d/1dP3Mh7w_vEuVcAlrbBAz7EjYFgb14REx/view?usp=drive_link)

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

1. Launch the app
2. Tap the '+' button to the upper right of the home screen, where add menu options drop down
3. Tap '강의 생성', and check that the language field is there - and options are switchable
4. Navigate back to home screen
5. Tap the '+' button to the upper right again
6. Tap '과목 추가'
7. Provide inputs for subject creation
    - Subject Name
    - Choose tags if you wish
8. Tap on '완료', and check that a subject has been added to your home screen
9. Tap on '수정하기' button to the left of '+' button
10. Tap and hold the handle of a subject (::) and drag it to reorder subjects
11. Tap on edit button (pencil) to the right of one subject
12. Edit subject name
13. Tap '+' button under 'Tags' field, and write new tag name and press '적용'
14. Tap '완료' to exit subject editing dialogue
15. Tap '수정하기' button again to see the changes applied to your subjects
16. Tap thumbnail of the Korean Tutorial Demo video to enter player screen
17. Scroll and tap sentences of transcripts to see synced skips
18. Set the device to landscape mode and tap on 'Full Screen' button
19. Double tap on either side of the screen to skip 10 sec
20. Tap on '자막' button to see subtitles in Korean
21. Tap on '대본' button to open the transcript panel to the right
22. Change back to portrait mode, then exit full screen mode by tapping on 'Full Screen' button again
23. Tap on 'Back' button to navigate back to home screen
24. Tap on upper left 'Menu' button, and tap on '설정' at the sidebar.
25. Tap on 'Help'
26. Tap on toggle buttons to the right of every FAQ to see the corresponding solution

## What Our Demo Demonstrates

### Features Implemented in Iteration 4

#### 1. Korean lecture support
- **New ASR Model**: Whisper model allows Korean/English ASR
- **Lecture Generation**: User can provide the spoken language in the lecture form screen.

#### 2. Enhanced usability of home screen UI
- **Shortcuts**: Allow adding new lecture & subject directly from the home screen.
- **Editing in home screen**: Allow lecture & subject identifier editing in the home screen via 'edit mode'.

#### 3. Enhanced usability of player UI
- **Informing deviation**: When synchronization is off and the user is viewing a slide different from the one aligned to the current sentence, the app indicates how far the viewed slide has deviated from the aligned slide.
- **Easy time-wise seeking**: Supports 10-second seeking by double tap
- **Reorganization of buttons**: Subtitles & transcript buttons are now located at the bottom when in horizontal playback.

#### 4. Tutorial
- **Tutorial as a reusable demo lecture**: User is no longer obliged to see the tutorial at the beginning, and can watch the tutorial whenever wanted.

#### 5. Testing Enhancements
- **Unit Test**: Covered 100% of backend, 85% of frontend code, incorporated in CI
- **Integration Tests**: Designed 7 integration scenarios - all passed

#### 6. Misc
- **High-contrast mode**: Thoroughly implemented high-contrast mode all across the application.
- **Stable server-client communication**: Lecture generation request & download request are appropriately resent on connection errors (e. g. connection reset by peer). Moreover, the result of lecture generation request can be successfully retrieved even when the SSE stream is closed (utilizing `status` API calls).
- **Help screen**: Provides help screen along the setting screens in FAQ format.
- **Storage organization**: Structured organization of lecture files (pdf, opus, m4a) & thorough deletion of unnecessary files to control storage usage.

### Goals Achieved

In Iteration 4, we focused on implementing Korean lecture support and enhancing usability of the application. We introduced Korean lecture support through a new Whisper-based ASR model and language-selectable lecture generation, alongside major usability improvements across the home and player screens, including direct shortcuts for adding lectures & subjects, home screen edit mode, deviation notifications when slides drift from aligned sentences, 10-second double-tap seeking, and reorganized playback controls. A reusable tutorial lecture replaces the mandatory onboarding flow, while testing was strengthened with full backend and high frontend coverage plus seven successful integration scenarios. Additional enhancements include comprehensive high-contrast mode, resilient server–client communication with automatic retries and status-based recovery, a new FAQ-style help screen, and improved file organization with robust cleanup of unused lecture assets.
