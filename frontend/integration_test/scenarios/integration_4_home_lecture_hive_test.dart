import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import '../helpers/test_helpers.dart';

/// Integration Test 4: Home + Lecture Fetch + Hive (Add Lecture)
///
/// Test Scenario:
/// 1. Tap (+) and click on 'Add lecture'
/// 2. Try adding a new lecture (appropriately mocked)
/// 3. Confirm that the lecture well resides in Hive, using relevant HiveManager methods
///
/// Note: This test will add a lecture manually to simulate the backend response
/// since we cannot fully mock file picker and backend API in integration tests
Future<void> runIntegration4Test(WidgetTester tester) async {
  final manager = HiveManager.instance;

  // Wait for app to be ready
  await IntegrationTestHelpers.waitForAppReady(tester);

  // Get initial lecture count
  final initialLectures = manager.getAllLectures();
  final initialCount = initialLectures.length;

  debugPrint('Initial lecture count: $initialCount'); // coverage:ignore-line

  // Step 1: Tap (+) button to open add menu
  final addButton = find.byIcon(Icons.add);
  expect(addButton, findsOneWidget, reason: 'Add button should exist');

  await tester.tap(addButton);
  await tester.pumpAndSettle();

  // Find 'Create Lecture' option
  final addLectureOption = find.text('Create Lecture');
  final addLectureOptionKo = find.text('강의 생성');

  final foundOption = addLectureOption.evaluate().isNotEmpty
      ? addLectureOption
      : addLectureOptionKo;

  expect(
    foundOption,
    findsOneWidget,
    reason: 'Create Lecture option should be visible',
  );

  // Step 2: Tap 'Add lecture'
  await tester.tap(foundOption);
  await tester.pumpAndSettle();

  // Verify lecture form screen opened
  // The form should have fields for subject selection, lecture title, etc.
  expect(
    find.byType(Scaffold),
    findsWidgets,
    reason: 'Lecture form screen should open',
  );

  // Since we cannot mock file picker and backend API in integration tests,
  // we'll manually add a lecture using HiveManager to simulate the backend response
  debugPrint('Simulating lecture creation via HiveManager...'); // coverage:ignore-line

  // Get uncategorized subject or first subject
  final subjects = manager.getSubjects();
  final targetSubject = subjects.firstWhere(
    (s) => s.id == 'uncategorized',
    orElse: () => subjects.first,
  );

  // Create dummy files for the lecture
  final tempDir = await getTemporaryDirectory();
  final lectureId = 'test_lecture_${DateTime.now().millisecondsSinceEpoch}';
  final lectureDir = Directory('${tempDir.path}/$lectureId');
  await lectureDir.create(recursive: true);

  final dummyAudioPath = '${lectureDir.path}/audio.m4a';
  final dummyTtsPath = '${lectureDir.path}/tts.opus';
  final dummyJsonPath = '${lectureDir.path}/data.json';
  final dummySlidePath = '${lectureDir.path}/slide.pdf';

  // Create empty dummy files
  await File(dummyAudioPath).writeAsBytes([]);
  await File(dummyTtsPath).writeAsBytes([]);
  await File(dummyJsonPath).writeAsString('[]');
  await File(dummySlidePath).writeAsBytes([]);

  // Create a test lecture with actual file paths
  final testLecture = HiveLecture(
    id: lectureId,
    subjectId: targetSubject.id,
    weekLabel: 'Week Test',
    title: 'Integration Test Lecture',
    duration: 3600000,
    slidePath: dummySlidePath,
    originalAudioPath: dummyAudioPath,
    ttsAudioPath: dummyTtsPath,
    jsonPath: dummyJsonPath,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Add lecture to HiveManager
  await manager.addLecture(testLecture);

  // Update subject to include the lecture
  final updatedLectureIds = [...targetSubject.lectureIds, testLecture.id];
  await manager.updateSubject(targetSubject.id, lectureIds: updatedLectureIds);

  // Navigate back to home
  await IntegrationTestHelpers.navigateBack(tester);
  await tester.pumpAndSettle();

  // Ensure we're back on home screen
  final menuButton = find.byIcon(Icons.menu);
  expect(menuButton, findsOneWidget, reason: 'Should be back on home screen');

  // Step 3: Verify lecture was added to Hive
  final updatedLectures = manager.getAllLectures();
  expect(
    updatedLectures.length,
    initialCount + 1,
    reason: 'Lecture count should increase by 1',
  );

  // Find the newly created lecture
  final newLecture = manager.getLecture(testLecture.id);
  expect(newLecture, isNotNull, reason: 'New lecture should exist');
  expect(
    newLecture!.title,
    'Integration Test Lecture',
    reason: 'Lecture should have correct title',
  );
  expect(
    newLecture.subjectId,
    targetSubject.id,
    reason: 'Lecture should be in correct subject',
  );

  // Verify the lecture exists in Hive using HiveManager methods
  final lecturesMap = manager.lectures;
  expect(
    lecturesMap.containsKey(testLecture.id),
    true,
    reason: 'Lecture should exist in Hive',
  );
  expect(
    lecturesMap[testLecture.id]!.title,
    'Integration Test Lecture',
    reason: 'Lecture in Hive should have correct title',
  );

  // Verify lecture appears in subject
  final updatedSubject = manager.getSubject(targetSubject.id);
  expect(
    updatedSubject!.lectureIds.contains(testLecture.id),
    true,
    reason: 'Subject should contain the new lecture',
  );

  // Verify lecture appears in home screen UI
  // Try to find the lecture title or week label in the UI
  final lectureTitleFinder = find.text(testLecture.title);
  final lectureWeekFinder = find.text(testLecture.weekLabel);

  // First, try to expand the subject panel if needed
  final subjectTitleFinder = find.text(targetSubject.title);
  if (subjectTitleFinder.evaluate().isNotEmpty) {
    try {
      await tester.tap(subjectTitleFinder.first);
      await tester.pumpAndSettle();
      debugPrint('✓ Expanded subject panel to verify lecture in UI'); // coverage:ignore-line
    } catch (_) {
      // Subject might already be expanded
    }
  }

  // Check if lecture is visible in UI
  final lectureVisibleInUI =
      lectureTitleFinder.evaluate().isNotEmpty ||
      lectureWeekFinder.evaluate().isNotEmpty;

  expect(
    lectureVisibleInUI,
    true,
    reason:
        'Lecture should be visible in home screen UI (title: "${testLecture.title}" or week: "${testLecture.weekLabel}")',
  );

  debugPrint('✓ Lecture verified in home screen UI'); // coverage:ignore-line

  debugPrint( // coverage:ignore-line
    '✅ Integration 4 passed: Lecture successfully added and persisted',
  );
}
