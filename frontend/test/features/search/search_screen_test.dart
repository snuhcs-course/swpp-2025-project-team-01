import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/features/search/search_screen.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';

import 'search_screen_test.mocks.dart';

@GenerateMocks([HiveManager])
void main() {
  late MockHiveManager mockHive;

  setUp(() {
    mockHive = MockHiveManager();
  });

  Future<void> pumpSearchScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {Routes.player: (_) => const SizedBox()},
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchScreen(hiveManager: mockHive),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders screen and shows AppBar title', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    await pumpSearchScreen(tester);

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('default state is not searching and shows recent section', (
    tester,
  ) async {
    when(mockHive.getRecentSearches()).thenReturn(['RNA', 'Protein']);
    await pumpSearchScreen(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Recent'), findsOneWidget);
  });

  testWidgets('shows no recent placeholder if list empty', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    await pumpSearchScreen(tester);
    expect(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(SearchScreen)),
        ).noRecentSearches,
      ),
      findsOneWidget,
    );
  });

  testWidgets('typing triggers live search without saving', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 'sub1', title: 'Genetics')]);
    when(mockHive.getLecturesBySubject('sub1')).thenReturn([
      HiveLecture(
        id: 'lec1',
        title: 'Mutation 101',
        weekLabel: 'Week 1',
        subjectId: 'sub1',
        duration: 0,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), 'mut');
    await tester.pump();

    verifyNever(mockHive.addRecentSearch('mut'));
    expect(find.textContaining('Mutation 101'), findsOneWidget);
  });

  testWidgets('submit triggers search and saves recent', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 's1', title: 'Bio')]);
    when(mockHive.getLecturesBySubject('s1')).thenReturn([
      HiveLecture(
        id: 'l1',
        title: 'CRISPR Intro',
        weekLabel: 'Week A',
        subjectId: 's1',
        duration: 0,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), 'crisp');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    verify(mockHive.addRecentSearch('crisp')).called(1);
    expect(find.textContaining('CRISPR Intro'), findsOneWidget);
  });

  testWidgets('filters out Untitled lecture', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(mockHive.getSubjects()).thenReturn([HiveSubject(id: 'x', title: 'X')]);
    when(mockHive.getLecturesBySubject('x')).thenReturn([
      HiveLecture(
        id: 'bad',
        title: 'Untitled',
        weekLabel: 'Week',
        subjectId: 'x',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
      HiveLecture(
        id: 'good',
        title: 'Valid',
        weekLabel: 'Week',
        subjectId: 'x',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();

    expect(find.text('Valid'), findsOneWidget);
    expect(find.text('Untitled'), findsNothing);
  });

  testWidgets('clear button resets state', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn(['Tail']);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 's', title: 'BioTech')]);
    when(mockHive.getLecturesBySubject('s')).thenReturn([
      HiveLecture(
        id: '1',
        title: 'polyA tails',
        weekLabel: 'Week 2',
        subjectId: 's',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), 'polyA');
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.textContaining('polyA'), findsNothing);
    expect(find.text('Tail'), findsOneWidget);
  });

  testWidgets('dropdown changes scope (week) and triggers search', (
    tester,
  ) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 's', title: 'CompBio')]);
    when(mockHive.getLecturesBySubject('s')).thenReturn([
      HiveLecture(
        id: '1',
        title: 'SVM Basics',
        weekLabel: 'Week 3',
        subjectId: 's',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), '3');
    await tester.pump(); // search by lecture initially yields nothing

    await tester.tap(find.byType(DropdownButton<SearchScope>));
    await tester.pump();
    await tester.tap(find.text('Week'));
    await tester.pump();

    expect(find.textContaining('SVM Basics'), findsOneWidget);
  });

  testWidgets('dropdown changes scope (subject) and triggers search', (
    tester,
  ) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 's', title: 'CompBio')]);
    when(mockHive.getLecturesBySubject('s')).thenReturn([
      HiveLecture(
        id: '1',
        title: 'SVM Basics',
        weekLabel: 'Week 3',
        subjectId: 's',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), 'CompBio');
    await tester.pump(); // search by lecture initially yields nothing

    await tester.tap(find.byType(DropdownButton<SearchScope>));
    await tester.pump();
    await tester.tap(find.text('Subject name'));
    await tester.pump();

    expect(find.textContaining('SVM Basics'), findsOneWidget);
  });

  testWidgets('tapping recent inserts text and performs search', (
    tester,
  ) async {
    when(mockHive.getRecentSearches()).thenReturn(['Prime']);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 's', title: 'Poly')]);
    when(mockHive.getLecturesBySubject('s')).thenReturn([
      HiveLecture(
        id: '1',
        title: 'Prime Editing',
        weekLabel: 'Week 9',
        subjectId: 's',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.tap(find.text('Prime'));
    await tester.pump();

    expect(find.textContaining('Prime Editing'), findsOneWidget);
  });

  testWidgets('no search results placeholder shown', (tester) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(mockHive.getSubjects()).thenReturn([]);
    await pumpSearchScreen(tester);

    await tester.enterText(find.byType(TextField), 'something');
    await tester.pump();

    expect(find.text('No search results'), findsOneWidget);
  });

  testWidgets('tapping search result navigates to player with arguments', (
    tester,
  ) async {
    when(mockHive.getRecentSearches()).thenReturn([]);
    when(
      mockHive.getSubjects(),
    ).thenReturn([HiveSubject(id: 's', title: 'Math')]);
    when(mockHive.getLecturesBySubject('s')).thenReturn([
      HiveLecture(
        id: 'lecX',
        title: 'Matrix',
        weekLabel: 'Week 4',
        subjectId: 's',
        duration: 5,
        originalAudioPath: '',
        ttsAudioPath: '',
      ),
    ]);

    await pumpSearchScreen(tester);
    await tester.enterText(find.byType(TextField), 'mat');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.tap(find.textContaining('Matrix'));
    await tester.pumpAndSettle();

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
