import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';

/// Integration test helper functions and utilities
class IntegrationTestHelpers {
  /// Initialize Hive for integration tests
  static Future<void> initializeHive() async {
    final tempDir = await Directory.systemTemp.createTemp('integration_test');
    Hive.init(tempDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UiStateAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HiveSubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HiveTagAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(HiveLectureAdapter());
    }
  }

  /// Clean up Hive after tests
  static Future<void> cleanupHive() async {
    await HiveManager.instance.close();
    await Hive.close();
    await Hive.deleteFromDisk();
  }

  /// Wait for app to be ready (HiveManager initialized)
  static Future<void> waitForAppReady(WidgetTester tester) async {
    debugPrint('⏳ Waiting for app to be ready...'); // coverage:ignore-line

    // Initial pump to start the app (longer timeout for slower devices)
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // Wait for splash screen to disappear and home screen to appear
    // Look for home screen indicators (menu button, add button, etc.)
    int splashAttempts = 0;
    bool homeScreenFound = false;

    while (splashAttempts < 100 && !homeScreenFound) {
      await tester.pump(const Duration(milliseconds: 100));

      // Check if we're on the home screen
      final menuButton = find.byIcon(Icons.menu);
      final addButton = find.byIcon(Icons.add);

      if (menuButton.evaluate().isNotEmpty || addButton.evaluate().isNotEmpty) {
        homeScreenFound = true;
        debugPrint('✓ Home screen detected after ${splashAttempts * 100}ms'); // coverage:ignore-line
        break;
      }

      // Debug every 2 seconds
      if (splashAttempts % 20 == 0 && splashAttempts > 0) {
        debugPrint( // coverage:ignore-line
          'Still waiting for home screen... (${splashAttempts * 100}ms)',
        );
      }

      splashAttempts++;
    }

    if (!homeScreenFound) {
      debugPrint('⚠️ Home screen not found after ${splashAttempts * 100}ms'); // coverage:ignore-line
    }

    // Additional settling time after splash screen
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Wait for HiveManager to initialize
    int hiveAttempts = 0;
    while (!HiveManager.instance.isInitialized && hiveAttempts < 100) {
      await tester.pump(const Duration(milliseconds: 100));
      hiveAttempts++;
    }

    expect(
      HiveManager.instance.isInitialized,
      true,
      reason: 'HiveManager should be initialized after ${hiveAttempts * 100}ms',
    );

    debugPrint('✓ HiveManager initialized after ${hiveAttempts * 100}ms'); // coverage:ignore-line

    // Final settling to ensure all widgets are ready
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Extra wait to ensure everything is fully loaded
    await Future.delayed(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify home screen is actually showing
    final menuButton = find.byIcon(Icons.menu);
    expect(
      menuButton,
      findsAtLeastNWidgets(1),
      reason: 'Home screen should be visible',
    );

    debugPrint('✅ App is ready - all systems initialized'); // coverage:ignore-line
  }

  /// Tap on a widget by key
  static Future<void> tapByKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  /// Tap on a widget by icon
  static Future<void> tapByIcon(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }

  /// Tap on a widget by text
  static Future<void> tapByText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// Enter text into a text field
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100,
    int maxScrolls = 50,
  }) async {
    int scrolls = 0;
    while (scrolls < maxScrolls) {
      try {
        await tester.ensureVisible(finder);
        break;
      } catch (_) {
        await tester.drag(scrollable, Offset(0, -delta));
        await tester.pumpAndSettle();
        scrolls++;
      }
    }
  }

  /// Wait for a specific duration
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// Find text containing a substring (case insensitive)
  static Finder findTextContaining(String substring) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.toLowerCase().contains(substring.toLowerCase()),
    );
  }

  /// Navigate back
  static Future<void> navigateBack(WidgetTester tester) async {
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      // Try to find back button by icon
      final iconBackButton = find.byIcon(Icons.arrow_back);
      if (iconBackButton.evaluate().isNotEmpty) {
        await tester.tap(iconBackButton.first);
      }
    }
    await tester.pumpAndSettle();
  }

  /// Navigate to home screen (for test isolation)
  static Future<void> navigateToHome(WidgetTester tester) async {
    debugPrint('🏠 Navigating to home screen...'); // coverage:ignore-line

    // Initial pump to ensure any pending animations complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Close any open overlays by tapping multiple areas of the screen
    // The AddPill menu uses an overlay with a barrier that closes on tap
    for (int i = 0; i < 5; i++) {
      try {
        final scaffolds = find.byType(Scaffold);
        if (scaffolds.evaluate().isNotEmpty) {
          final size = tester.getSize(scaffolds.first);
          // Tap different areas to ensure we hit any barrier
          await tester.tapAt(Offset(size.width / 2, size.height / 2));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tapAt(Offset(size.width / 2, 100));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tapAt(Offset(50, 50));
          await tester.pump(const Duration(milliseconds: 100));
        }
      } catch (e) {
        debugPrint('Tap to close overlay attempt $i failed: $e'); // coverage:ignore-line
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }

    // Wait for any overlay close animations
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Close any open dialogs
    int dialogAttempts = 0;
    while (dialogAttempts < 5) {
      final dialogCount = find.byType(Dialog).evaluate().length;
      if (dialogCount == 0) {
        break;
      }

      debugPrint('Closing $dialogCount open dialog(s)...'); // coverage:ignore-line
      try {
        final navigators = find.byType(Navigator);
        if (navigators.evaluate().isNotEmpty) {
          final NavigatorState navigator = tester.state(navigators.first);
          if (navigator.canPop()) {
            navigator.pop();
            await tester.pumpAndSettle();
          }
        }
      } catch (e) {
        debugPrint('Could not close dialog via Navigator: $e'); // coverage:ignore-line
        break;
      }
      dialogAttempts++;
    }

    // Close any open drawers
    final drawer = find.byType(Drawer);
    if (drawer.evaluate().isNotEmpty) {
      debugPrint('Closing open drawer...'); // coverage:ignore-line
      try {
        final scaffolds = find.byType(Scaffold);
        if (scaffolds.evaluate().isNotEmpty) {
          final size = tester.getSize(scaffolds.first);
          await tester.tapAt(Offset(size.width / 2, 100));
          await tester.pumpAndSettle();
        }
      } catch (e) {
        debugPrint('Could not close drawer: $e'); // coverage:ignore-line
      }
    }

    // Navigate back to home screen if we're on a different screen
    int attempts = 0;
    while (attempts < 20) {
      await tester.pumpAndSettle();

      final menuButton = find.byIcon(Icons.menu);
      final addButton = find.byIcon(Icons.add);
      final searchButton = find.byIcon(Icons.search);

      // If we see home screen indicators, we're done
      if (menuButton.evaluate().isNotEmpty &&
          (addButton.evaluate().isNotEmpty ||
              searchButton.evaluate().isNotEmpty)) {
        debugPrint('✓ On home screen (attempt $attempts)'); // coverage:ignore-line
        break;
      }

      // Try to go back
      final backButton = find.byTooltip('Back');
      final iconBackButton = find.byIcon(Icons.arrow_back);

      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        debugPrint('Tapped back button (tooltip)'); // coverage:ignore-line
      } else if (iconBackButton.evaluate().isNotEmpty) {
        await tester.tap(iconBackButton.first);
        await tester.pumpAndSettle();
        debugPrint('Tapped back button (icon)'); // coverage:ignore-line
      } else {
        // Try Navigator.pop()
        bool poppedViaNavigator = false;
        try {
          final navigators = find.byType(Navigator);
          if (navigators.evaluate().isNotEmpty) {
            final NavigatorState navigator = tester.state(navigators.first);
            if (navigator.canPop()) {
              navigator.pop();
              await tester.pumpAndSettle();
              debugPrint('Used Navigator.pop()'); // coverage:ignore-line
              poppedViaNavigator = true;
            }
          }
        } catch (e) {
          debugPrint('Navigator.pop() failed: $e'); // coverage:ignore-line
        }

        if (!poppedViaNavigator) {
          // After several attempts with no back button, assume we're at home
          if (attempts > 5) {
            debugPrint('No back button found, assuming we are at home'); // coverage:ignore-line
            break;
          }
        }
      }

      attempts++;
    }

    // Final settling
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify we're actually on home screen
    final menuButton = find.byIcon(Icons.menu);

    if (menuButton.evaluate().isEmpty) {
      debugPrint( // coverage:ignore-line
        '⚠️ Warning: Could not verify home screen - menu button not found',
      );

      // Debug: print visible icon buttons to understand what's on screen
      debugPrint('Visible icon buttons:'); // coverage:ignore-line
      final iconButtons = find.byType(IconButton);
      for (final element in iconButtons.evaluate().take(10)) {
        final iconButton = element.widget as IconButton;
        if (iconButton.icon is Icon) {
          final icon = iconButton.icon as Icon;
          debugPrint('  - Icon: ${icon.icon}'); // coverage:ignore-line
        }
      }

      // Debug: check if scaffold exists
      final scaffolds = find.byType(Scaffold);
      debugPrint('Scaffold count: ${scaffolds.evaluate().length}'); // coverage:ignore-line

      // Debug: check for common home screen widgets
      final appBars = find.byType(AppBar);
      debugPrint('AppBar count: ${appBars.evaluate().length}'); // coverage:ignore-line
    } else {
      debugPrint('✓ Successfully navigated to home screen'); // coverage:ignore-line
    }
  }

  /// Setup initial test data (subjects, lectures, tags)
  static Future<void> setupInitialTestData(WidgetTester tester) async {
    final manager = HiveManager.instance;
    debugPrint('📦 Setting up initial test data...'); // coverage:ignore-line

    // Create dummy files directory
    final tempDir = await getTemporaryDirectory();
    final testDataDir = Directory('${tempDir.path}/test_data');
    await testDataDir.create(recursive: true);

    // Create 2 test subjects with lectures
    final subjects = manager.getSubjects();
    final existingSubjectCount = subjects
        .where((s) => !s.isUncategorized)
        .length;

    if (existingSubjectCount < 2) {
      // Create test subject 1
      await manager.createSubject('Test Subject 1', []);
      final subject1 = manager.getSubjects().firstWhere(
        (s) => s.title == 'Test Subject 1',
      );
      debugPrint('✓ Created Test Subject 1: ${subject1.id}'); // coverage:ignore-line

      // Create lectures for subject 1
      final lectureIds = <String>[];
      for (int i = 1; i <= 2; i++) {
        final lectureId = 'test_lec_${subject1.id}_$i';
        final lectureDir = Directory('${testDataDir.path}/$lectureId');
        await lectureDir.create(recursive: true);

        // Create dummy files
        await File('${lectureDir.path}/audio.m4a').writeAsBytes([]);
        await File('${lectureDir.path}/tts.opus').writeAsBytes([]);
        await File('${lectureDir.path}/data.json').writeAsString('[]');
        await File('${lectureDir.path}/slide.pdf').writeAsBytes([]);

        final lecture = HiveLecture(
          id: lectureId,
          subjectId: subject1.id,
          weekLabel: 'Week $i',
          title: 'Test Lecture $i',
          duration: 3600000,
          slidePath: '${lectureDir.path}/slide.pdf',
          originalAudioPath: '${lectureDir.path}/audio.m4a',
          ttsAudioPath: '${lectureDir.path}/tts.opus',
          jsonPath: '${lectureDir.path}/data.json',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await manager.addLecture(lecture);
        lectureIds.add(lectureId);
      }

      // Update subject with lectures
      await manager.updateSubject(subject1.id, lectureIds: lectureIds);
      debugPrint('✓ Created 2 lectures for Test Subject 1'); // coverage:ignore-line

      // Create test subject 2
      await manager.createSubject('Test Subject 2', []);
      debugPrint('✓ Created Test Subject 2'); // coverage:ignore-line
    }

    // Ensure we have at least 3 tags
    final existingTags = manager.getTags();
    if (existingTags.length < 3) {
      final tagsToCreate = 3 - existingTags.length;
      final newTags = List<HiveTag>.from(existingTags);
      for (int i = 1; i <= tagsToCreate; i++) {
        final tag = HiveTag(
          id: 'test_tag_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: 'Test Tag $i',
          color: 0xFF0000FF + (i * 0x001100),
        );
        newTags.add(tag);
      }
      await manager.saveTags(newTags);
      debugPrint('✓ Created $tagsToCreate test tags'); // coverage:ignore-line
    }

    await tester.pumpAndSettle();
    debugPrint('✅ Initial test data setup complete'); // coverage:ignore-line
  }

  /// Create a test lecture
  static HiveLecture createTestLecture({
    required String id,
    required String subjectId,
    String weekLabel = 'Week 1',
    String title = 'Test Lecture',
  }) {
    return HiveLecture(
      id: id,
      subjectId: subjectId,
      weekLabel: weekLabel,
      title: title,
      duration: 3600000,
      slidePath: 'test_slide.pdf',
      originalAudioPath: 'test_audio.m4a',
      ttsAudioPath: 'test_tts.opus',
      thumbnailUrl: 'https://example.com/thumbnail.png',
      jsonPath: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a test subject
  static HiveSubject createTestSubject({
    required String id,
    required String title,
    bool favorite = false,
    List<String> tagIds = const [],
    List<String> lectureIds = const [],
  }) {
    return HiveSubject(
      id: id,
      title: title,
      favorite: favorite,
      tagIds: tagIds,
      lectureIds: lectureIds,
    );
  }

  /// Create a test tag
  static HiveTag createTestTag({
    required String id,
    required String name,
    int color = 0xFFEFF0A4,
  }) {
    return HiveTag(id: id, name: name, color: color);
  }

  /// Measure transition time
  static Future<int> measureTransitionTime(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    await action();
    await tester.pumpAndSettle();
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  /// Take a screenshot for debugging
  static Future<void> takeScreenshot(WidgetTester tester, String name) async {
    try {
      // Get the integration test binding
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      await binding.takeScreenshot(name);
      debugPrint('📸 Screenshot saved: $name'); // coverage:ignore-line
    } catch (e) {
      debugPrint('⚠️ Failed to take screenshot "$name": $e'); // coverage:ignore-line
    }
  }
}
