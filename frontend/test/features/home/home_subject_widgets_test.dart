import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/home/home_subject_widgets.dart';
import 'package:re_view/shared/widgets.dart';

import 'home_subject_widgets_test.mocks.dart';

@GenerateMocks([HiveManager])
void main() {
  late MockHiveManager mockHiveManager;
  late HiveSubject subject;
  late List<HiveTag> allTags;

  Widget buildTestApp() {
    return MaterialApp(
      locale: const Locale('en'), // so archive label is "Archive"
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => SubjectEditDialog(
                      subject: subject,
                      initialTagIds: const ['t1'],
                      allTags: allTags,
                      hiveManager: mockHiveManager,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  setUp(() {
    mockHiveManager = MockHiveManager();

    subject = HiveSubject(
      id: 's1',
      title: 'Test Subject',
      isArchived: false,
      isUncategorized: false,
      lectureIds: const [],
    );

    // Adjust fields if your HiveTag model is different
    allTags = [HiveTag(id: 't1', name: 'Tag 1', color: 0xFF000000)];
  });

  group('SubjectEditDialog – delete flow', () {
    testWidgets('tapping Delete then Yes calls HiveManager.deleteSubject', (
      tester,
    ) async {
      when(
        mockHiveManager.deleteSubject(any),
      ).thenAnswer((_) async {}); // if async, or thenReturn(null) if sync

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // 1. Open SubjectEditDialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Grab l10n from the dialog context
      final dialogCtx = tester.element(find.byType(SubjectEditDialog));
      final l10n = AppLocalizations.of(dialogCtx);

      // 2. Tap "Delete" in the edit dialog
      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();

      // 3. Confirmation dialog should appear
      expect(find.byType(DeleteWarningDialog), findsOneWidget);

      final confirmCtx = tester.element(find.byType(DeleteWarningDialog));
      final l10nConfirm = AppLocalizations.of(confirmCtx);

      // 4. Tap "Yes" in the confirmation dialog
      await tester.tap(find.text(l10nConfirm.yes));
      await tester.pumpAndSettle();

      // 5. Verify HiveManager.deleteSubject was called
      verify(mockHiveManager.deleteSubject('s1')).called(1);
    });

    testWidgets(
      'tapping Delete then No does NOT call HiveManager.deleteSubject',
      (tester) async {
        when(mockHiveManager.deleteSubject(any)).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final dialogCtx = tester.element(find.byType(SubjectEditDialog));
        final l10n = AppLocalizations.of(dialogCtx);

        await tester.tap(find.text(l10n.delete));
        await tester.pumpAndSettle();

        expect(find.byType(DeleteWarningDialog), findsOneWidget);

        final confirmCtx = tester.element(find.byType(DeleteWarningDialog));
        final l10nConfirm = AppLocalizations.of(confirmCtx);

        await tester.tap(find.text(l10nConfirm.no));
        await tester.pumpAndSettle();

        verifyNever(mockHiveManager.deleteSubject(any));
      },
    );
  });

  group('SubjectEditDialog – archive flow', () {
    testWidgets('tapping Archive then Yes calls HiveManager.archiveSubject', (
      tester,
    ) async {
      when(mockHiveManager.archiveSubject(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // 1. Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final dialogCtx = tester.element(find.byType(SubjectEditDialog));
      final l10n = AppLocalizations.of(dialogCtx);

      // Label is localized in widget:
      // archiveLabel: l10n.isKorean ? '보관' : 'Archive'
      final archiveLabel = l10n.isKorean
          ? '보관'
          : 'Archive'; // but locale is 'en', so "Archive"

      // 2. Tap "Archive" in the edit dialog
      await tester.tap(find.text(archiveLabel));
      await tester.pumpAndSettle();

      // 3. Confirmation dialog appears
      expect(find.byType(DeleteWarningDialog), findsOneWidget);

      final confirmCtx = tester.element(find.byType(DeleteWarningDialog));
      final l10nConfirm = AppLocalizations.of(confirmCtx);

      // 4. Tap "Yes"
      await tester.tap(find.text(l10nConfirm.yes));
      await tester.pumpAndSettle();

      // 5. Verify archiveSubject call
      verify(mockHiveManager.archiveSubject('s1')).called(1);
    });

    testWidgets(
      'tapping Archive then No does NOT call HiveManager.archiveSubject',
      (tester) async {
        when(mockHiveManager.archiveSubject(any)).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final dialogCtx = tester.element(find.byType(SubjectEditDialog));
        final l10n = AppLocalizations.of(dialogCtx);
        final archiveLabel = l10n.isKorean ? '보관' : 'Archive';

        await tester.tap(find.text(archiveLabel));
        await tester.pumpAndSettle();

        expect(find.byType(DeleteWarningDialog), findsOneWidget);

        final confirmCtx = tester.element(find.byType(DeleteWarningDialog));
        final l10nConfirm = AppLocalizations.of(confirmCtx);

        await tester.tap(find.text(l10nConfirm.no));
        await tester.pumpAndSettle();

        verifyNever(mockHiveManager.archiveSubject(any));
      },
    );
  });
}
