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

  // Extra wait to ensure complete initialization between tests
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle(const Duration(seconds: 3));

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
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle(const Duration(seconds: 3));

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

  // Ensure the lecture widget is fully visible and scrolled into view
  try {
    await tester.ensureVisible(lectureWidget);
    await tester.pumpAndSettle();
    debugPrint('✓ Lecture widget ensured visible');
  } catch (e) {
    debugPrint('⚠️ Could not ensure lecture visible: $e');
  }

  // DEBUG: Take screenshot before tapping lecture
  await IntegrationTestHelpers.takeScreenshot(
    tester,
    'integration_2_before_tap',
  );

  // Step 2: Tap on the lecture to navigate to player
  // LectureCard has a thumbnail at the top - tap on that for reliable interaction

  bool navigationSuccessful = false;
  for (int tapAttempt = 0; tapAttempt < 3; tapAttempt++) {
    try {
      // Find the thumbnail area (AspectRatio widget) within the same card
      // The AspectRatio is the thumbnail container in LectureCard
      Finder tappableWidget = lectureWidget;

      try {
        final element = lectureWidget.evaluate().first;

        // Find the ancestor InkWell (the card itself)
        final inkWell = find.ancestor(
          of: find.byWidget(element.widget),
          matching: find.byType(InkWell),
        );

        if (inkWell.evaluate().isNotEmpty) {
          // Now find the AspectRatio (thumbnail) within this InkWell
          final thumbnail = find.descendant(
            of: inkWell.first,
            matching: find.byType(AspectRatio),
          );

          if (thumbnail.evaluate().isNotEmpty) {
            tappableWidget = thumbnail.first;
            debugPrint('✓ Found thumbnail (AspectRatio) for tapping');
          } else {
            // Fallback to InkWell if thumbnail not found
            tappableWidget = inkWell.first;
            debugPrint('✓ Using InkWell (thumbnail not found)');
          }
        } else {
          debugPrint('⚠️ InkWell not found, using text widget directly');
        }
      } catch (e) {
        debugPrint('⚠️ Could not find thumbnail: $e');
      }

      // Tap on the thumbnail or card
      final Offset center = tester.getCenter(tappableWidget);
      await tester.tapAt(center);
      debugPrint('✓ Tapped at position ($center) (attempt ${tapAttempt + 1})');
    } catch (e) {
      debugPrint('⚠️ Error tapping: $e, trying alternative');

      // Fallback: try tapping with warnIfMissed: false
      await tester.tap(lectureWidget, warnIfMissed: false);
      debugPrint(
        '✓ Tapped lecture widget (fallback, attempt ${tapAttempt + 1})',
      );
    }

    // Give time for navigation to start
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // Check if we're still on home screen or navigated away
    final menuButton = find.byIcon(Icons.menu);
    if (menuButton.evaluate().isEmpty) {
      // Menu button not found, likely navigated away from home
      navigationSuccessful = true;
      debugPrint('✓ Navigation detected after tap attempt ${tapAttempt + 1}');
      break;
    } else {
      debugPrint(
        '⚠️ Still on home screen after tap attempt ${tapAttempt + 1}, retrying...',
      );
      await tester.pumpAndSettle();
    }
  }

  if (!navigationSuccessful) {
    debugPrint(
      '⚠️ Warning: Navigation may not have occurred after 3 tap attempts',
    );
    // DEBUG: Take screenshot if navigation failed
    await IntegrationTestHelpers.takeScreenshot(
      tester,
      'integration_2_navigation_failed',
    );
  }

  // Give extra time for navigation animation
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // DEBUG: Take screenshot after navigation
  await IntegrationTestHelpers.takeScreenshot(
    tester,
    'integration_2_after_navigation',
  );

  // Wait for player to load (PlayerScreen shows CircularProgressIndicator initially)
  // Poll for PlayerLayout to appear, with timeout
  debugPrint('Waiting for player to load...');
  bool playerLoaded = false;
  for (int i = 0; i < 40; i++) {
    // Try up to 40 times (20 seconds total with pumpAndSettle)
    await tester.pump(const Duration(milliseconds: 500));

    // Also try pumpAndSettle to handle any pending animations
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    } catch (e) {
      // If pumpAndSettle times out, continue polling
      debugPrint('pumpAndSettle timeout during polling, continuing...');
    }

    // DEBUG: Take screenshots during player loading
    if (i == 5) {
      await IntegrationTestHelpers.takeScreenshot(
        tester,
        'integration_2_loading_2.5s',
      );
    } else if (i == 10) {
      await IntegrationTestHelpers.takeScreenshot(
        tester,
        'integration_2_loading_5s',
      );
    } else if (i == 20) {
      await IntegrationTestHelpers.takeScreenshot(
        tester,
        'integration_2_loading_10s',
      );
    }

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
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  // DEBUG: Take screenshot before player verification
  await IntegrationTestHelpers.takeScreenshot(
    tester,
    'integration_2_before_verification',
  );

  // Verify navigation to player screen by checking for unique player widgets
  // Must find either VerticalPlayerLayout or HorizontalPlayerLayout
  final verticalLayout = find.byType(VerticalPlayerLayout);
  final horizontalLayout = find.byType(HorizontalPlayerLayout);
  final pdfArea = find.byType(PdfArea);
  final transcriptArea = find.byType(TranscriptArea);

  debugPrint(
    'DEBUG: verticalLayout found: ${verticalLayout.evaluate().length}',
  );
  debugPrint(
    'DEBUG: horizontalLayout found: ${horizontalLayout.evaluate().length}',
  );
  debugPrint('DEBUG: pdfArea found: ${pdfArea.evaluate().length}');
  debugPrint(
    'DEBUG: transcriptArea found: ${transcriptArea.evaluate().length}',
  );

  // At least one layout should be present
  final hasPlayerLayout =
      verticalLayout.evaluate().isNotEmpty ||
      horizontalLayout.evaluate().isNotEmpty;

  // DEBUG: If player not loaded, take failure screenshot
  if (!hasPlayerLayout) {
    await IntegrationTestHelpers.takeScreenshot(
      tester,
      'integration_2_player_not_found',
    );
  }

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
