# Re:View
<p align="center">
  <img width="677" height="227" alt="Screenshot 2025-09-30 at 1 27 15 AM" src="https://github.com/user-attachments/assets/b34a752c-187a-4d65-986d-7333fd275d5a" />
</p>
Re:View takes in raw lecture recordings and lecture slides to refine them into structured, accessible study materials.

## Demo Video

Watch our demo video: [Re:View Demo]()

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
   git checkout iteration-5-demo
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
3. Tap '과목 추가', add a subject whose name already exists, and check that it isn't added
4. Tap the top right 'X' or outside of the dialog, and tap the '수정' button besides the '+' button
5. Tap the top left '필터' and the star button in order, and check that they don't work and the appropriate snackbars appear
6. Tap the pencil button in the '환영합니다!' subject header
7. Tap the '보관' button, and check that '환영합니다!' subject isn't shown in home screen
8. Tap the top left menu button, and tap '보관함'
9. Tap the unarchive button of the '환영합니다!' subject header (between trash bin button and toggle button), tap the '예' button, navigate back to home screen, and check that '환영합니다!' subject appears in home screen
10. Tap the top left menu button again, and tap '태그 수정'
11. Delete all tags using the '삭제' button, and check that text box and buttons don't work when there isn't any tag
12. Create two tags with no name editing, and check the second one's name editing starts with '새 태그(1)'
13. Navigate back to home screen, and tap the top right '+' button again
14. Tap '강의 생성', upload any PDF file (tap the '추가' button), and check that the text of right button changes from '추가' to '변경'
15. Upload any audio file, and check that the next audio file slot is formed automatically and the red '제거' button is formed in the uploaded slot (to the left of the '변경' button, the text of the '추가' button in the uploaded slot changes to '변경')
16. Upload one more audio file, and check that the first (at the top) audio file can be removed
17. Fill the other elements, and generate the lecture normally
18. Slide up the lecture generating loading bar, and check that the collapsed loading bar is sticky to the left/right edge of the screen
19. Navigate back to home screen, and tap the pre-generated Korean lecture
20. In the player, tap the 'Rec' button, and check that the scackbar '한국어 강의는 TTS 음성이 제공되지 않습니다.' appears and the lecture is continuously played with recorded audio (not TTS)
21. Slide up the screen, tap the un-matched lecture slide, and check that it isn't conducted to move to that slide
22. Slide down the screen, and check that the PDF navigator disappears

## What Our Demo Demonstrates

### Features Implemented in Iteration 5

#### 1. Redesigned native splash screen
- **Natural loading flow**: Redesign flutter native splash screen naturally.

#### 2. Enhanced usability of add subject UI
- **Impossible subject name duplication**: Do not allow adding subject whose name already exists.

#### 3. Enhanced usability of home edit mode
- **Block filter/favorite tapping in edit mode**: In edit mode at home screen, filter and favorite buttons don't work. If user tap it, the related snackbar messages appear.

#### 4. Enhanced usability of tags edit UI
- **Block features with no tag**: When there isn't any tag, the name input text box and delete/apply buttons are inactivated.
- **Tag name editing start point**: Every tag name editing starts at that exact current name.

#### 5. Enhanced usability of multi-audio lecture generation UI
- **Meaningful button text**: After a file is uploaded, the text of that slot's add button changes from 'add' to 'change'.
- **Modified mechanism of uploading multi-audio**: Existing +/- buttons are removed, the next audio file uploading slot is formed automatically when an audio file is uploaded, instead.

#### 6. Enhanced usability of player UI
- **Information for not supporting Korean TTS**: When user tap the 'Rec' button in Korean lecture, the snackbar message ('한국어 강의는 TTS 음성이 제공되지 않습니다.') appears and there's no change in playing audio.
- **More usable PDF navigator**: User can slide up the screen to open PDF navigator even in playbar state. Addedly, user can close PDF navigator by sliding down the screen. Moreover, when user tap the unmatched slide in PDF navigator, it is unresponsive to touch, and nothing happens. (Originally, there was an animation that briefly navigated to the slide and then returned)

#### 7. Subject archiving
- **Archiving**: User can archive subjects in edit subject info dialog. If archived, the subject lose all tags/favorite state, and disappears in home screen.
- **Unarchiving**: Archived subjects are shown in archive (menu tap). User can delete/unarchive/toggle archived subjects in archive. If unarchived, the subject appears in home screen again with no tags/favorite state.

#### 8. Testing Enhancements
- **Unit Test**: Covered 100% of backend, 86.8% of frontend code, incorporated in CI.

### Goals Achieved

In Iteration 5, we focused on enhancing overall usability and robustness by refining user interactions across key features. We improved the UX flows for Subject, Tag, and Lecture Generation UIs by handling edge cases and preventing invalid actions, ensuring a seamless experience from the splash screen to the player. Additionally, we implemented a Subject Archiving system for better content lifecycle management and optimized the Lecture Player with intuitive gesture controls and clearer feedback. Finally, we solidified system reliability by achieving comprehensive unit test coverage.
