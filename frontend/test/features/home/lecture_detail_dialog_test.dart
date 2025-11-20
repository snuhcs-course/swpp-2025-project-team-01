import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/home/home_widgets.dart';

/// Separate test file for _LectureDetailDialog to avoid cluttering home_widgets_test.dart
void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  late Box<AppData> testBox;
  late Directory testDirectory;

  ThemeData buildTheme() => ThemeData.from(colorScheme: lightScheme).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppHighlights.fromScheme(lightScheme),
    ],
  );

  // Helper function to build dialog with localization support
  Widget buildDialogTest({
    required HiveLecture lecture,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: Scaffold(
        body: Center(
          child: LectureCard(lec: lecture, onTap: (_) {}),
        ),
      ),
    );
  }

  setUpAll(() async {
    testDirectory = Directory.systemTemp.createTempSync('hive_lecture_dialog_');
    await binding.runAsync(() async {
      Hive.init(testDirectory.path);

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

      testBox = await Hive.openBox<AppData>('app_data');
    });
  });

  tearDownAll(() async {
    try {
      if (testDirectory.existsSync()) {
        testDirectory.deleteSync(recursive: true);
      }
    } catch (e) {
      // Ignore Windows file lock issues
    }
  });

  setUp(() async {
    await binding.runAsync(() async {
      await testBox.clear();
      await testBox.put('main', AppData());
      await HiveManager.instance.initForTesting(testBox);
    });
  });

  group('_LectureDetailDialog', () {
    group('Rendering', () {
      testWidgets('displays dialog with correct header title in English', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test Lecture',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        // Long press to show detail dialog
        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('Edit Lecture Info'), findsOneWidget);
      });

      testWidgets('displays dialog with correct header title in Korean', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test Lecture',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(
          buildDialogTest(lecture: testLecture, locale: const Locale('ko')),
        );
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('강의 정보 수정'), findsOneWidget);
      });

      testWidgets('pre-fills week label field with lecture data', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 5',
          title: 'Advanced Topics',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('Week 5'), findsWidgets);
      });

      testWidgets('pre-fills title field with lecture data', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Machine Learning Basics',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('Machine Learning Basics'), findsWidgets);
      });

      testWidgets('displays duration in correct format (mm:ss)', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3660000, // 61 minutes = 61:00
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('61:00'), findsOneWidget);
      });

      testWidgets('displays duration with seconds padding', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3665000, // 61 minutes 5 seconds = 61:05
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('61:05'), findsOneWidget);
      });

      testWidgets('displays delete button with correct style', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Find delete button by icon
        final deleteIcon = find.byIcon(Icons.delete_outline);
        expect(deleteIcon, findsOneWidget);

        // Verify the button exists
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('displays complete button', (WidgetTester tester) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('Complete'), findsOneWidget);
      });
    });

    group('Subject Selection', () {
      testWidgets('displays uncategorized with localized text in Korean', (
        WidgetTester tester,
      ) async {
        // Uncategorized subject should exist by default after HiveManager initialization
        final uncategorized = HiveManager.instance.getSubject('uncategorized');

        // Skip test if uncategorized doesn't exist (shouldn't happen but just in case)
        if (uncategorized == null) {
          return;
        }

        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: uncategorized.id,
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(
          buildDialogTest(lecture: testLecture, locale: const Locale('ko')),
        );
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Open dropdown
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        expect(find.text('미분류'), findsWidgets);
      });
    });

    group('Text Editing', () {
      testWidgets('can edit week label field', (WidgetTester tester) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Find the week TextField (first one)
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.first, 'Week 10');
        await tester.pump();

        expect(find.text('Week 10'), findsOneWidget);
      });

      testWidgets('can edit title field', (WidgetTester tester) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Original Title',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Find the title TextField (second one)
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.last, 'New Title');
        await tester.pump();

        expect(find.text('New Title'), findsOneWidget);
      });

      testWidgets('accepts empty week label', (WidgetTester tester) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.first, '');
        await tester.pump();

        // Should accept empty value without error
        expect(find.byType(TextField), findsNWidgets(2));
      });
    });

    group('Delete Action', () {
      testWidgets('clicking delete shows confirmation dialog', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Tap delete button by finding the delete icon
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Warning'), findsOneWidget);
        expect(
          find.textContaining('Are you sure you want to'),
          findsOneWidget,
        );
      });

      testWidgets('confirmation dialog shows Korean text in Korean locale', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(
          buildDialogTest(lecture: testLecture, locale: const Locale('ko')),
        );
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Tap delete button by finding the delete icon
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Should show Korean text
        expect(find.text('경고'), findsOneWidget);
        expect(find.textContaining('이 강의를 삭제하시겠습니까?'), findsOneWidget);
      });

      testWidgets('cancel in confirmation keeps both dialogs open', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Tap delete button by finding the delete icon
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Tap No button
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        // Main dialog should still be visible
        expect(find.text('Edit Lecture Info'), findsOneWidget);
        // Confirmation dialog should be closed
        expect(find.text('Warning'), findsNothing);
      });
    });
    group('Edge Cases', () {
      testWidgets('handles zero duration formatting', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 0,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('0:00'), findsOneWidget);
      });

      testWidgets('handles large duration formatting', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 60000000, // 1000 minutes
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        expect(find.text('1000:00'), findsOneWidget);
      });

      testWidgets('handles very long text in fields', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(buildDialogTest(lecture: testLecture));
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        final longText = 'A' * 200;
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.first, longText);
        await tester.pump();

        // Should accept long text without error
        expect(find.text(longText), findsOneWidget);
      });
    });

    group('Localization', () {
      testWidgets('displays all Korean text in Korean locale', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(
          buildDialogTest(lecture: testLecture, locale: const Locale('ko')),
        );
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Key Korean strings
        expect(find.text('강의 정보 수정'), findsOneWidget);
        expect(find.text('과목'), findsOneWidget);
        expect(find.text('주차'), findsOneWidget);
        expect(find.text('강의 제목'), findsOneWidget);
        expect(find.text('강의 길이'), findsOneWidget);
        expect(find.text('삭제'), findsOneWidget);
        expect(find.text('완료'), findsOneWidget);
      });

      testWidgets('displays all English text in English locale', (
        WidgetTester tester,
      ) async {
        final testLecture = HiveLecture(
          id: 'test-lec',
          subjectId: 'subject-1',
          weekLabel: 'Week 1',
          title: 'Test',
          duration: 3600000,
          originalAudioPath: 'test.m4a',
          ttsAudioPath: 'test.opus',
        );

        await tester.pumpWidget(
          buildDialogTest(lecture: testLecture, locale: const Locale('en')),
        );
        await tester.pump();

        await tester.longPress(find.byType(LectureCard));
        await tester.pumpAndSettle();

        // Key English strings
        expect(find.text('Edit Lecture Info'), findsOneWidget);
        expect(find.text('Subject'), findsOneWidget);
        expect(find.text('Week'), findsOneWidget);
        expect(find.text('Lecture Title'), findsOneWidget);
        expect(find.text('Lecture Length'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
      });
    });
  });
}
