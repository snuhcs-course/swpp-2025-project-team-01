# Re:View
<p align="center">
  <img width="677" height="227" alt="Screenshot 2025-09-30 at 1 27 15 AM" src="https://github.com/user-attachments/assets/b34a752c-187a-4d65-986d-7333fd275d5a" />
</p>
Re:View takes in raw lecture recordings and lecture slides to refine them into structured, accessible study materials.

## Demo Video

Watch our demo video: [Re:View Demo](https://drive.google.com/file/d/1dld4QQEUPP-WcGHozV_yBXi37Ha94BIL/view?usp=sharing)

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
   git checkout iteration-2-demo
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
2. Open the menu on the left top and select 'Add Lecture'
3. Provide inputs for the lecture:
- Subject
- Lecture Week (required)
- Lecture Title (required)
- Lecture Slide PDF (required)
- Lecture Audio m4a (required)
4. Tap on 'Create'
5. When lecture generation is finished, navigate to the home screen.
6. Tap on the generated lecture, and play the lecture:
- Seek by sentence & slide
- Seek by duration (15 seconds) in both directions
- Flip to horizontal view and enable the subtitles
- Flip again to vertical view and try turning off the sync
7. Return to the home screen
8. Open the menu on the left top and select 'Settings'
9. Tap on 'Accessibility' and turn on the switch for 'Reduce Motion'
10. Exit the accessibility features screen to observe faster transition

## What Our Demo Demonstrates

### Features Implemented in Iteration 2

#### 1. Full Lecture Generation
- **Customizable Descriptions**: Designate the week, title and subject
- **Lecture Retrieval & Storage**: Stable request & retrieval of synchronized lecture (single audio only)

#### 2. Accessibility Feature
- **Reducing motion effects**: Allow faster screen transitions

#### 3. Smoother synchronization
- **Player Enhancement**: Replaced `audioplayers` for `just_audio` for better OPUS support

### Goals Achieved

In this iteration, we have put our primary focus on successfully implementing a complete lecture generation pipeline. Some implementation fixes such as replacing audio player library from `audioplayers` to `just_audio` and replacing the data container from self-designed `Repo` class to `Hive` library models have enhanced the performance of relevant features.
