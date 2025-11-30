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
      locale: const Locale('en'),
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

    allTags = [HiveTag(id: 't1', name: 'Tag 1', color: 0xFF000000)];
  });

  group('CreateSubjectDialog', () {
    /// Small helper app that opens CreateSubjectDialog when tapping a button
    Widget buildCreateDialogTestApp() {
      return MaterialApp(
        locale: const Locale('en'),
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
                      builder: (_) => CreateSubjectDialog(
                        allTags: allTags,
                        hiveManager: mockHiveManager,
                      ),
                    );
                  },
                  child: const Text('Open Create Dialog'),
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('shows SelectableTagPill for each tag in allTags', (
      tester,
    ) async {
      // CreateSubjectDialog uses HiveManager.instance internally
      when(mockHiveManager.getTags()).thenReturn(<HiveTag>[]);
      when(mockHiveManager.getSubjects()).thenReturn(<HiveSubject>[]);

      await tester.pumpWidget(buildCreateDialogTestApp());
      await tester.pump();

      // Open the dialog
      await tester.tap(find.text('Open Create Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateSubjectDialog), findsOneWidget);
      expect(find.byType(SelectableTagPill), findsNWidgets(allTags.length));
    });

    testWidgets('tapping a tag toggles its selected state', (tester) async {
      when(mockHiveManager.getTags()).thenReturn(<HiveTag>[]);
      when(mockHiveManager.getSubjects()).thenReturn(<HiveSubject>[]);

      await tester.pumpWidget(buildCreateDialogTestApp());
      await tester.pump();

      await tester.tap(find.text('Open Create Dialog'));
      await tester.pumpAndSettle();

      final tagFinder = find.byType(SelectableTagPill).first;

      // Initially not selected
      var pill = tester.widget<SelectableTagPill>(tagFinder);
      expect(pill.selected, isFalse);

      // Tap to select
      await tester.tap(tagFinder);
      await tester.pump();

      pill = tester.widget<SelectableTagPill>(tagFinder);
      expect(pill.selected, isTrue);

      // Tap again to unselect
      await tester.tap(tagFinder);
      await tester.pump();

      pill = tester.widget<SelectableTagPill>(tagFinder);
      expect(pill.selected, isFalse);
    });

    testWidgets(
      'Add with empty title shows pleaseEnterSubjectName snackbar and keeps dialog open',
      (tester) async {
        when(mockHiveManager.getTags()).thenReturn(<HiveTag>[]);
        when(mockHiveManager.getSubjects()).thenReturn(<HiveSubject>[]);

        await tester.pumpWidget(buildCreateDialogTestApp());
        await tester.pump();

        await tester.tap(find.text('Open Create Dialog'));
        await tester.pumpAndSettle();

        final dialogCtx = tester.element(find.byType(CreateSubjectDialog));
        final l10n = AppLocalizations.of(dialogCtx);

        // Title is empty by default, tap Add
        await tester.tap(find.text(l10n.add));
        await tester.pump(); // show snackbar

        expect(find.text(l10n.pleaseEnterSubjectName), findsOneWidget);
        // Dialog still open
        expect(find.byType(CreateSubjectDialog), findsOneWidget);
      },
    );

    testWidgets(
      'Add with duplicate title shows subjectNameExists snackbar and keeps dialog open',
      (tester) async {
        // One existing subject with title "Test Subject"
        when(mockHiveManager.getSubjects()).thenReturn([
          HiveSubject(
            id: 'existing',
            title: 'Test Subject',
            isArchived: false,
            isUncategorized: false,
            lectureIds: const [],
          ),
        ]);
        when(mockHiveManager.getTags()).thenReturn(<HiveTag>[]);

        await tester.pumpWidget(buildCreateDialogTestApp());
        await tester.pump();

        await tester.tap(find.text('Open Create Dialog'));
        await tester.pumpAndSettle();

        final dialogCtx = tester.element(find.byType(CreateSubjectDialog));
        final l10n = AppLocalizations.of(dialogCtx);

        // Enter duplicate title
        await tester.enterText(find.byType(TextField).first, 'Test Subject');
        await tester.pump();

        await tester.tap(find.text(l10n.add));
        await tester.pump(); // for snackbar

        expect(find.text(l10n.subjectNameExists), findsOneWidget);
        // Dialog should still be visible
        expect(find.byType(CreateSubjectDialog), findsOneWidget);

        verify(mockHiveManager.getSubjects()).called(1);
      },
    );

    testWidgets(
      'when there are already 15 tags, tapping "+" shows maxTagsReached snackbar and does not show add-tag form',
      (tester) async {
        final fifteenTags = List.generate(
          15,
          (i) => HiveTag(id: 't$i', name: 'Tag $i', color: 0xFF000000),
        );

        when(mockHiveManager.getTags()).thenReturn(fifteenTags);
        when(mockHiveManager.getSubjects()).thenReturn(<HiveSubject>[]);

        await tester.pumpWidget(buildCreateDialogTestApp());
        await tester.pump();

        await tester.tap(find.text('Open Create Dialog'));
        await tester.pumpAndSettle();

        final dialogCtx = tester.element(find.byType(CreateSubjectDialog));
        final l10n = AppLocalizations.of(dialogCtx);

        // Tap the "+" ActionChip
        await tester.tap(find.byType(ActionChip));
        await tester.pump(); // snackbar + possible state change

        // Should show "maxTagsReached" snackbar
        expect(find.text(l10n.maxTagsReached), findsOneWidget);

        // Add-tag panel (_isCreatingTag) should NOT be visible
        expect(find.text(l10n.addTag), findsNothing);

        // Should not attempt to save new tags
        verifyNever(mockHiveManager.saveTags(any));
      },
    );

    testWidgets('tapping + shows add-tag panel', (tester) async {
      // no tags yet, no subjects needed for this test
      when(mockHiveManager.getTags()).thenReturn(<HiveTag>[]);
      when(mockHiveManager.getSubjects()).thenReturn(<HiveSubject>[]);

      final settings = AppSettings(
        tagColorTheme: 'default',
      );
      when(mockHiveManager.settings).thenReturn(settings);

      await tester.pumpWidget(buildCreateDialogTestApp());
      await tester.pump();

      // Open CreateSubjectDialog
      await tester.tap(find.text('Open Create Dialog'));
      await tester.pumpAndSettle();

      final dialogCtx = tester.element(find.byType(CreateSubjectDialog));
      final l10n = AppLocalizations.of(dialogCtx);

      // Initially, add-tag panel shouldn't be visible
      expect(find.text(l10n.addTag), findsNothing);

      // Tap the "+" ActionChip
      await tester.tap(find.byType(ActionChip));
      await tester.pump(); // rebuild with _isCreatingTag = true

      // Now the add-tag panel title should appear
      expect(find.text(l10n.addTag), findsOneWidget);
    });

    testWidgets('creating a new tag via + and Apply saves tags', (
      tester,
    ) async {
      final existingTags = <HiveTag>[];
      when(mockHiveManager.getTags()).thenReturn(existingTags);
      when(mockHiveManager.getSubjects()).thenReturn(<HiveSubject>[]);

      final settings = AppSettings(tagColorTheme: 'default');
      when(mockHiveManager.settings).thenReturn(settings);

      when(mockHiveManager.saveTags(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildCreateDialogTestApp());
      await tester.pump();

      // Open dialog
      await tester.tap(find.text('Open Create Dialog'));
      await tester.pumpAndSettle();

      final dialogCtx = tester.element(find.byType(CreateSubjectDialog));
      final l10n = AppLocalizations.of(dialogCtx);

      // Tap "+"
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      await tester.tap(find.text(l10n.apply));
      await tester.pump(); // run onPressed
      await tester.pump();
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      await tester.tap(find.text(l10n.apply));
      await tester.pump(); // run onPressed
      await tester.pump();
      await tester.tap(find.byType(ActionChip));
      await tester.pump();

      // Add-tag panel visible
      expect(find.text(l10n.addTag), findsOneWidget);

      final tagTextFieldFinder = find
          .descendant(
            of: find.byType(CreateSubjectDialog),
            matching: find.byType(TextField),
          )
          .at(1);

      await tester.enterText(tagTextFieldFinder, 'My New Tag');
      await tester.pump();

      // Tap "Apply" to complete the completer and trigger _addNewTag logic
      await tester.tap(find.text(l10n.apply));
      await tester.pump(); // run onPressed
      await tester.pump(); // let _addNewTag's setState run

      // Verify saveTags was called with a list containing the new tag
      final capturedLists = verify(
        mockHiveManager.saveTags(captureAny),
      ).captured.cast<List<HiveTag>>();

      final lastSavedList = capturedLists.last;

      expect(lastSavedList.length, 3);
      expect(lastSavedList.last.name, 'My New Tag');

      // Panel should be dismissed (_isCreatingTag == false)
      expect(find.text(l10n.addTag), findsNothing);
    });
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
      final archiveLabel = l10n.isKorean
          ? '보관'
          : 'Archive';

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
