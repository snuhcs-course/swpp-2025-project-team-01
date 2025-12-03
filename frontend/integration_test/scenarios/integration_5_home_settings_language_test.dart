import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/data/hive_manager.dart';
import '../helpers/test_helpers.dart';

/// Integration Test 5: Home + Settings (Language Change)
///
/// Test Scenario:
/// 1. Navigate to settings screen from home
/// 2. Navigate to language screen and change language
/// 3. Return to home screen, and confirm the language change is applied
Future<void> runIntegration5Test(WidgetTester tester) async {
  final manager = HiveManager.instance;

  // Wait for app to be ready
  await IntegrationTestHelpers.waitForAppReady(tester);

  // Get initial language
  final initialLanguage = manager.settings.language;
  debugPrint('Initial language: $initialLanguage'); // coverage:ignore-line

  // Determine target language (switch to the opposite)
  final targetLanguage = initialLanguage == 'ko' ? 'en' : 'ko';

  // Step 1: Navigate to settings screen from home
  // Open drawer/menu
  final menuButton = find.byIcon(Icons.menu);
  expect(menuButton, findsOneWidget, reason: 'Menu button should exist');

  await tester.tap(menuButton);
  await tester.pumpAndSettle();

  // Find and tap "Settings" option
  final settingsOption = find.text('Settings');
  final settingsOptionKo = find.text('설정');

  Finder foundSettingsOption;
  if (settingsOption.evaluate().isNotEmpty) {
    foundSettingsOption = settingsOption;
  } else if (settingsOptionKo.evaluate().isNotEmpty) {
    foundSettingsOption = settingsOptionKo;
  } else {
    // Try to find by ListTile
    final listTiles = find.byType(ListTile);
    // Settings is usually one of the last options
    foundSettingsOption = listTiles.last;
  }

  await tester.tap(foundSettingsOption);
  await tester.pumpAndSettle();

  // Step 2: Navigate to language screen
  final languageOption = find.text('Language');
  final languageOptionKo = find.text('언어');

  Finder foundLanguageOption;
  if (languageOption.evaluate().isNotEmpty) {
    foundLanguageOption = languageOption;
  } else if (languageOptionKo.evaluate().isNotEmpty) {
    foundLanguageOption = languageOptionKo;
  } else {
    // Try to find by ListTile
    final listTiles = find.byType(ListTile);
    // Language option is usually in the settings list
    foundLanguageOption = listTiles.at(3); // Adjust based on actual position
  }

  await tester.tap(foundLanguageOption);
  await tester.pumpAndSettle();

  // Change language
  // Find the radio button for target language
  final targetLangRadio = targetLanguage == 'en'
      ? find.text('English')
      : find.text('한국어');

  expect(
    targetLangRadio,
    findsOneWidget,
    reason: 'Target language option should exist',
  );

  await tester.tap(targetLangRadio);
  await tester.pumpAndSettle();

  // Verify language changed in HiveManager
  expect(
    manager.settings.language,
    targetLanguage,
    reason: 'Language should be updated in HiveManager',
  );

  // Step 3: Navigate back to home and verify language change
  await IntegrationTestHelpers.navigateBack(tester);
  await tester.pumpAndSettle();

  // Navigate back to home from settings
  await IntegrationTestHelpers.navigateBack(tester);
  await tester.pumpAndSettle();

  // Close drawer if open
  if (find.byType(Drawer).evaluate().isNotEmpty) {
    await tester.tap(find.byType(Scaffold).first);
    await tester.pumpAndSettle();
  }

  // Verify language change is applied in UI
  // Check for language-specific text in the app
  if (targetLanguage == 'en') {
    // Should see English text
    final reviewText = find.textContaining('Re:View');
    final filterText = find.textContaining('Filter');
    final hasEnglishText =
        reviewText.evaluate().isNotEmpty || filterText.evaluate().isNotEmpty;
    expect(hasEnglishText, true, reason: 'English text should be visible');
  } else {
    // Should see Korean text
    final filterTextKo = find.textContaining('필터');
    final editTextKo = find.textContaining('편집');
    final hasKoreanText =
        filterTextKo.evaluate().isNotEmpty || editTextKo.evaluate().isNotEmpty;
    expect(hasKoreanText, true, reason: 'Korean text should be visible');
  }

  debugPrint('✅ Integration 5 passed: Language changed to $targetLanguage'); // coverage:ignore-line

  // Restore original language for other tests
  await manager.updateLanguage(initialLanguage);
  await tester.pumpAndSettle();
}
