import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:re_view/main.dart' as app;

import 'helpers/test_helpers.dart';
import 'scenarios/integration_1_home_hive_subject_test.dart';
import 'scenarios/integration_2_home_player_test.dart';
import 'scenarios/integration_3_home_tag_hive_test.dart';
import 'scenarios/integration_4_home_lecture_hive_test.dart';
import 'scenarios/integration_5_home_settings_language_test.dart';
import 'scenarios/integration_6_home_settings_motion_test.dart';
import 'scenarios/integration_7_home_edit_hive_test.dart';
import 'scenarios/integration_8_home_player_extended_test.dart';
import 'scenarios/integration_9_home_filter_tag_theme_test.dart';

/// Main Integration Test Suite
///
/// This file orchestrates all integration tests for the Re:View app.
/// Tests are executed in sequence to ensure proper state management.
///
/// Integration Test Scenarios:
/// 1. Home + Hive: Add subject
/// 2. Home + Player: Tutorial lecture navigation with subtitles
/// 3. Home + Tag + Hive: Add tag
/// 4. Home + Lecture Fetch + Hive: Add lecture
/// 5. Home + Settings: Language change
/// 6. Home + Settings: Reduced motion performance
/// 7. Home (Edit) + Hive: Delete lecture
/// 8. Home + Player: Extended features (double tap skip, language toggle)
/// 9. Home (Filter) + Tag (Theme): Tag filtering and color theme changes
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Re:View Integration Tests', () {
    setUpAll(() async {
      // Initialize Hive for integration tests
      await IntegrationTestHelpers.initializeHive();
    });

    setUp(() async {
      // Clean up Hive between tests to ensure clean state
      await IntegrationTestHelpers.cleanupHive();
      await IntegrationTestHelpers.initializeHive();
    });

    tearDownAll(() async {
      // Cleanup Hive after all tests
      await IntegrationTestHelpers.cleanupHive();
    });

    testWidgets('Integration 1: Home + Hive (Add Subject)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration1Test(tester);
    });

    testWidgets('Integration 2: Home + Player (Tutorial Navigation)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration2Test(tester);
    });

    testWidgets('Integration 3: Home + Tag + Hive (Add Tag)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration3Test(tester);
    });

    testWidgets('Integration 4: Home + Lecture Fetch + Hive (Add Lecture)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration4Test(tester);
    });

    testWidgets('Integration 5: Home + Settings (Language Change)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration5Test(tester);
    });

    testWidgets('Integration 6: Home + Settings (Reduced Motion)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration6Test(tester);
    });

    testWidgets('Integration 7: Home (Edit) + Hive (Delete Lecture)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration7Test(tester);
    });

    testWidgets('Integration 8: Home + Player (Extended Features)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration8Test(tester);
    });

    testWidgets('Integration 9: Home (Filter) + Tag (Theme)', (
      WidgetTester tester,
    ) async {
      // Start app fresh for this test
      app.main();
      await runIntegration9Test(tester);
    });
  });
}
