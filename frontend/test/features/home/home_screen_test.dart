import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/home/home_screen.dart';
import 'package:re_view/features/home/custom_drawer.dart';
import 'package:re_view/features/home/home_widgets.dart';
import 'package:re_view/shared/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<AppData> testBox;
  late Directory testDirectory;

  setUpAll(() async {
    // Create a temporary directory for Hive in tests
    testDirectory = Directory.systemTemp.createTempSync('hive_test_home_');

    // Initialize Hive with the test directory
    Hive.init(testDirectory.path);

    // Register adapters if not already registered
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

    // Open the box manually
    testBox = await Hive.openBox<AppData>('app_data');

    // Initialize with empty data
    final appData = AppData(
      settings: AppSettings(),
      subjects: {},
      tags: {},
      lectures: {},
      uiState: UiState(),
    );
    await testBox.put('main', appData);

    // Initialize HiveManager for testing
    await HiveManager.instance.initForTesting(testBox);
  });

  tearDownAll(() async {
    // Close all Hive boxes and clean up
    await Hive.close();
    if (testDirectory.existsSync()) {
      testDirectory.deleteSync(recursive: true);
    }
  });

  Widget buildTestApp({Locale locale = const Locale('en')}) {
    final theme = ThemeData.from(
      colorScheme: lightScheme,
    ).copyWith(extensions: [AppHighlights.fromScheme(lightScheme)]);

    return MaterialApp(
      locale: locale,
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }

  HiveSubject makeSubject({
    required String id,
    String title = 'Subject',
    bool favorite = false,
    List<String> tagIds = const [],
    List<String> lectureIds = const [],
  }) {
    return HiveSubject(
      id: id,
      title: title,
      favorite: favorite,
      tagIds: tagIds,
      lectureIds: lectureIds,
    );
  }

  HiveTag makeTag({
    required String id,
    required String name,
    int color = 0xFFFFFFFF,
  }) {
    return HiveTag(id: id, name: name, color: color);
  }

  HiveLecture makeLecture({
    required String id,
    required String subjectId,
    String weekLabel = 'Week 1',
    String title = 'Lecture',
    int duration = 3600,
  }) {
    return HiveLecture(
      id: id,
      subjectId: subjectId,
      weekLabel: weekLabel,
      title: title,
      duration: duration,
      audioPath: null,
    );
  }

  // Helper to update test data - modifies in place
  void updateTestData(void Function(AppData) updater) {
    final appData = testBox.get('main')!;
    updater(appData);
    // Note: Hive saves changes automatically for HiveObjects, no need to call put
  }

  setUp(() async {
    // Reset to empty data before each test
    final appData = AppData(
      settings: AppSettings()..accessibilityReduceMotion = false,
      subjects: {},
      tags: {},
      lectures: {},
      uiState: UiState(),
    );
    await testBox.put('main', appData);
    await HiveManager.instance.initForTesting(testBox);
  });

  group('HomeScreen - Structure', () {
    testWidgets('renders AppBar with menu, title, and search buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Check AppBar exists
      expect(find.byType(AppBar), findsOneWidget);

      // Check menu icon button
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Check search icon button
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Check app title exists
      expect(find.text('Re:View'), findsOneWidget);
    });

    testWidgets('renders filter and favorite pills', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(FilterPill), findsOneWidget);
      expect(find.byType(FavoritePill), findsOneWidget);
    });
  });

  group('HomeScreen - Drawer behavior - reduce motion disabled', () {
    testWidgets('has drawer widget when reduce motion is disabled', (
      tester,
    ) async {
      // setUp already sets accessibilityReduceMotion to false
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Find the Scaffold and check if it has a drawer
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNotNull);
      expect(scaffold.drawer, isA<CustomDrawer>());
    });
  });

  group('HomeScreen - Drawer behavior - reduce motion enabled', () {
    setUp(() async {
      // Override the default setUp with reduce motion enabled
      final appData = AppData(
        settings: AppSettings()..accessibilityReduceMotion = true,
        subjects: {},
        tags: {},
        lectures: {},
        uiState: UiState(),
      );
      await testBox.put('main', appData);
      await HiveManager.instance.initForTesting(testBox);
    });

    testWidgets('has no drawer widget when reduce motion is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Find the Scaffold and check that it has NO drawer
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull);
    });

    testWidgets('menu button exists when reduce motion is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify menu button exists
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Verify scaffold has no drawer (uses dialog instead)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull);
    });
  });

  group('HomeScreen - Search navigation', () {
    testWidgets('search button exists in app bar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify search button exists
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('HomeScreen - Filter functionality', () {
    testWidgets('toggles filter pill active state', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Initially filter should be inactive
      FilterPill filterPill = tester.widget<FilterPill>(
        find.byType(FilterPill),
      );
      expect(filterPill.active, false);

      // Tap filter pill
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Filter should now be active
      filterPill = tester.widget<FilterPill>(find.byType(FilterPill));
      expect(filterPill.active, true);

      // Tap again
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Filter should be inactive again
      filterPill = tester.widget<FilterPill>(find.byType(FilterPill));
      expect(filterPill.active, false);
    });

    testWidgets('shows tag chips when filter is enabled', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        data.tags['t2'] = makeTag(id: 't2', name: 'Tag2');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Initially tag chips should not be visible
      expect(find.byType(TagChips), findsNothing);

      // Enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Tag chips should now be visible
      expect(find.byType(TagChips), findsOneWidget);
    });

    testWidgets('hides tag chips when filter is disabled', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();
      expect(find.byType(TagChips), findsOneWidget);

      // Disable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Tag chips should be hidden
      expect(find.byType(TagChips), findsNothing);
    });

    testWidgets('clears selected tags when filter is disabled', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Select a tag
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pump();

      // Verify tag is selected
      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip).first).selected,
        isTrue,
      );

      // Disable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Re-enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Tag should no longer be selected
      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip).first).selected,
        isFalse,
      );
    });
  });

  group('HomeScreen - Favorite functionality', () {
    testWidgets('toggles favorite pill active state', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Initially favorite should be inactive
      FavoritePill favoritePill = tester.widget<FavoritePill>(
        find.byType(FavoritePill),
      );
      expect(favoritePill.active, false);

      // Tap favorite pill
      await tester.tap(find.byType(FavoritePill));
      await tester.pump();

      // Favorite should now be active
      favoritePill = tester.widget<FavoritePill>(find.byType(FavoritePill));
      expect(favoritePill.active, true);
    });

    testWidgets('shows only favorite subjects when enabled', (tester) async {
      updateTestData((data) {
        data.subjects['s1'] = makeSubject(
          id: 's1',
          title: 'Regular',
          favorite: false,
        );
        data.subjects['s2'] = makeSubject(
          id: 's2',
          title: 'Favorite',
          favorite: true,
        );
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Initially should show both subjects
      expect(find.byType(SubjectPanel), findsNWidgets(2));

      // Enable favorites filter
      await tester.tap(find.byType(FavoritePill));
      await tester.pumpAndSettle();

      // Should only show favorite subject
      expect(find.byType(SubjectPanel), findsOneWidget);
    });
  });

  group('HomeScreen - Tag filtering', () {
    testWidgets('toggles tag selection', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Select tag
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pump();

      // Verify tag is selected
      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip).first).selected,
        isTrue,
      );

      // Deselect tag
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pump();

      // Verify tag is deselected
      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip).first).selected,
        isFalse,
      );
    });

    testWidgets('filters subjects by selected tags', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        data.subjects['s1'] = makeSubject(
          id: 's1',
          title: 'With Tag',
          tagIds: ['t1'],
        );
        data.subjects['s2'] = makeSubject(id: 's2', title: 'Without Tag');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Initially should show both subjects
      expect(find.byType(SubjectPanel), findsNWidgets(2));

      // Enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Select tag
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();

      // Should only show subject with tag
      expect(find.byType(SubjectPanel), findsOneWidget);
    });
  });

  group('HomeScreen - Subject display', () {
    testWidgets('displays subjects from manager', (tester) async {
      updateTestData((data) {
        data.subjects['s1'] = makeSubject(id: 's1', title: 'Subject 1');
        data.subjects['s2'] = makeSubject(id: 's2', title: 'Subject 2');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify subjects are displayed
      expect(find.byType(SubjectPanel), findsNWidgets(2));
    });

    testWidgets('displays subject tags in sorted order', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'English');
        data.tags['t2'] = makeTag(id: 't2', name: '123');
        data.tags['t3'] = makeTag(id: 't3', name: '한글');
        data.subjects['s1'] = makeSubject(id: 's1', tagIds: ['t1', 't2', 't3']);
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Find all TagPills
      final tagPills = tester.widgetList<TagPill>(find.byType(TagPill));
      final names = tagPills.map((p) => p.tag.name).toList();

      // Verify tags are sorted: numbers > Korean > English
      expect(names, equals(['123', '한글', 'English']));
    });

    testWidgets('handles subjects with missing tags gracefully', (
      tester,
    ) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        // Subject references tag 't2' which doesn't exist
        data.subjects['s1'] = makeSubject(id: 's1', tagIds: ['t1', 't2']);
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Should only show the one valid tag
      expect(find.byType(TagPill), findsOneWidget);
    });
  });

  group('HomeScreen - Subject interactions', () {
    testWidgets('displays subject panel when subject exists', (tester) async {
      final appData = testBox.get('main')!;
      appData.subjects['s1'] = makeSubject(id: 's1', title: 'Test Subject');

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Verify subject panel exists
      expect(find.byType(SubjectPanel), findsOneWidget);
    });
  });

  group('HomeScreen - Empty states', () {
    testWidgets('shows no favorites message when no favorite subjects', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Enable favorites filter
      await tester.tap(find.byType(FavoritePill));
      await tester.pump();

      // Verify empty state message
      expect(find.byType(EmptyStateMessage), findsOneWidget);
    });

    testWidgets('shows no subjects with tags message when filtered', (
      tester,
    ) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Enable filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Select tag
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pump();

      // Verify empty state message
      expect(find.byType(EmptyStateMessage), findsOneWidget);
    });

    testWidgets('shows no message when no filters active and no subjects', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Should find EmptyStateMessage but with empty string (so it shows nothing)
      expect(find.byType(EmptyStateMessage), findsOneWidget);
      final emptyMessage = tester.widget<EmptyStateMessage>(
        find.byType(EmptyStateMessage),
      );
      expect(emptyMessage.message, '');
    });
  });

  group('HomeScreen - Tag name sorting', () {
    testWidgets('sorts tags with numbers first', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Zebra');
        data.tags['t2'] = makeTag(id: 't2', name: '1st');
        data.tags['t3'] = makeTag(id: 't3', name: '가나다');
        data.subjects['s1'] = makeSubject(id: 's1', tagIds: ['t1', 't2', 't3']);
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final tagPills = tester.widgetList<TagPill>(find.byType(TagPill));
      final names = tagPills.map((p) => p.tag.name).toList();

      // Numbers should come first
      expect(names.first, '1st');
    });

    testWidgets('sorts tags with Korean second', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Apple');
        data.tags['t2'] = makeTag(id: 't2', name: '가나다');
        data.tags['t3'] = makeTag(id: 't3', name: '123');
        data.subjects['s1'] = makeSubject(id: 's1', tagIds: ['t1', 't2', 't3']);
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final tagPills = tester.widgetList<TagPill>(find.byType(TagPill));
      final names = tagPills.map((p) => p.tag.name).toList();

      // Order should be: numbers, Korean, English
      expect(names, equals(['123', '가나다', 'Apple']));
    });

    testWidgets('sorts tags with English last', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Zebra');
        data.tags['t2'] = makeTag(id: 't2', name: 'Apple');
        data.subjects['s1'] = makeSubject(id: 's1', tagIds: ['t1', 't2']);
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final tagPills = tester.widgetList<TagPill>(find.byType(TagPill));
      final names = tagPills.map((p) => p.tag.name).toList();

      // English tags should be sorted alphabetically
      expect(names, equals(['Apple', 'Zebra']));
    });

    testWidgets('handles empty tag names', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: '');
        data.tags['t2'] = makeTag(id: 't2', name: 'Normal');
        data.subjects['s1'] = makeSubject(id: 's1', tagIds: ['t1', 't2']);
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Should not crash with empty tag name
      expect(find.byType(TagPill), findsNWidgets(2));
    });
  });

  group('HomeScreen - Localization', () {
    testWidgets('renders Korean labels when locale is ko', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('ko')));
      await tester.pumpAndSettle();

      expect(find.text('필터'), findsOneWidget);
      expect(find.text('즐겨찾기'), findsOneWidget);
    });

    testWidgets('renders English labels when locale is en', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });
  });

  group('HomeScreen - Combined filters', () {
    testWidgets('applies both favorite and tag filters', (tester) async {
      updateTestData((data) {
        data.tags['t1'] = makeTag(id: 't1', name: 'Tag1');
        data.subjects['s1'] = makeSubject(
          id: 's1',
          title: 'Fav with tag',
          favorite: true,
          tagIds: ['t1'],
        );
        data.subjects['s2'] = makeSubject(
          id: 's2',
          title: 'Fav no tag',
          favorite: true,
        );
        data.subjects['s3'] = makeSubject(
          id: 's3',
          title: 'No fav with tag',
          tagIds: ['t1'],
        );
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // All 3 subjects should be visible
      expect(find.byType(SubjectPanel), findsNWidgets(3));

      // Enable favorites
      await tester.tap(find.byType(FavoritePill));
      await tester.pumpAndSettle();

      // Should show 2 favorite subjects
      expect(find.byType(SubjectPanel), findsNWidgets(2));

      // Enable tag filter
      await tester.tap(find.byType(FilterPill));
      await tester.pump();

      // Select a tag
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();

      // Should only show 1 subject (favorite AND has tag)
      expect(find.byType(SubjectPanel), findsOneWidget);
    });
  });

  group('HomeScreen - Edge cases', () {
    testWidgets('handles null or empty lecture lists', (tester) async {
      updateTestData((data) {
        data.subjects['s1'] = makeSubject(id: 's1');
        // data modified in place
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Should display subject panel even with no lectures
      expect(find.byType(SubjectPanel), findsOneWidget);
    });

    testWidgets('displays subjects when data is present', (tester) async {
      // Add a subject before building widget
      final appData = testBox.get('main')!;
      appData.subjects['s1'] = makeSubject(id: 's1', title: 'Test Subject');

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Should show the subject
      expect(find.byType(SubjectPanel), findsOneWidget);
    });
  });
}
