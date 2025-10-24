import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/models.dart';
import 'package:re_view/features/home/home_widgets.dart';

class MockVoidCallback extends Mock {
  void call();
}

class MockLectureCallback extends Mock {
  void call(Lecture lecture);
}

class MockTagToggle extends Mock {
  void call(String tagId);
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  late Box<AppData> testBox;
  late Directory testDirectory;

  const subject = Subject(
    id: 'subject-1',
    title: 'Algebra',
    favorite: false,
    tagIds: ['math', 'logic'],
    lectureIds: ['lec-1', 'lec-2'],
  );

  const lectures = [
    Lecture(
      id: 'lec-1',
      subjectId: 'subject-1',
      weekLabel: 'Week 1',
      title: 'Introduction',
      durationSec: 3600,
      slidesPath: null,
    ),
    Lecture(
      id: 'lec-2',
      subjectId: 'subject-1',
      weekLabel: 'Week 2',
      title: 'Advanced Topics',
      durationSec: 4200,
      slidesPath: null,
    ),
  ];

  const tags = [
    Tag(id: 'math', name: 'math', color: 0xFFE0F7FA),
    Tag(id: 'logic', name: 'logic', color: 0xFFFFF9C4),
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
    await binding.runAsync(() async {
      if (testBox.isOpen) {
        await testBox.close();
      }
      await Hive.close();
    });
    if (testDirectory.existsSync()) {
      testDirectory.deleteSync(recursive: true);
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
    testWidgets('shows label and triggers tap callback', (
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
  });

  group('FavoritePill', () {
    testWidgets('shows filled star when active and triggers tap callback', (
      WidgetTester tester,
    ) async {
      final mockOnTap = MockVoidCallback();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FavoritePill(active: true, onTap: mockOnTap.call, label: 'Favorites'),
        ),
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
        wrapWithMaterialApp(
          FavoritePill(active: false, onTap: () {}, label: 'Favorites'),
        ),
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
      const tags = [
        Tag(id: 'math', name: 'math', color: 0xFFE0F7FA),
        Tag(id: 'cs', name: 'cs', color: 0xFFFFF9C4),
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
  });

  group('LectureCard', () {
    testWidgets('renders placeholder thumbnail and forwards tap', (
      WidgetTester tester,
    ) async {
      final mockOnTap = MockLectureCallback();
      const lecture = Lecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 1',
        title: 'Introduction',
        durationSec: 3600,
        slidesPath: null,
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

    /*
    testWidgets('toggles expansion and persists to Hive',
        (WidgetTester tester) async {
      HiveManager.instance.settings.accessibilityReduceMotion = true;

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

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();

      expect(
        HiveManager.instance.getSubjectExpandedState(subject.id),
        isFalse,
      );
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });
    */

    testWidgets('invokes callbacks for favorite and lecture taps', (
      WidgetTester tester,
    ) async {
      final mockFavorite = MockVoidCallback();
      final mockOnOpenLecture = MockLectureCallback();
      final mockOnUpdated = MockVoidCallback();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          SubjectPanel(
            subject: subject.copyWith(favorite: false),
            tags: tags,
            lectures: lectures,
            onToggleFavorite: mockFavorite.call,
            onOpenLecture: mockOnOpenLecture.call,
            onLectureUpdated: mockOnUpdated.call,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();
      verify(mockFavorite()).called(1);

      final Lecture firstLecture = lectures.first;
      await tester.tap(find.byType(LectureCard).first);
      await tester.pump();
      verify(mockOnOpenLecture(firstLecture)).called(1);

      final LectureCard firstCard = tester.widget<LectureCard>(
        find.byType(LectureCard).first,
      );
      expect(firstCard.onUpdated, isNotNull);
      firstCard.onUpdated!.call();
      verify(mockOnUpdated()).called(1);
    });
  });
}
