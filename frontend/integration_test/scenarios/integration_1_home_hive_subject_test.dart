import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/data/hive_manager.dart';
import '../helpers/test_helpers.dart';

/// Integration Test 1: Home + Hive (Add Subject)
///
/// Test Scenario:
/// 1. Tap (+) and click on 'Add subject'
/// 2. Try adding a new subject
/// 3. Confirm that the subject well resides in Hive, using relevant HiveManager methods
Future<void> runIntegration1Test(WidgetTester tester) async {
  final manager = HiveManager.instance;

  // Wait for app to be ready
  await IntegrationTestHelpers.waitForAppReady(tester);

  // Get initial subject count
  final initialSubjects = manager.getSubjects();
  final initialCount = initialSubjects.length;

  debugPrint('Initial subject count: $initialCount');

  // Create a unique subject name using timestamp
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final testSubjectName = 'Test Subject $timestamp';

  // Step 1: Tap (+) button to open add menu
  final addButton = find.byIcon(Icons.add);
  expect(addButton, findsOneWidget, reason: 'Add button should exist');

  await tester.tap(addButton);
  await tester.pump(); // Start the animation

  debugPrint('✓ Tapped add button (+)');

  // Wait for overlay animation to complete (180ms animation + buffer)
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();

  // Verify add menu is open by looking for 'Add Subject' option
  final addSubjectOption = find.text('Add Subject');
  final addSubjectOptionKo = find.text('과목 추가');

  Finder? foundOption;
  if (addSubjectOption.evaluate().isNotEmpty) {
    foundOption = addSubjectOption;
    debugPrint('✓ Found "Add Subject" option');
  } else if (addSubjectOptionKo.evaluate().isNotEmpty) {
    foundOption = addSubjectOptionKo;
    debugPrint('✓ Found "과목 추가" option');
  }

  if (foundOption == null) {
    // Debug: print all visible text widgets
    debugPrint('Available text widgets after tapping add button:');
    final allTexts = find.byType(Text);
    for (final element in allTexts.evaluate().take(20)) {
      final widget = element.widget as Text;
      debugPrint('  - ${widget.data}');
    }
    throw Exception('Add Subject option not found. Searched for "Add Subject" and "과목 추가"');
  }

  // Step 2: Tap 'Add subject'
  await tester.tap(foundOption);
  await tester.pumpAndSettle();

  // Verify dialog opened
  expect(
    find.byType(Dialog),
    findsOneWidget,
    reason: 'Create subject dialog should open',
  );

  // Enter subject title with unique name
  final titleField = find.byType(TextField).first;
  await IntegrationTestHelpers.enterText(tester, titleField, testSubjectName);

  // Find and tap the create/confirm button
  // The actual button uses AppLocalizations.of(context).add which is "Add"/"추가"
  final confirmButton = find.text('Add');
  final confirmButtonKo = find.text('추가');

  if (confirmButton.evaluate().isNotEmpty) {
    await tester.tap(confirmButton);
  } else if (confirmButtonKo.evaluate().isNotEmpty) {
    await tester.tap(confirmButtonKo);
  } else {
    // Try finding by FilledButton type (the actual button type)
    final filledButtons = find.byType(FilledButton);
    if (filledButtons.evaluate().isNotEmpty) {
      await tester.tap(filledButtons.first);
    } else {
      // Fallback to finding by button type
      final buttons = find.byType(TextButton);
      if (buttons.evaluate().length >= 2) {
        // Usually the second button is the confirm button
        await tester.tap(buttons.last);
      }
    }
  }
  await tester.pumpAndSettle();

  // Step 3: Verify subject was added to Hive
  final updatedSubjects = manager.getSubjects();
  expect(
    updatedSubjects.length,
    initialCount + 1,
    reason: 'Subject count should increase by 1',
  );

  // Find the newly created subject
  final newSubject = updatedSubjects.firstWhere(
    (s) => s.title == testSubjectName,
    orElse: () => throw Exception('New subject not found'),
  );

  expect(
    newSubject.title,
    testSubjectName,
    reason: 'Subject should have correct title',
  );
  expect(
    newSubject.lectureIds.isEmpty,
    true,
    reason: 'New subject should have no lectures',
  );

  // Verify the subject exists in Hive using HiveManager methods
  final subjectFromHive = manager.getSubject(newSubject.id);
  expect(subjectFromHive, isNotNull, reason: 'Subject should exist in Hive');
  expect(
    subjectFromHive!.title,
    testSubjectName,
    reason: 'Subject in Hive should have correct title',
  );

  // Verify subject appears in the UI
  expect(
    find.text(testSubjectName),
    findsOneWidget,
    reason: 'Subject should be visible in home screen',
  );

  debugPrint(
    '✅ Integration 1 passed: Subject successfully added and persisted',
  );

  // Clean up: Just settle - navigateToHome will handle comprehensive cleanup
  await tester.pumpAndSettle(const Duration(seconds: 2));
  debugPrint('✓ Integration 1 cleanup complete');
}
