# Re:View
<p align="center">
  <img width="677" height="227" alt="Screenshot 2025-09-30 at 1 27 15 AM" src="https://github.com/user-attachments/assets/b34a752c-187a-4d65-986d-7333fd275d5a" />
</p>
Re:View takes in raw lecture recordings and lecture slides to refine them into structured, accessible study materials.

## Demo Video

Watch our demo video: [Re:View Demo](https://drive.google.com/file/d/1WmofMLBiUXRYE6Xp_ULFdpR6wvjDUizW/view?usp=sharing)

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
   git checkout iteration-1-demo
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
2. Toggle "소프트웨어 개발의 원리와 실습" course (expand/collapse)
3. Test tag filtering:
   - Press filter button
   - Select "#25-1" and "#AI" tags
   - Press filter button again to deselect
4. Test favorites:
   - Press favorite button
   - Toggle favorite status on different courses
   - Verify filtering works correctly
5. Modify lecture week:
   - Long press "Demo" lecture
   - Change week from "Week 1-1" to "Iter 1"
6. Test video player (portrait):

   *Note that due to some issues with the emulator, the volume is quite low. We recommend running the video with maximum volume to hear the TTS audio.*
   - Tap "Demo" lecture
   - Scroll through transcript
   - Tap any sentence to skip to that timestamp
8. Test video player (landscape):
   - Rotate screen to landscape
   - Test 15-second skip buttons
   - Open/close transcript panel
   - Pause video
   - Return to home screen
9. Test search functionality:
   - Press search button
   - Type "proce"
   - Verify search results appear
   - Tap that lecture from search results
   - Verify if the player screen appears
   - Verify if recent searches features run
   - Navigate back to home
10. Open menu
11. Show "수업 추가" screen
12. Test course editing:
    - Open course edit screen
    - Add a new course
    - Drag "Demo" lecture down in "소프트웨어 개발의 원리와 실습" course
    - Delete "Week 2-1" lecture from "외계행성과 생명" course
    - Return to home and verify changes
13. Test tag editing:
    - Open tag editor
    - Change tag tone to "네온"
    - Rename "25-2" tag to "This Semester"
    - Create new tag
    - Apply changes
14. Apply new tags:
    - Open course editor
    - Add "새 태그" to newly created course
    - Verify changes on home screen
15. Settings exploration:
    - Open settings
    - Review each option screen
    - Test each feature

## What Our Demo Demonstrates

### Core Features Implemented

#### 1. Course Management
- **Course List View**: Display courses with expandable/collapsible sections (toggles)
- **Favorite Courses**: Toggle favorite status and filter to show only favorited courses
- **Course Editing**: Add, edit, and delete courses with drag-and-drop reordering & buttons
- **Lecture Management**: Add/delete lectures within courses, modify lecture's details

#### 2. Tag System
- **Tag Filtering**: Filter courses by tags (e.g., #25-1, #AI)
- **Tag Editing**: Customize tag colors with different themes (e.g., Neon)
- **Tag Management**: Create, rename, and assign tags to courses

#### 3. Video Player
- **Dual Orientation Support**:
  - Portrait mode with bottom transcript panel
  - Landscape mode with side transcript panel
- **Transcript Integration**:
  - Scrollable transcript synchronized with video
  - Tap-to-seek functionality
  - Collapsible transcript panel in landscape mode
- **Playback Controls**: Play/pause, 15-second skip forward/backward

#### 4. Search Functionality
- **Real-time Search**: Search courses by course/subject/week name with live results
- **Search History**: Recent search terms saved and displayed
- **Quick Navigation**: Direct access to video player from search results

#### 5. Settings
- **Display Mode**: Switch between light/dark mode manually or sync with device system settings
- **TTS (Text-to-Speech)**: UI layout implemented with data persistence (functionality to be added in future iterations)
- **Accessibility**:
  - High contrast mode for enhanced visibility
  - Toggle animations on/off throughout the app
- **Language**: Switch between Korean and English app-wide
- **Help**: Placeholder section for future user guide and documentation

### Goals Achieved

We have successfully implemented a comprehensive initial draft of all core frontend features. While minor refinements, performance optimizations, and UI/UX improvements may still be needed, the current implementation is fully capable of integrating with the backend to deliver the complete application experience we envisioned. All essential user-facing functionalities are operational and ready for backend integration.
