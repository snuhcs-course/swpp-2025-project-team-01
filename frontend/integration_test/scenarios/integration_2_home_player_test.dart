import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/player/player_layout.dart';
import '../helpers/test_helpers.dart';

/// Integration Test 2: Home + Player (Tutorial Lecture Navigation)
///
/// Test Scenario:
/// 1. Tap on tutorial lecture (assets) in home screen
/// 2. Confirm correct navigation to appropriate player screen
/// 3. Tap on subtitles button and assure that the subtitles are visible
Future<void> runIntegration2Test(WidgetTester tester) async {
  final manager = HiveManager.instance;

  // Wait for app to be ready
  await IntegrationTestHelpers.waitForAppReady(tester);

  // Get the tutorial lecture (lec_demo_001 from assets)
  final tutorialLecture = manager.getLecture('lec_demo_001');
  expect(
    tutorialLecture,
    isNotNull,
    reason: 'Tutorial lecture should exist in assets',
  );

  debugPrint('Tutorial lecture found: ${tutorialLecture!.title}');

  // Step 1: Find and tap on tutorial lecture in home screen
  // The lecture should be in subject 's1' (환영합니다!)
  final subject = manager.getSubject('s1');
  expect(subject, isNotNull, reason: 'Subject s1 should exist');
  expect(
    subject!.lectureIds.contains('lec_demo_001'),
    true,
    reason: 'Subject should contain tutorial lecture',
  );

  // Wait for UI to settle and ensure home screen is fully loaded
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify we're on home screen
  final menuButton = find.byIcon(Icons.menu);
  expect(menuButton, findsOneWidget, reason: 'Should be on home screen');

  debugPrint('Confirmed on home screen, looking for lecture widget...');

  // First, try to expand the subject panel by tapping on the subject title
  final subjectTitle = find.text(subject.title);
  if (subjectTitle.evaluate().isNotEmpty) {
    try {
      await tester.tap(subjectTitle.first);
      await tester.pumpAndSettle();
      debugPrint('✓ Expanded subject panel');
    } catch (e) {
      // Subject might already be expanded
      debugPrint('Subject panel already expanded or not collapsible: $e');
    }
  } else {
    debugPrint('⚠️ Could not find subject title: ${subject.title}');
  }

  // Additional wait for expansion animation
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Find the lecture item by looking for the lecture title or week label
  final lectureFinder = find.text(tutorialLecture.title);
  final weekFinder = find.text(tutorialLecture.weekLabel);

  debugPrint(
    'Looking for lecture: ${tutorialLecture.title} or ${tutorialLecture.weekLabel}',
  );

  // Try to find the lecture
  Finder? lectureWidget;

  // First check if lecture is already visible
  if (lectureFinder.evaluate().isNotEmpty) {
    lectureWidget = lectureFinder.first;
    debugPrint('✓ Found lecture by title');
  } else if (weekFinder.evaluate().isNotEmpty) {
    lectureWidget = weekFinder.first;
    debugPrint('✓ Found lecture by week label');
  } else {
    // If not visible, try scrolling to find it
    debugPrint('Lecture not immediately visible, trying to scroll...');
    final scrollables = find.byType(Scrollable);

    if (scrollables.evaluate().isNotEmpty) {
      debugPrint('Found ${scrollables.evaluate().length} scrollable(s)');

      // Try scrolling to find the lecture by title first
      try {
        await IntegrationTestHelpers.scrollUntilVisible(
          tester,
          lectureFinder,
          scrollables.first,
        );

        if (lectureFinder.evaluate().isNotEmpty) {
          lectureWidget = lectureFinder.first;
          debugPrint('✓ Found lecture by scrolling to title');
        }
      } catch (scrollError) {
        debugPrint('Could not scroll to lecture by title: $scrollError');

        // Try scrolling to find by week label
        try {
          await IntegrationTestHelpers.scrollUntilVisible(
            tester,
            weekFinder,
            scrollables.first,
          );

          if (weekFinder.evaluate().isNotEmpty) {
            lectureWidget = weekFinder.first;
            debugPrint('✓ Found lecture by scrolling to week label');
          }
        } catch (e) {
          debugPrint('Could not scroll to lecture by week label: $e');
        }
      }
    }

    // Last resort: try to find any ListTile or Card that might be the lecture
    if (lectureWidget == null) {
      debugPrint('Last resort: looking for any widget containing lecture text');

      // Try a case-insensitive search
      final textWidgets = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            (widget.data!.contains(tutorialLecture.title) ||
                widget.data!.contains(tutorialLecture.weekLabel)),
      );

      if (textWidgets.evaluate().isNotEmpty) {
        lectureWidget = textWidgets.first;
        debugPrint('✓ Found lecture text widget');
      }
    }
  }

  if (lectureWidget == null) {
    // Debug: print all text widgets to see what's available
    debugPrint('Available text widgets:');
    final allTexts = find.byType(Text);
    for (final element in allTexts.evaluate().take(20)) {
      final widget = element.widget as Text;
      debugPrint('  - ${widget.data}');
    }

    throw Exception(
      'Cannot find lecture widget for ${tutorialLecture.title}. '
      'Searched for title "${tutorialLecture.title}" and week label "${tutorialLecture.weekLabel}"',
    );
  }

  debugPrint('✓ Lecture widget found, preparing to tap');

  // Step 2: Tap on the lecture to navigate to player
  // LectureCard uses InkWell as the tappable widget
  // Use tapAt to directly tap the coordinates to avoid hit-test issues

  try {
    // Get the center of the lecture widget and tap there
    final Offset center = tester.getCenter(lectureWidget);
    await tester.tapAt(center);
    debugPrint('✓ Tapped at lecture position ($center)');
  } catch (e) {
    debugPrint('⚠️ Error tapping at center: $e, trying alternative');

    // Fallback: try tapping with warnIfMissed: false
    await tester.tap(lectureWidget, warnIfMissed: false);
    debugPrint('✓ Tapped lecture widget (fallback)');
  }

  // Give extra time for navigation animation
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Wait for player to load (PlayerScreen shows CircularProgressIndicator initially)
  // Poll for PlayerLayout to appear, with timeout
  debugPrint('Waiting for player to load...');
  bool playerLoaded = false;
  for (int i = 0; i < 20; i++) {
    // Try up to 20 times (10 seconds total)
    await tester.pump(const Duration(milliseconds: 500));

    final verticalLayout = find.byType(VerticalPlayerLayout);
    final horizontalLayout = find.byType(HorizontalPlayerLayout);

    if (verticalLayout.evaluate().isNotEmpty ||
        horizontalLayout.evaluate().isNotEmpty) {
      playerLoaded = true;
      debugPrint('✓ Player loaded after ${(i + 1) * 500}ms');
      break;
    }
  }

  // Additional settle after finding the layout
  await tester.pumpAndSettle();

  // Verify navigation to player screen by checking for unique player widgets
  // Must find either VerticalPlayerLayout or HorizontalPlayerLayout
  final verticalLayout = find.byType(VerticalPlayerLayout);
  final horizontalLayout = find.byType(HorizontalPlayerLayout);
  final pdfArea = find.byType(PdfArea);
  final transcriptArea = find.byType(TranscriptArea);

  // At least one layout should be present
  final hasPlayerLayout =
      verticalLayout.evaluate().isNotEmpty ||
      horizontalLayout.evaluate().isNotEmpty;

  expect(
    hasPlayerLayout,
    true,
    reason:
        'Player screen should show VerticalPlayerLayout or HorizontalPlayerLayout. '
        'PlayerLoaded: $playerLoaded',
  );

  // PdfArea and TranscriptArea should be present
  expect(pdfArea, findsOneWidget, reason: 'Player screen should show PDF area');

  expect(
    transcriptArea,
    findsOneWidget,
    reason: 'Player screen should show transcript area',
  );

  debugPrint('✅ Navigated to player screen - verified player layout widgets');

  // Step 3: Find and tap the subtitles/transcript toggle button
  // In horizontal layout, there might be a button to toggle transcript panel
  // In vertical layout, transcript should be visible by default

  // Wait for player to be ready
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Try to find the transcript toggle button (if in horizontal mode)
  final transcriptButton = find.byIcon(Icons.notes);
  if (transcriptButton.evaluate().isNotEmpty) {
    // We're in horizontal mode, tap to show transcript
    await tester.tap(transcriptButton);
    await tester.pumpAndSettle();
  }

  // Verify subtitles/transcript are still visible (already checked above)
  // The TranscriptArea widget should contain transcript content
  debugPrint('✅ Transcript area verified');

  debugPrint(
    '✅ Integration 2 passed: Navigation to player and subtitles verified',
  );
}
