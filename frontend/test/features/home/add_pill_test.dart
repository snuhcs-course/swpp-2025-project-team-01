import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/home/add_pill.dart';
import 'package:re_view/features/home/home_widgets.dart';
import 'package:re_view/features/home/home_subject_widgets.dart';

import 'add_pill_test.mocks.dart';

@GenerateMocks([HiveManager])
void main() {
  late MockHiveManager mockHiveManager;

  setUp(() {
    mockHiveManager = MockHiveManager();

    when(mockHiveManager.getTags()).thenReturn([]);
  });

  tearDown(() {
    reset(mockHiveManager);
  });

  group('AddPill', () {
    testWidgets('registers and unregisters HiveManager listener', (
      tester,
    ) async {
      final link = LayerLink();
      final plusKey = GlobalKey();

      await tester.pumpWidget(
        _TestApp(
          link: link,
          pillKey: plusKey,
          mockHiveManager: mockHiveManager,
        ),
      );
      await tester.pump();

      // Verify listener was added once in initState
      final verification = verify(
        mockHiveManager.addListener(captureAny as VoidCallback?),
      );
      final captured = verification.captured;
      expect(captured.length, 1);
      final VoidCallback listener = captured.single as VoidCallback;

      // Remove the widget to trigger dispose
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // Same listener should be removed
      verify(mockHiveManager.removeListener(listener)).called(1);
    });

    testWidgets('tapping pill toggles add menu overlay on / off', (
      tester,
    ) async {
      final link = LayerLink();
      final plusKey = GlobalKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: _TestApp(
            link: link,
            pillKey: plusKey,
            mockHiveManager: mockHiveManager,
          ),
        ),
      );
      await tester.pump();

      // Initially: no MiniActionPill
      expect(find.byType(MiniActionPill), findsNothing);

      // Tap the AddPill → overlay should appear
      await tester.tap(find.byType(PillButton));
      await tester.pumpAndSettle();

      // Two actions: add lecture + add subject
      expect(find.byType(MiniActionPill), findsNWidgets(2));
      expect(
        find.widgetWithIcon(MiniActionPill, Icons.note_add_outlined),
        findsOneWidget,
      );
      expect(
        find.widgetWithIcon(MiniActionPill, Icons.folder_open_outlined),
        findsOneWidget,
      );

      // Tap AddPill again → overlay should disappear
      await tester.tap(find.byType(PillButton));
      await tester.pumpAndSettle();

      expect(find.byType(MiniActionPill), findsNothing);
    });

    testWidgets('tapping outside closes add menu overlay', (tester) async {
      final link = LayerLink();
      final plusKey = GlobalKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: _TestApp(
            link: link,
            pillKey: plusKey,
            mockHiveManager: mockHiveManager,
          ),
        ),
      );
      await tester.pump();

      // Open menu
      await tester.tap(find.byType(PillButton));
      await tester.pumpAndSettle();

      expect(find.byType(MiniActionPill), findsNWidgets(2));

      // Tap somewhere in the screen background (caught by full-screen GestureDetector)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Overlay closed
      expect(find.byType(MiniActionPill), findsNothing);
    });

    testWidgets(
      'calling showCreateSubjectDialog with create action calls createSubject',
      (tester) async {
        final link = LayerLink();
        final plusKey = GlobalKey();

        when(mockHiveManager.getTags()).thenReturn([]);
        when(
          mockHiveManager.createSubject(any, any),
        ).thenAnswer((_) async => Future.value());

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
            child: _TestApp(
              link: link,
              pillKey: plusKey,
              mockHiveManager: mockHiveManager,
            ),
          ),
        );
        await tester.pump();

        // Open overlay
        await tester.tap(find.byType(PillButton));
        await tester.pumpAndSettle();

        // Tap "add subject" pill -> opens CreateSubjectDialog
        await tester.tap(
          find.widgetWithIcon(MiniActionPill, Icons.folder_open_outlined),
        );
        await tester.pumpAndSettle();

        // Ensure dialog is shown
        expect(find.byType(CreateSubjectDialog), findsOneWidget);

        // Simulate the user pressing "create" in the dialog by popping
        // a result Map with action/title/tagIds.
        const titleText = 'My New Subject';
        const tagIds = <String>['tag1', 'tag2'];

        final dialogContext = tester.element(find.byType(CreateSubjectDialog));
        Navigator.of(dialogContext).pop(<String, dynamic>{
          'action': 'create',
          'title': titleText,
          'tagIds': tagIds,
        });

        await tester.pumpAndSettle();

        // Verify that createSubject was called with the data from the dialog
        verify(mockHiveManager.createSubject(titleText, tagIds)).called(1);
      },
    );

    testWidgets('tapping add lecture mini action navigates to lecture form', (
      tester,
    ) async {
      final link = LayerLink();
      final plusKey = GlobalKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: _TestApp(
            link: link,
            pillKey: plusKey,
            mockHiveManager: mockHiveManager,
          ),
        ),
      );
      await tester.pump();

      // Open overlay
      await tester.tap(find.byType(PillButton));
      await tester.pumpAndSettle();

      // Tap the "add lecture" MiniActionPill (note_add_outlined icon)
      await tester.tap(
        find.widgetWithIcon(MiniActionPill, Icons.note_add_outlined),
      );
      await tester.pumpAndSettle();

      // We should now be on the lecture form screen (test stub)
      expect(find.text('Lecture form screen (test stub)'), findsOneWidget);
    });

    testWidgets('tapping add subject mini action shows CreateSubjectDialog', (
      tester,
    ) async {
      final link = LayerLink();
      final plusKey = GlobalKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: _TestApp(
            link: link,
            pillKey: plusKey,
            mockHiveManager: mockHiveManager,
          ),
        ),
      );
      await tester.pump();

      // Open overlay
      await tester.tap(find.byType(PillButton));
      await tester.pumpAndSettle();

      // Tap the "add subject" MiniActionPill (folder_open_outlined icon)
      await tester.tap(
        find.widgetWithIcon(MiniActionPill, Icons.folder_open_outlined),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CreateSubjectDialog), findsOneWidget);
    });
  });
}

/// Minimal test app
class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.link,
    required this.pillKey,
    required this.mockHiveManager,
  });

  final LayerLink link;
  final GlobalKey pillKey;
  final MockHiveManager mockHiveManager;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        Routes.lectureForm: (_) => const Scaffold(
          body: Center(child: Text('Lecture form screen (test stub)')),
        ),
      },
      home: Scaffold(
        body: Center(
          child: CompositedTransformTarget(
            link: link,
            child: AddPill(
              key: pillKey,
              icon: Icons.add,
              link: link,
              hiveManager: mockHiveManager,
            ),
          ),
        ),
      ),
    );
  }
}
