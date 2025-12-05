import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/home/home_widgets.dart';
import '../helpers/test_helpers.dart';

/// Integration Test 3: Home + Tag + Hive (Add Tag)
///
/// Test Scenario:
/// 1. Navigate to tag screen from home
/// 2. Try adding a new tag
/// 3. Confirm that the tag well resides in Hive, using relevant HiveManager methods
Future<void> runIntegration3Test(WidgetTester tester) async {
  final manager = HiveManager.instance;

  // Wait for app to be ready
  await IntegrationTestHelpers.waitForAppReady(tester);

  // Get initial tag count
  final initialTags = manager.getTags();
  final initialCount = initialTags.length;

  debugPrint('Initial tag count: $initialCount'); // coverage:ignore-line

  // Step 1: Navigate to tag screen from home
  // Open drawer/menu
  final menuButton = find.byIcon(Icons.menu);
  expect(menuButton, findsOneWidget, reason: 'Menu button should exist');

  await tester.tap(menuButton);
  await tester.pumpAndSettle();

  // Find and tap "Manage Subjects & Tags" or similar option
  final manageOption = find.text('Manage Subjects & Tags');
  final manageOptionKo = find.text('과목 및 태그 관리');

  Finder foundManageOption;
  if (manageOption.evaluate().isNotEmpty) {
    foundManageOption = manageOption;
  } else if (manageOptionKo.evaluate().isNotEmpty) {
    foundManageOption = manageOptionKo;
  } else {
    // Try to find by icon or widget type
    final listTiles = find.byType(ListTile);
    // Usually it's one of the list tiles in the drawer
    foundManageOption = listTiles.at(1); // Adjust index as needed
  }

  await tester.tap(foundManageOption);
  await tester.pumpAndSettle();

  // Navigate to tags tab
  final tagsTab = find.text('Tags');
  final tagsTabKo = find.text('태그');

  if (tagsTab.evaluate().isNotEmpty) {
    await tester.tap(tagsTab);
  } else if (tagsTabKo.evaluate().isNotEmpty) {
    await tester.tap(tagsTabKo);
  } else {
    // Try to find tab by type
    final tabs = find.byType(Tab);
    if (tabs.evaluate().length >= 2) {
      await tester.tap(tabs.last);
    }
  }
  await tester.pumpAndSettle();

  // Step 2: Add a new tag
  // Tags are added by tapping an ActionChip with '+' label (not a dialog)
  final addTagChip = find.text('+');
  expect(addTagChip, findsOneWidget, reason: 'Add tag chip should exist');

  // Tap the '+' chip to add a new tag
  await tester.tap(addTagChip);
  await tester.pumpAndSettle();

  // The tag is created immediately with a default name
  // Now we need to edit the name in the TextField
  final tagNameField = find.byType(TextField).first;
  await IntegrationTestHelpers.enterText(
    tester,
    tagNameField,
    'Integration Test Tag',
  );

  // Find and tap the apply button (nameApply in AppLocalizations)
  // The actual button uses AppLocalizations.of(context).nameApply
  final applyButton = find.text('Apply');
  final applyButtonKo = find.text('적용');

  if (applyButton.evaluate().isNotEmpty) {
    await tester.tap(applyButton);
  } else if (applyButtonKo.evaluate().isNotEmpty) {
    await tester.tap(applyButtonKo);
  } else {
    // Try finding by FilledButton type
    final filledButtons = find.byType(FilledButton);
    if (filledButtons.evaluate().isNotEmpty) {
      // The first FilledButton is the apply button
      await tester.tap(filledButtons.first);
    }
  }
  await tester.pumpAndSettle();

  // Navigate back to save tags to Hive
  // Tags are only saved when navigating back from the tag edit screen
  debugPrint('Navigating back to save tags...'); // coverage:ignore-line
  await IntegrationTestHelpers.navigateBack(tester);
  await tester.pumpAndSettle();

  // Navigate back to home from manage screen
  await IntegrationTestHelpers.navigateBack(tester);
  await tester.pumpAndSettle();

  // Step 3: Verify tag was added to Hive
  final updatedTags = manager.getTags();
  expect(
    updatedTags.length,
    initialCount + 1,
    reason: 'Tag count should increase by 1',
  );

  // Find the newly created tag
  final newTag = updatedTags.firstWhere(
    (t) => t.name == 'Integration Test Tag',
    orElse: () => throw Exception('New tag not found'),
  );

  expect(
    newTag.name,
    'Integration Test Tag',
    reason: 'Tag should have correct name',
  );

  // Verify the tag exists in Hive using HiveManager methods
  final tagsMap = manager.tags;
  expect(
    tagsMap.containsKey(newTag.id),
    true,
    reason: 'Tag should exist in Hive',
  );
  expect(
    tagsMap[newTag.id]!.name,
    'Integration Test Tag',
    reason: 'Tag in Hive should have correct name',
  );

  debugPrint('✓ Tag verified in Hive'); // coverage:ignore-line

  // Step 4: Verify tag is visible in UI by opening filter pill
  // Verify we're on home screen
  final menuButtonOnHome = find.byIcon(Icons.menu);
  expect(
    menuButtonOnHome,
    findsOneWidget,
    reason: 'Should be back on home screen',
  );

  // Tap filter pill to show tags
  final filterPill = find.byWidgetPredicate((widget) => widget is FilterPill);

  expect(filterPill, findsOneWidget, reason: 'Filter pill should be visible');

  await tester.tap(filterPill);
  await tester.pumpAndSettle();

  debugPrint('✓ Tapped filter pill to show tags'); // coverage:ignore-line

  // Look for the newly created tag in the UI
  // Try multiple approaches to find the tag
  Finder? tagInUI = find.text('Integration Test Tag');

  if (tagInUI.evaluate().isEmpty) {
    // Try with textContaining
    tagInUI = find.textContaining('Integration Test Tag');
  }

  if (tagInUI.evaluate().isEmpty) {
    // Try to find by checking all Text widgets
    tagInUI = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.contains('Integration Test Tag'),
    );
  }

  if (tagInUI.evaluate().isEmpty) {
    // Debug: print all visible text widgets
    debugPrint(
      'Available text widgets in filter area:',
    ); // coverage:ignore-line
    final allTexts = find.byType(Text);
    for (final element in allTexts.evaluate().take(30)) {
      final widget = element.widget as Text;
      debugPrint('  - ${widget.data}'); // coverage:ignore-line
    }
  }

  expect(
    tagInUI.evaluate().isNotEmpty,
    true,
    reason: 'Newly created tag should be visible in filter pills',
  );

  debugPrint('✓ Tag verified in UI'); // coverage:ignore-line

  // Close filter pill
  await tester.tap(filterPill);
  await tester.pumpAndSettle();

  debugPrint(
    // coverage:ignore-line
    '✅ Integration 3 passed: Tag successfully added, persisted, and visible in UI',
  );
}
