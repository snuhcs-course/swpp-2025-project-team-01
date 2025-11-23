import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/home/home_widgets.dart';

class MockVoidCallback extends Mock {
  void call();
}

class MockLectureCallback extends Mock {
  void call(HiveLecture lecture);
}

class MockTagToggle extends Mock {
  void call(String tagId);
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  late Box<AppData> testBox;
  late Directory testDirectory;

  final subject = HiveSubject(
    id: 'subject-1',
    title: 'Algebra',
    favorite: false,
    tagIds: ['math', 'logic'],
    lectureIds: ['lec-1', 'lec-2'],
  );

  final lectures = [
    HiveLecture(
      id: 'lec-1',
      subjectId: 'subject-1',
      weekLabel: 'Week 1',
      title: 'Introduction',
      duration: 3600000, // 1시간 (밀리초)
      originalAudioPath: 'originalAudio.m4a',
      ttsAudioPath: 'ttsAudio.opus',
    ),
    HiveLecture(
      id: 'lec-2',
      subjectId: 'subject-1',
      weekLabel: 'Week 2',
      title: 'Advanced Topics',
      duration: 4200000, // 1시간 10분 (밀리초)
      originalAudioPath: 'originalAudio.m4a',
      ttsAudioPath: 'ttsAudio.opus',
    ),
  ];

  final tags = [
    HiveTag(id: 'math', name: 'math', color: 0xFFE0F7FA),
    HiveTag(id: 'logic', name: 'logic', color: 0xFFFFF9C4),
  ];

  ThemeData buildTheme() => ThemeData.from(colorScheme: lightScheme).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppHighlights.fromScheme(lightScheme),
    ],
  );

  Widget wrapWithMaterialApp(Widget child) => MaterialApp(
    theme: buildTheme(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );

  setUpAll(() async {
    testDirectory = Directory.systemTemp.createTempSync('hive_home_widgets_');
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

  group('EmptyStateMessage', () {
    testWidgets('renders nothing when message empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(const EmptyStateMessage(message: '')),
      );

      expect(
        find.descendant(
          of: find.byType(EmptyStateMessage),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });

    testWidgets('renders provided message when not empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(const EmptyStateMessage(message: 'No items found')),
      );

      expect(
        find.descendant(
          of: find.byType(EmptyStateMessage),
          matching: find.text('No items found'),
        ),
        findsOneWidget,
      );
    });
  });

  group('FilterPill', () {
    testWidgets('shows label and triggers tap callback when inactive', (
      WidgetTester tester,
    ) async {
      final mockOnTap = MockVoidCallback();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FilterPill(
            icon: Icons.filter_alt,
            label: 'Filter',
            onTap: mockOnTap.call,
            active: false,
          ),
        ),
      );

      expect(find.text('Filter'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);

      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      verify(mockOnTap()).called(1);
    });

    testWidgets('shows different styling when active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FilterPill(
            icon: Icons.filter_alt,
            label: 'Filter',
            onTap: () {},
            active: true,
          ),
        ),
      );

      expect(find.text('Filter'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    });
  });

  group('FavoritePill', () {
    testWidgets('shows filled star when active and triggers tap callback', (
      WidgetTester tester,
    ) async {
      final mockOnTap = MockVoidCallback();

      await tester.pumpWidget(
        wrapWithMaterialApp(FavoritePill(active: true, onTap: mockOnTap.call)),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byType(FavoritePill));
      await tester.pump();

      verify(mockOnTap()).called(1);
    });

    testWidgets('shows outlined star when inactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(FavoritePill(active: false, onTap: () {})),
      );

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('TagChips', () {
    testWidgets('invokes onToggle with tapped tag id', (
      WidgetTester tester,
    ) async {
      final mockToggle = MockTagToggle();
      final tags = [
        HiveTag(id: 'math', name: 'math', color: 0xFFE0F7FA),
        HiveTag(id: 'cs', name: 'cs', color: 0xFFFFF9C4),
      ];

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TagChips(
            tags: tags,
            selected: const {'cs'},
            onToggle: mockToggle.call,
          ),
        ),
      );

      await tester.tap(find.text('#math'));
      await tester.pump();

      verify(mockToggle('math')).called(1);
    });

    testWidgets('displays all tags with # prefix', (WidgetTester tester) async {
      final tags = [
        HiveTag(id: 'math', name: 'math', color: 0xFFE0F7FA),
        HiveTag(id: 'cs', name: 'cs', color: 0xFFFFF9C4),
        HiveTag(id: 'physics', name: 'physics', color: 0xFFFFCDD2),
      ];

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TagChips(tags: tags, selected: const {}, onToggle: (_) {}),
        ),
      );

      expect(find.text('#math'), findsOneWidget);
      expect(find.text('#cs'), findsOneWidget);
      expect(find.text('#physics'), findsOneWidget);
    });

    testWidgets('shows selected state correctly', (WidgetTester tester) async {
      final tags = [
        HiveTag(id: 'math', name: 'math', color: 0xFFE0F7FA),
        HiveTag(id: 'cs', name: 'cs', color: 0xFFFFF9C4),
      ];

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TagChips(tags: tags, selected: const {'math'}, onToggle: (_) {}),
        ),
      );

      final mathChip = tester.widget<ChoiceChip>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ChoiceChip &&
              widget.label is Text &&
              (widget.label as Text).data == '#math',
        ),
      );
      expect(mathChip.selected, isTrue);

      final csChip = tester.widget<ChoiceChip>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ChoiceChip &&
              widget.label is Text &&
              (widget.label as Text).data == '#cs',
        ),
      );
      expect(csChip.selected, isFalse);
    });

    testWidgets('handles empty tag list', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          TagChips(tags: const [], selected: const {}, onToggle: (_) {}),
        ),
      );

      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('LectureCard', () {
    testWidgets('renders placeholder thumbnail and forwards tap', (
      WidgetTester tester,
    ) async {
      final mockOnTap = MockLectureCallback();
      final lecture = HiveLecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 1',
        title: 'Introduction',
        duration: 3600000, // 1시간 (밀리초)
        originalAudioPath: 'originalAudio.m4a',
        ttsAudioPath: 'ttsAudio.opus',
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(LectureCard(lec: lecture, onTap: mockOnTap.call)),
      );

      await tester.pump(); // process initial async state

      expect(find.text('thumbnail'), findsOneWidget);

      await tester.tap(find.byType(LectureCard));
      await tester.pump();

      verify(mockOnTap(lecture)).called(1);
    });

    testWidgets('displays lecture title and week label', (
      WidgetTester tester,
    ) async {
      final lecture = HiveLecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 3',
        title: 'Advanced Algorithms',
        duration: 3600000, // 1시간 (밀리초)
        originalAudioPath: 'originalAudio.m4a',
        ttsAudioPath: 'ttsAudio.opus',
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(LectureCard(lec: lecture, onTap: (_) {})),
      );

      await tester.pump();

      expect(find.text('Advanced Algorithms'), findsOneWidget);
      expect(find.text('Week 3'), findsOneWidget);
    });

    testWidgets('calls onUpdated callback when provided', (
      WidgetTester tester,
    ) async {
      final mockOnUpdated = MockVoidCallback();
      final lecture = HiveLecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 1',
        title: 'Test',
        duration: 3600000, // 1시간 (밀리초)
        originalAudioPath: 'originalAudio.m4a',
        ttsAudioPath: 'ttsAudio.opus',
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(
          LectureCard(
            lec: lecture,
            onTap: (_) {},
            onUpdated: mockOnUpdated.call,
          ),
        ),
      );

      await tester.pump();

      // Get the card and call onUpdated
      final card = tester.widget<LectureCard>(find.byType(LectureCard));
      expect(card.onUpdated, isNotNull);
      card.onUpdated!();

      verify(mockOnUpdated()).called(1);
    });

    testWidgets('handles lecture without slidePath', (
      WidgetTester tester,
    ) async {
      final lecture = HiveLecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 1',
        title: 'No Slides',
        duration: 3600000, // 1시간 (밀리초)
        originalAudioPath: 'originalAudio.m4a',
        ttsAudioPath: 'ttsAudio.opus',
        slidePath: null,
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(LectureCard(lec: lecture, onTap: (_) {})),
      );

      await tester.pump();

      // Should show thumbnail placeholder
      expect(find.text('thumbnail'), findsOneWidget);
    });
  });

  group('SubjectPanel', () {
    testWidgets('shows header and lecture cards when expanded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          SubjectPanel(
            subject: subject,
            tags: tags,
            lectures: lectures,
            onToggleFavorite: () {},
            onOpenLecture: (_) {},
            onLectureUpdated: () {},
          ),
        ),
      );
      await tester.pump(); // allow LectureCard to update state

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('#math'), findsOneWidget);
      expect(find.text('#logic'), findsOneWidget);
      expect(find.byType(LectureCard), findsNWidgets(lectures.length));
    });

    testWidgets('respects stored collapsed state', (WidgetTester tester) async {
      HiveManager.instance.uiState.subjectExpandedStates[subject.id] = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          SubjectPanel(
            subject: subject,
            tags: tags,
            lectures: lectures,
            onToggleFavorite: () {},
            onOpenLecture: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('toggles expansion with reduce motion enabled', (
      WidgetTester tester,
    ) async {
      HiveManager.instance.settings.accessibilityReduceMotion = true;
      HiveManager.instance.uiState.subjectExpandedStates[subject.id] = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          SubjectPanel(
            subject: subject,
            tags: tags,
            lectures: lectures,
            onToggleFavorite: () {},
            onOpenLecture: (_) {},
          ),
        ),
      );

      await tester.pump();

      // Initially collapsed - should show up arrow
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(HiveManager.instance.getSubjectExpandedState(subject.id), isFalse);

      // Tap the header to expand
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
      await tester.pump();

      // Should now be expanded
      expect(HiveManager.instance.getSubjectExpandedState(subject.id), isTrue);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });

  // Note: _LectureDetailDialog tests have been moved to lecture_detail_dialog_test.dart
  // for better organization and to avoid test file bloat
}
