import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/tags/tags_edit_screen.dart';
import 'package:re_view/shared/widgets.dart';

import 'tags_edit_screen_test.mocks.dart';

// ------------------------------------------------------------------
// Mock 클래스 생성
// ------------------------------------------------------------------
@GenerateMocks([HiveManager, AppSettings])
void main() {
  // 동적으로 테마 가져오기
  // 테마 리스트가 비어 있지 않다고 가정 (테스트의 기본 전제)
  final firstTheme = tagColorThemes[0];

  // 일부 테스트를 위해 최소 2개 이상의 테마가 있다고 가정하고,
  // 1개일 경우를 대비해 안전장치 추가
  final secondTheme = tagColorThemes.length > 1
      ? tagColorThemes[1]
      : firstTheme;

  // 일부 테스트를 위해 최소 3개 이상의 테마가 있다고 가정하고,
  // 1개일 경우를 대비해 안전장치 추가
  final thirdTheme = tagColorThemes.length > 2 ? tagColorThemes[2] : firstTheme;

  // 위젯과 관련 없는 순수 유닛 테스트
  group('7. Static Class (TagColorTheme)', () {
    test('getTagColorTheme works correctly', () {
      // [Given]
      final themeFirst = getTagColorTheme(firstTheme.name);
      final themeSecond = getTagColorTheme(secondTheme.name);

      // [Then]
      expect(themeFirst.name, firstTheme.name);
      expect(themeSecond.name, secondTheme.name);

      // [Given] 존재하지 않는 테마
      final fallback = getTagColorTheme('non_existent_theme');

      // [Then] 첫 번째 테마로 대체되는지 확인
      expect(fallback.name, firstTheme.name);
      expect(fallback, equals(tagColorThemes[0]));
    });
  });

  // --- 위젯 테스트 설정 (Setup) ---
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHiveManager mockHiveManager;
  late MockAppSettings mockSettings;

  setUp(() {
    mockHiveManager = MockHiveManager();
    mockSettings = MockAppSettings();

    // 기본 모킹 설정
    when(mockHiveManager.settings).thenReturn(mockSettings);
    when(mockSettings.tagColorTheme).thenReturn(firstTheme.name);

    // 테스트 데이터 초기화
    final tags = [
      HiveTag(id: 't1', name: 'AI', color: firstTheme.colors[0]),
      HiveTag(id: 't2', name: 'Web', color: firstTheme.colors[1]),
    ];

    final subjects = [
      HiveSubject(id: 's1', title: 'Subject A', tagIds: ['t1']),
      HiveSubject(id: 's2', title: 'Subject B', tagIds: ['t2']),
    ];

    when(mockHiveManager.getTags()).thenReturn(tags);
    when(mockHiveManager.getSubjects()).thenReturn(subjects);
    when(mockHiveManager.updateTagColorTheme(any)).thenAnswer((_) async {});
    when(mockHiveManager.saveTags(any)).thenAnswer((_) async {});
  });

  // --- 테스트용 헬퍼 함수: 위젯 빌드 ---
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'), // 'ko'로 고정
      home: child,
    );
  }

  // --- 테스트용 헬퍼 함수: 화면 펌핑 ---
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(TagsEditScreen(hiveManager: mockHiveManager)),
    );
    await tester.pumpAndSettle();
  }

  // --- 테스트용 헬퍼 함수: SelectableTagPill 찾기 ---
  SelectableTagPill findTagPillByName(WidgetTester tester, String name) {
    final pills = tester.widgetList<SelectableTagPill>(
      find.byType(SelectableTagPill),
    );
    return pills.firstWhere((pill) => pill.tag.name == name);
  }

  group('1. UI Initial State Verification', () {
    testWidgets('Verify initial UI elements are rendered correctly', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('태그 수정'), findsNWidgets(2));
      final aiTagPill = findTagPillByName(tester, 'AI');

      expect(aiTagPill.tag.color, getTagColorTheme(firstTheme.name).colors[0]);

      for (final theme in tagColorThemes) {
        expect(find.text(theme.name), findsOneWidget);
      }

      expect(find.byType(SelectableTagPill), findsNWidgets(2));
      expect(find.widgetWithText(ActionChip, '+'), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'AI');

      expect(find.text('태그 삭제'), findsOneWidget);
    });

    testWidgets('Verify delete button is hidden when no tags', (
      WidgetTester tester,
    ) async {
      // [Given]
      when(mockHiveManager.getTags()).thenReturn([]);

      // [When]
      await pumpScreen(tester);

      // [Then]
      expect(find.byType(SelectableTagPill), findsNothing);
      expect(find.text('태그 삭제'), findsNothing);
    });
  });

  group('2. User Interaction - Theme Selection', () {
    testWidgets('Tapping theme chip updates theme and tag colors', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // [Given]
      final aiTagPill = findTagPillByName(tester, 'AI');
      final webTagPill = findTagPillByName(tester, 'Web');
      expect(aiTagPill.tag.color, firstTheme.colors[0]);
      expect(webTagPill.tag.color, firstTheme.colors[1]);

      // [Given]
      expect(find.text(secondTheme.name), findsOneWidget);

      // [When]
      await tester.tap(find.text(secondTheme.name));
      await tester.pumpAndSettle();

      // [Then]
      verify(mockHiveManager.updateTagColorTheme(secondTheme.name)).called(1);

      // [Then]
      final updatedAiTagPill = findTagPillByName(tester, 'AI');
      final updatedWebTagPill = findTagPillByName(tester, 'Web');
      expect(updatedAiTagPill.tag.color, secondTheme.colors[0]);
      expect(updatedWebTagPill.tag.color, secondTheme.colors[1]);
      expect(updatedAiTagPill.tag.color, isNot(firstTheme.colors[0]));
      expect(updatedWebTagPill.tag.color, isNot(firstTheme.colors[1]));
    });

    testWidgets('Tapping radio button directly updates theme and tag colors', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // [Given]
      final aiTagPill = findTagPillByName(tester, 'AI');
      expect(aiTagPill.tag.color, firstTheme.colors[0]);

      // [When]
      final radioButtons = find.byType(Radio<String>);
      expect(radioButtons, findsWidgets);

      final secondRadio = tester
          .widgetList<Radio<String>>(radioButtons)
          .firstWhere((radio) => radio.value == secondTheme.name);

      await tester.tap(find.byWidget(secondRadio));
      await tester.pumpAndSettle();

      // [Then]
      verify(mockHiveManager.updateTagColorTheme(secondTheme.name)).called(1);

      // [Then]
      final updatedAiTagPill = findTagPillByName(tester, 'AI');
      expect(updatedAiTagPill.tag.color, secondTheme.colors[0]);
    });

    testWidgets('Theme change reassigns colors to all tags correctly', (
      WidgetTester tester,
    ) async {
      // [Given]
      final tags = List.generate(
        5,
        (i) => HiveTag(
          id: 't${i + 1}',
          name: 'Tag $i',
          color: firstTheme.colors[i],
        ),
      );
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);

      // [Then]
      for (int i = 0; i < 5; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        expect(tagPill.tag.color, firstTheme.colors[i]);
      }

      // [When]
      await tester.tap(find.text(thirdTheme.name));
      await tester.pumpAndSettle();

      // [Then]
      for (int i = 0; i < 5; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        expect(tagPill.tag.color, thirdTheme.colors[i]);
        expect(tagPill.tag.color, isNot(firstTheme.colors[i]));
      }
    });

    testWidgets('All 15 tag positions get correct colors from theme', (
      WidgetTester tester,
    ) async {
      // [Given]
      final tags = List.generate(15, (i) {
        final colorIndex = i % firstTheme.colors.length;
        return HiveTag(
          id: 't${i + 1}',
          name: 'Tag $i',
          color: firstTheme.colors[colorIndex],
        );
      });
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);

      // [Then]
      for (int i = 0; i < 15; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        final colorIndex = i % firstTheme.colors.length;
        expect(
          tagPill.tag.color,
          firstTheme.colors[colorIndex],
          reason: 'Tag $i should have color at index $i from first theme',
        );
      }

      // [When]
      await tester.tap(find.text(secondTheme.name));
      await tester.pumpAndSettle();

      // [Then]
      for (int i = 0; i < 15; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        final colorIndex = i % secondTheme.colors.length;
        final oldColorIndex = i % firstTheme.colors.length;
        expect(
          tagPill.tag.color,
          secondTheme.colors[colorIndex],
          reason: 'Tag $i should have color at index $i from second theme',
        );
        expect(
          tagPill.tag.color,
          isNot(firstTheme.colors[oldColorIndex]),
          reason: 'Tag $i color should change from first to second theme',
        );
      }
    });

    testWidgets('All 5 themes apply colors correctly to 15 tags', (
      WidgetTester tester,
    ) async {
      // [Given]
      final initialTheme = getTagColorTheme(firstTheme.name);
      final tags = List.generate(15, (i) {
        final colorIndex = i % initialTheme.colors.length;
        return HiveTag(
          id: 't${i + 1}',
          name: 'Tag $i',
          color: initialTheme.colors[colorIndex],
        );
      });
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);

      for (final theme in tagColorThemes) {
        // [When]
        final themeChipFinder = find.text(theme.name);
        await tester.ensureVisible(themeChipFinder);
        await tester.tap(themeChipFinder);
        await tester.pumpAndSettle();

        // [Then] 15개 태그 모두 해당 테마의 정확한 색상을 가짐
        for (int i = 0; i < 15; i++) {
          final tagPill = findTagPillByName(tester, 'Tag $i');
          final colorIndex = i % theme.colors.length;
          expect(
            tagPill.tag.color,
            theme.colors[colorIndex],
            reason:
                'Tag $i should have color[$colorIndex] from ${theme.name} theme (${theme.colors[colorIndex].toRadixString(16)})',
          );
        }
      }
    });
  });

  group('3. User Interaction - Tag Selection & Editing', () {
    testWidgets('Tapping tag chip updates form', (tester) async {
      await pumpScreen(tester);

      // [Given]
      expect(findTagPillByName(tester, 'AI').selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'AI',
      );

      // [When]
      await tester.tap(find.text('#Web'));
      await tester.pumpAndSettle();

      // [Then]
      expect(findTagPillByName(tester, 'AI').selected, isFalse);
      expect(findTagPillByName(tester, 'Web').selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Web',
      );
    });

    testWidgets('Apply button updates tag name', (tester) async {
      await pumpScreen(tester);

      // [Given]
      expect(find.text('AI-Renamed'), findsNothing);

      // [When]
      await tester.enterText(find.byType(TextField), 'AI-Renamed');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.text('AI'), findsNothing);
      expect(find.text('AI-Renamed'), findsOneWidget);
    });

    testWidgets('Apply with empty name shows snackbar', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('태그 이름을 입력해주세요.'), findsOneWidget);
    });

    testWidgets('Apply with duplicate name shows snackbar', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'Web');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('이미 사용 중인 이름입니다. 다른 이름을 입력해주세요.'), findsOneWidget);
    });
  });

  group('4. User Interaction - Tag Creation', () {
    testWidgets('Add tag button creates new tag', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SelectableTagPill), findsNWidgets(2));

      // [When]
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(SelectableTagPill), findsNWidgets(3));
      expect(find.text('#새 태그'), findsOneWidget);
      final newTagPill = findTagPillByName(tester, '새 태그');
      expect(newTagPill.selected, isTrue);

      // [Then]
      final springTheme = getTagColorTheme('봄');
      expect(newTagPill.tag.color, springTheme.colors[2]);

      // [Then]
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('Add tag generates non-duplicate name', (tester) async {
      // [Given]
      final tags = [
        HiveTag(id: 't1', name: 'AI', color: firstTheme.colors[0]),
        HiveTag(id: 't2', name: 'Web', color: firstTheme.colors[1]),
        HiveTag(id: 't3', name: '새 태그', color: firstTheme.colors[2]),
      ];
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);

      // [When]
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.text('#새 태그 (1)'), findsOneWidget);

      // [Then]
      final newTagPill = findTagPillByName(tester, '새 태그 (1)');
      expect(newTagPill.tag.color, firstTheme.colors[3]);
    });

    testWidgets('Add tag respects 15 tag limit', (tester) async {
      // [Given]
      final tags = List.generate(15, (i) {
        final colorIndex = i % firstTheme.colors.length;
        return HiveTag(
          id: 't${i + 1}',
          name: 'Tag $i',
          color: firstTheme.colors[colorIndex],
        );
      });
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);
      expect(find.byType(SelectableTagPill), findsNWidgets(15));

      // [When]
      await tester.ensureVisible(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('태그는 최대 15개까지 생성할 수 있습니다.'), findsOneWidget);
      expect(find.byType(SelectableTagPill), findsNWidgets(15));
    });

    testWidgets('Tag color cycles when adding 16th+ tag (after deleting)', (
      WidgetTester tester,
    ) async {
      // [Given]
      final tags = List.generate(14, (i) {
        final colorIndex = i % firstTheme.colors.length;
        return HiveTag(
          id: 't${i + 1}',
          name: 'Tag $i',
          color: firstTheme.colors[colorIndex],
        );
      });
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);

      // [When]
      await tester.ensureVisible(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then]
      final newTagPill = findTagPillByName(tester, '새 태그');
      final expectedColorIndex = 14 % firstTheme.colors.length;
      expect(newTagPill.tag.color, firstTheme.colors[expectedColorIndex]);

      // [When]
      await tester.enterText(find.byType(TextField), 'Tag 14');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();
      expect(
        find.text('태그는 최대 15개까지 생성할 수 있습니다.'),
        findsOneWidget,
        reason: '스낵바가 표시되어야 합니다.',
      );
      expect(
        find.byType(SelectableTagPill),
        findsNWidgets(15),
        reason: '태그 개수는 15개를 초과할 수 없습니다.',
      );
    });
  });

  group('5. User Interaction - Tag Deletion', () {
    testWidgets('Delete tag (no warning) works', (tester) async {
      // [Given]
      final tags = List.generate(
        5,
        (i) => HiveTag(id: 't$i', name: 'Tag$i', color: firstTheme.colors[i]),
      );

      final subjects = [
        HiveSubject(id: 's1', title: 'Subject A', tagIds: ['t0']),
        HiveSubject(id: 's2', title: 'Subject B', tagIds: ['t1']),
      ];

      when(mockHiveManager.getTags()).thenReturn(tags);
      when(mockHiveManager.getSubjects()).thenReturn(subjects);

      await pumpScreen(tester);

      // [Given]
      expect(find.byType(SelectableTagPill), findsNWidgets(5));
      for (int i = 0; i < 5; i++) {
        expect(
          findTagPillByName(tester, 'Tag$i').tag.color,
          firstTheme.colors[i],
        );
      }

      // [When]
      await tester.tap(find.text('#Tag2'));
      await tester.pumpAndSettle();

      // 삭제 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#Tag2'), findsNothing);
      expect(find.byType(SelectableTagPill), findsNWidgets(4));

      // [Then]
      expect(findTagPillByName(tester, 'Tag0').tag.color, firstTheme.colors[0]);
      expect(findTagPillByName(tester, 'Tag1').tag.color, firstTheme.colors[1]);
      expect(
        findTagPillByName(tester, 'Tag3').tag.color,
        firstTheme.colors[2],
        reason: 'Tag3 should be reassigned to color[2] after Tag2 deletion',
      );
      expect(
        findTagPillByName(tester, 'Tag4').tag.color,
        firstTheme.colors[3],
        reason: 'Tag4 should be reassigned to color[3] after Tag2 deletion',
      );

      // [When]
      await tester.tap(find.text('#Tag4'));
      await tester.pumpAndSettle();

      // 삭제 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(SelectableTagPill), findsNWidgets(3));
      expect(findTagPillByName(tester, 'Tag0').tag.color, firstTheme.colors[0]);
      expect(findTagPillByName(tester, 'Tag1').tag.color, firstTheme.colors[1]);
      expect(findTagPillByName(tester, 'Tag3').tag.color, firstTheme.colors[2]);

      // [Then]
      expect(findTagPillByName(tester, 'Tag3').selected, isTrue);
    });

    testWidgets('Delete tag (with warning) shows dialog and handles No/Yes', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // [Given]
      expect(findTagPillByName(tester, 'AI').selected, isTrue);

      // [When]
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('경고'), findsOneWidget);
      expect(find.textContaining('Subject A'), findsOneWidget);

      // [When]
      await tester.tap(find.text('아니오'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#AI'), findsOneWidget);

      // [When]
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('예'));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#AI'), findsNothing);
      expect(find.byType(SelectableTagPill), findsNWidgets(1));

      // [Then]
      expect(findTagPillByName(tester, 'Web').selected, isTrue);
    });
  });

  group('6. Data Persistence & Navigation', () {
    testWidgets('Popping screen saves data via _onWillPop (PopScope)', (
      WidgetTester tester,
    ) async {
      // [Given]
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TagsEditScreen(hiveManager: mockHiveManager),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(TagsEditScreen), findsOneWidget);

      // [When]
      await tester.tap(find.text(secondTheme.name));
      await tester.pumpAndSettle();

      // [When]
      await tester.enterText(find.byType(TextField), 'AI-Renamed');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      // [When]
      await tester.tap(find.text('#Web'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('예'));
      await tester.pumpAndSettle();

      expect(find.text('#Web'), findsNothing);

      // [When]
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // [Then]
      expect(find.byType(TagsEditScreen), findsNothing);
      expect(find.text('Go'), findsOneWidget);

      final captured = verify(mockHiveManager.saveTags(captureAny)).captured;
      expect(captured, isNotEmpty);

      final savedTags = captured.last as List<HiveTag>;
      expect(savedTags.length, 1);
      expect(savedTags.first.name, 'AI-Renamed');

      verify(
        mockHiveManager.updateTagColorTheme(secondTheme.name),
      ).called(greaterThan(0));
    });
  });
}
