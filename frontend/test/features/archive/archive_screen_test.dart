import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/archive/archive_screen.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/features/home/home_widgets.dart';

import 'package:re_view/shared/widgets.dart';
import 'archive_screen_test.mocks.dart';

@GenerateMocks([HiveManager])
void main() {
  late MockHiveManager mockHiveManager;

  // Helper to pump ArchiveScreen with proper localization & navigator
  Future<void> pumpArchiveScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final theme = ThemeData.from(
      colorScheme: lightScheme,
    ).copyWith(extensions: [AppHighlights.fromScheme(lightScheme)]);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ArchiveScreen(hiveManager: mockHiveManager),
        routes: {
          Routes.player: (_) =>
              const Scaffold(body: Center(child: Text('PlayerScreen'))),
        },
      ),
    );
    await tester.pump();
  }

  setUp(() {
    mockHiveManager = MockHiveManager();
    final settings = AppSettings(
      theme: 'system',
      language: 'en',
      accessibilityHighContrast: false,
      accessibilityReduceMotion: false,
    );

    when(mockHiveManager.getSubjectExpandedState(any)).thenReturn(false);
    when(mockHiveManager.settings).thenReturn(settings);
  });

  group('ArchiveScreen - basic UI', () {
    testWidgets(
      'shows CircularProgressIndicator when HiveManager is not initialized',
      (tester) async {
        when(mockHiveManager.isInitialized).thenReturn(false);

        await pumpArchiveScreen(tester);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(SubjectPanel), findsNothing);
        expect(find.byType(EmptyStateMessage), findsNothing);
      },
    );

    testWidgets('shows EmptyStateMessage when there are no archived subjects', (
      tester,
    ) async {
      when(mockHiveManager.isInitialized).thenReturn(true);
      when(
        mockHiveManager.archivedSubjects,
      ).thenReturn(<String, HiveSubject>{});

      await pumpArchiveScreen(tester);

      expect(find.byType(EmptyStateMessage), findsOneWidget);
      expect(find.byType(SubjectPanel), findsNothing);
    });

    testWidgets(
      'shows SubjectPanels for archived, non-uncategorized subjects only',
      (tester) async {
        when(mockHiveManager.isInitialized).thenReturn(true);

        final sArchived = HiveSubject(
          id: 's1',
          title: 'Archived subject',
          isArchived: true,
          isUncategorized: false,
          lectureIds: ['lec1'],
        );

        final sUnarchived = HiveSubject(
          id: 's2',
          title: 'Not archived',
          isArchived: false,
          isUncategorized: false,
          lectureIds: ['lec2'],
        );

        when(
          mockHiveManager.archivedSubjects,
        ).thenReturn({'s1': sArchived, 's2': sUnarchived});

        when(
          mockHiveManager.getLecturesBySubject(any),
        ).thenReturn(<HiveLecture>[]);

        await pumpArchiveScreen(tester);

        // Only s1 should appear
        final panels = tester.widgetList<SubjectPanel>(
          find.byType(SubjectPanel),
        );
        expect(panels.length, 1);
        expect(panels.first.subject, same(sArchived));
      },
    );

    testWidgets('AppBar back button pops the screen', (tester) async {
      when(mockHiveManager.isInitialized).thenReturn(true);
      when(
        mockHiveManager.archivedSubjects,
      ).thenReturn(<String, HiveSubject>{});

      await pumpArchiveScreen(tester);

      // There should be an AppBar with back icon
      expect(find.byType(AppBar), findsOneWidget);
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });
  });

  group('ArchiveScreen - unarchive dialog', () {
    testWidgets(
      'tapping unarchive callback shows dialog and yes calls unarchiveSubject',
      (tester) async {
        when(mockHiveManager.isInitialized).thenReturn(true);

        final sArchived = HiveSubject(
          id: 's1',
          title: 'Archived subject',
          isArchived: true,
          isUncategorized: false,
          lectureIds: ['lec1'],
        );

        when(mockHiveManager.subjects).thenReturn({'s1': sArchived});
        when(mockHiveManager.archivedSubjects).thenReturn({'s1': sArchived});
        when(
          mockHiveManager.getLecturesBySubject(any),
        ).thenReturn(<HiveLecture>[]);
        when(
          mockHiveManager.unarchiveSubject(any),
        ).thenAnswer((_) async {}); // if async

        await pumpArchiveScreen(tester);

        final subjectPanelFinder = find.byType(SubjectPanel);
        expect(subjectPanelFinder, findsOneWidget);

        final SubjectPanel panel = tester.widget<SubjectPanel>(
          subjectPanelFinder,
        );

        // Trigger the unarchive callback (which opens the dialog)
        panel.onUnarchiveSubject?.call();
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.byType(DeleteWarningDialog), findsOneWidget);

        // Get localization to know the "yes" text
        final BuildContext context = tester.element(
          find.byType(DeleteWarningDialog),
        );
        final l10n = AppLocalizations.of(context);
        final yesFinder = find.text(l10n.yes);

        expect(yesFinder, findsOneWidget);

        // Tap "yes"
        await tester.tap(yesFinder);
        await tester.pumpAndSettle();

        // Verify manager.unarchiveSubject was called
        verify(mockHiveManager.unarchiveSubject('s1')).called(1);
      },
    );
  });

  group('ArchiveScreen - delete dialog', () {
    testWidgets(
      'tapping delete callback shows dialog and yes calls deleteSubject',
      (tester) async {
        when(mockHiveManager.isInitialized).thenReturn(true);

        final sArchived = HiveSubject(
          id: 's1',
          title: 'Archived subject',
          isArchived: true,
          isUncategorized: false,
          lectureIds: ['lec1'],
        );

        when(mockHiveManager.archivedSubjects).thenReturn({'s1': sArchived});
        when(
          mockHiveManager.getLecturesBySubject(any),
        ).thenReturn(<HiveLecture>[]);
        when(mockHiveManager.deleteSubject(any)).thenAnswer((_) async {});

        await pumpArchiveScreen(tester);

        final subjectPanelFinder = find.byType(SubjectPanel);
        expect(subjectPanelFinder, findsOneWidget);

        final SubjectPanel panel = tester.widget<SubjectPanel>(
          subjectPanelFinder,
        );

        // Trigger delete callback (opens dialog)
        panel.onDeleteSubject?.call();
        await tester.pumpAndSettle();

        expect(find.byType(DeleteWarningDialog), findsOneWidget);

        final BuildContext context = tester.element(
          find.byType(DeleteWarningDialog),
        );
        final l10n = AppLocalizations.of(context);

        final yesFinder = find.text(l10n.yes);
        expect(yesFinder, findsOneWidget);

        await tester.tap(yesFinder);
        await tester.pumpAndSettle();

        verify(mockHiveManager.deleteSubject('s1')).called(1);
      },
    );
  });

  group('ArchiveScreen - navigation to player', () {
    testWidgets(
      'onOpenLecture navigates to player route with correct arguments',
      (tester) async {
        when(mockHiveManager.isInitialized).thenReturn(true);

        final sArchived = HiveSubject(
          id: 's1',
          title: 'Archived subject',
          isArchived: true,
          isUncategorized: false,
          lectureIds: ['lec1'],
        );

        final lec = HiveLecture(
          id: 'lec1',
          subjectId: 's1',
          title: 'Archived Lecture',
          weekLabel: 'week 1',
          duration: 10,
          originalAudioPath: '',
          ttsAudioPath: '',
        );

        when(mockHiveManager.subjects).thenReturn({'s1': sArchived});
        when(mockHiveManager.archivedSubjects).thenReturn({'s1': sArchived});
        when(mockHiveManager.getLecturesBySubject('s1')).thenReturn([lec]);

        await pumpArchiveScreen(tester);

        final subjectPanelFinder = find.byType(SubjectPanel);
        expect(subjectPanelFinder, findsOneWidget);

        final SubjectPanel panel = tester.widget<SubjectPanel>(
          subjectPanelFinder,
        );

        // Call the open lecture callback, which internally calls _navigateToPlayer
        panel.onOpenLecture.call(lec);
        await tester.pumpAndSettle();

        // PlayerScreen should be visible
        expect(find.text('PlayerScreen'), findsOneWidget);
      },
    );
  });
}
