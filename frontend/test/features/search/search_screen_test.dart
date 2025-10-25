import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/search/search_screen.dart';

void main() {
  late Box<AppData> testBox;
  late Directory testDirectory;

  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create a temporary directory for Hive in tests
    testDirectory = Directory.systemTemp.createTempSync('hive_test_');

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

  setUp(() async {
    // Get current app data
    final appData = testBox.get('main')!;

    // Create test subjects
    final csSubject = HiveSubject(
      id: 'subject_cs_test',
      title: 'Computer Science',
      favorite: false,
      lectureIds: ['lec1', 'lec2'],
    );
    final mathSubject = HiveSubject(
      id: 'subject_math_test',
      title: 'Mathematics',
      favorite: false,
      lectureIds: ['lec3'],
    );

    // Create test lectures
    final lec1 = HiveLecture(
      id: 'lec1',
      subjectId: 'subject_cs_test',
      weekLabel: 'Week 1',
      title: 'Introduction to Algorithms',
      duration: 3600,
      slidePath: 'path/to/slides1.pdf',
      audioPath: 'path/to/audio1.mp3',
    );
    final lec2 = HiveLecture(
      id: 'lec2',
      subjectId: 'subject_cs_test',
      weekLabel: 'Week 2',
      title: 'Data Structures',
      duration: 3600,
      slidePath: 'path/to/slides2.pdf',
      audioPath: 'path/to/audio2.mp3',
    );
    final lec3 = HiveLecture(
      id: 'lec3',
      subjectId: 'subject_math_test',
      weekLabel: 'Week 1',
      title: 'Linear Algebra Basics',
      duration: 3600,
      slidePath: 'path/to/slides3.pdf',
      audioPath: 'path/to/audio3.mp3',
    );

    // Update app data
    appData.subjects['subject_cs_test'] = csSubject;
    appData.subjects['subject_math_test'] = mathSubject;
    appData.lectures['lec1'] = lec1;
    appData.lectures['lec2'] = lec2;
    appData.lectures['lec3'] = lec3;

    // Save to box
    await testBox.put('main', appData);

    // Reinitialize HiveManager to pick up the new data
    await HiveManager.instance.initForTesting(testBox);
  });

  tearDown(() async {
    // Reset to empty data
    final appData = AppData(
      settings: AppSettings(),
      subjects: {},
      tags: {},
      lectures: {},
      uiState: UiState(),
    );
    await testBox.put('main', appData);

    // Reinitialize HiveManager with empty data
    await HiveManager.instance.initForTesting(testBox);
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('en', ''), // Use English locale for consistent tests
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', ''), Locale('en', '')],
      home: child,
      routes: {
        Routes.player: (context) => const Scaffold(body: Text('Player Screen')),
      },
    );
  }

  group('SearchScreen Widget Tests', () {
    testWidgets('should display search bar and dropdown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Check if search bar is displayed
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Check if search scope dropdown is displayed
      expect(find.byType(DropdownButton<SearchScope>), findsOneWidget);
    });

    testWidgets('should show empty message when no recent searches', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Should show no recent searches message
      expect(find.text('No recent searches'), findsOneWidget);
    });
  });

  group('Search by Lecture Title', () {
    testWidgets('should find lectures by title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(find.byType(TextField), 'Algorithms');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should find the lecture with "Algorithms" in title
      expect(find.text('Introduction to Algorithms'), findsOneWidget);

      // Should not find other lectures
      expect(find.text('Data Structures'), findsNothing);
    });

    testWidgets('should perform case-insensitive search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Search with lowercase
      await tester.enterText(find.byType(TextField), 'algorithms');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should still find the lecture
      expect(find.text('Introduction to Algorithms'), findsOneWidget);
    });

    testWidgets('should show no results for non-existent lecture', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Search for non-existent lecture
      await tester.enterText(find.byType(TextField), 'NonExistent');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should show no results message
      expect(find.text('No search results'), findsOneWidget);
    });
  });

  group('Search Scope Changes', () {
    testWidgets('should default to lecture name scope', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Check default scope
      expect(find.text('Lecture name'), findsOneWidget);
    });

    testWidgets('should search by week when scope changed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Change search scope to week
      await tester.tap(find.byType(DropdownButton<SearchScope>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week').last);
      await tester.pumpAndSettle();

      // Search for "Week 1"
      await tester.enterText(find.byType(TextField), 'Week 1');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should find both lectures with "Week 1"
      expect(find.text('Introduction to Algorithms'), findsOneWidget);
      expect(find.text('Linear Algebra Basics'), findsOneWidget);
    });

    testWidgets('should search by subject when scope changed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Change search scope to subject
      await tester.tap(find.byType(DropdownButton<SearchScope>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Subject name').last);
      await tester.pumpAndSettle();

      // Search for "Mathematics"
      await tester.enterText(find.byType(TextField), 'Mathematics');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should find lecture from Mathematics subject
      expect(find.text('Linear Algebra Basics'), findsOneWidget);
    });
  });

  group('Clear Functionality', () {
    testWidgets('should clear search when clear button tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(find.byType(TextField), 'Algorithms');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should show search results
      expect(find.text('Introduction to Algorithms'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should return to recent searches view
      expect(find.text('No recent searches'), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    testWidgets('should handle special characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Search with special characters
      await tester.enterText(find.byType(TextField), r'@#$%');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should show no results
      expect(find.text('No search results'), findsOneWidget);
    });

    testWidgets('should handle whitespace-only search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Search with whitespace
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Should show recent searches (empty search)
      expect(find.text('No recent searches'), findsOneWidget);
    });

    testWidgets('should display subject titles in results', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Search for a lecture title (not week) to avoid scope issues
      await tester.enterText(find.byType(TextField), 'Algebra');
      await tester.pump(); // Use pump instead of pumpAndSettle
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Give time for search

      // Should find the lecture
      expect(find.text('Linear Algebra Basics'), findsOneWidget);

      // Subject title should be displayed as subtitle
      expect(find.text('Mathematics'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('should navigate to player when lecture tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Search for a lecture
      await tester.enterText(find.byType(TextField), 'Algorithms');
      await tester.pumpAndSettle(); // Wait for search to complete

      // Tap on the lecture
      await tester.tap(find.text('Introduction to Algorithms'));
      await tester.pumpAndSettle();

      // Should navigate to player screen
      expect(find.text('Player Screen'), findsOneWidget);
    });
  });
}
