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

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 7: Static Class
  // (위젯과 관련 없는 순수 유닛 테스트)
  // ------------------------------------------------------------------
  group('7. Static Class (TagColorTheme)', () {
    test('getTagColorTheme works correctly', () {
      // [Given]
      final themeFirst = getTagColorTheme(firstTheme.name);
      final themeSecond = getTagColorTheme(secondTheme.name);

      // [Then] 이름이 일치하는지 확인
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

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 1: UI Initial State Verification
  // ------------------------------------------------------------------
  group('1. UI Initial State Verification', () {
    testWidgets('Verify initial UI elements are rendered correctly', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // AppBar 제목 (AppBar + Card 섹션 제목에 모두 나타남)
      expect(find.text('태그 수정'), findsNWidgets(2));

      // _loadData -> _assignColors 호출 확인 (봄 테마 색상)
      final aiTagPill = findTagPillByName(tester, 'AI');
      expect(aiTagPill.tag.color, getTagColorTheme(firstTheme.name).colors[0]);

      // 테마 선택기 - 모든 테마 이름 텍스트가 있는지 확인
      for (final theme in tagColorThemes) {
        expect(find.text(theme.name), findsOneWidget);
      }

      // 태그 칩 (2개) + 추가 버튼
      expect(find.byType(SelectableTagPill), findsNWidgets(2));
      expect(find.widgetWithText(ActionChip, '+'), findsOneWidget);

      // _syncForm(0) 호출 확인 (첫 번째 태그 'AI'가 폼에 로드됨)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'AI');

      // 삭제 버튼 표시됨
      expect(find.text('태그 삭제'), findsOneWidget);
    });

    testWidgets('Verify delete button is hidden when no tags', (
      WidgetTester tester,
    ) async {
      // [Given] 태그가 0개인 상태로 설정
      when(mockHiveManager.getTags()).thenReturn([]);

      // [When] 화면 펌핑
      await pumpScreen(tester);

      // [Then] 태그 칩 0개, 삭제 버튼 숨김
      expect(find.byType(SelectableTagPill), findsNothing);
      expect(find.text('태그 삭제'), findsNothing);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 2: User Interaction - Theme Selection
  // ------------------------------------------------------------------
  group('2. User Interaction - Theme Selection', () {
    testWidgets('Tapping theme chip updates theme and tag colors', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // [Given] 첫 번째 테마가 적용된 'AI'와 'Web' 태그
      final aiTagPill = findTagPillByName(tester, 'AI');
      final webTagPill = findTagPillByName(tester, 'Web');
      expect(aiTagPill.tag.color, firstTheme.colors[0]);
      expect(webTagPill.tag.color, firstTheme.colors[1]);

      // [Given] 초기 상태에서 두 번째 테마 텍스트가 표시됨
      expect(find.text(secondTheme.name), findsOneWidget);

      // [When] 두 번째 테마 탭
      await tester.tap(find.text(secondTheme.name));
      await tester.pumpAndSettle();

      // [Then] 두 번째 테마가 선택되고 Hive가 호출됨
      verify(mockHiveManager.updateTagColorTheme(secondTheme.name)).called(1);

      // [Then] 모든 태그의 색상이 '비비드' 테마 색상으로 변경됨
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

      // [Given] 첫 번째 테마가 적용된 상태
      final aiTagPill = findTagPillByName(tester, 'AI');
      expect(aiTagPill.tag.color, firstTheme.colors[0]);

      // [When] Radio 버튼 직접 탭 (두 번째 테마의 Radio 위젯 찾기)
      final radioButtons = find.byType(Radio<String>);
      expect(radioButtons, findsWidgets);

      // 두 번째 테마에 해당하는 Radio 버튼 찾기
      final secondRadio = tester
          .widgetList<Radio<String>>(radioButtons)
          .firstWhere((radio) => radio.value == secondTheme.name);

      await tester.tap(find.byWidget(secondRadio));
      await tester.pumpAndSettle();

      // [Then] 두 번째 테마가 선택되고 Hive가 호출됨
      verify(mockHiveManager.updateTagColorTheme(secondTheme.name)).called(1);

      // [Then] 모든 태그의 색상이 두 번째 테마 색상으로 변경됨
      final updatedAiTagPill = findTagPillByName(tester, 'AI');
      expect(updatedAiTagPill.tag.color, secondTheme.colors[0]);
    });

    testWidgets('Theme change reassigns colors to all tags correctly', (
      WidgetTester tester,
    ) async {
      // [Given] 3개 태그가 있는 상태
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

      // [Then] 모든 태그가 첫 번째 테마 색상을 가짐
      for (int i = 0; i < 5; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        expect(tagPill.tag.color, firstTheme.colors[i]);
      }

      // [When] 세 번째 테마로 변경
      await tester.tap(find.text(thirdTheme.name));
      await tester.pumpAndSettle();

      // [Then] 모든 태그가 세 번째 테마 색상으로 변경됨
      for (int i = 0; i < 5; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        expect(tagPill.tag.color, thirdTheme.colors[i]);
        expect(tagPill.tag.color, isNot(firstTheme.colors[i]));
      }
    });

    testWidgets('All 15 tag positions get correct colors from theme', (
      WidgetTester tester,
    ) async {
      // [Given] 15개 태그 생성 (최대 개수)
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

      // [Then] 15개 태그 모두 정확한 위치의 색상을 가짐
      for (int i = 0; i < 15; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        final colorIndex = i % firstTheme.colors.length;
        expect(
          tagPill.tag.color,
          firstTheme.colors[colorIndex],
          reason: 'Tag $i should have color at index $i from first theme',
        );
      }

      // [When] 두 번째 테마로 변경
      await tester.tap(find.text(secondTheme.name));
      await tester.pumpAndSettle();

      // [Then] 15개 태그 모두 두 번째 테마의 정확한 위치 색상으로 변경됨
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
      // [Given] 15개 태그 생성
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

      // [When/Then] 5개 테마 모두 순회하며 색상 배정 확인
      for (final theme in tagColorThemes) {
        // [When] 테마 변경
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

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 3: User Interaction - Tag Selection & Editing
  // ------------------------------------------------------------------
  group('3. User Interaction - Tag Selection & Editing', () {
    testWidgets('Tapping tag chip updates form', (tester) async {
      await pumpScreen(tester);

      // [Given] 'AI'가 선택됨
      expect(findTagPillByName(tester, 'AI').selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'AI',
      );

      // [When] 'Web' 태그 탭 - '#Web' 텍스트를 찾아서 탭
      await tester.tap(find.text('#Web'));
      await tester.pumpAndSettle();

      // [Then] 'Web'이 선택되고 폼이 업데이트됨
      expect(findTagPillByName(tester, 'AI').selected, isFalse);
      expect(findTagPillByName(tester, 'Web').selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Web',
      );
    });

    testWidgets('Apply button updates tag name', (tester) async {
      await pumpScreen(tester);

      // [Given] 'AI'가 선택됨
      expect(find.text('AI-Renamed'), findsNothing);

      // [When] 이름 변경 후 '이름 적용'
      await tester.enterText(find.byType(TextField), 'AI-Renamed');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      // [Then] 태그 칩의 이름이 변경됨
      expect(find.text('AI'), findsNothing);
      expect(find.text('AI-Renamed'), findsOneWidget);
    });

    testWidgets('Apply with empty name shows snackbar', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), '   '); // 공백
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
      await pumpScreen(tester); // 'AI'가 선택됨
      await tester.enterText(find.byType(TextField), 'Web'); // 'Web' (중복)
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

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 4: User Interaction - Tag Creation
  // ------------------------------------------------------------------
  group('4. User Interaction - Tag Creation', () {
    testWidgets('Add tag button creates new tag', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SelectableTagPill), findsNWidgets(2));

      // [When] '+' 버튼 탭
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then] 새 태그가 추가되고 선택됨
      expect(find.byType(SelectableTagPill), findsNWidgets(3));
      expect(find.text('#새 태그'), findsOneWidget);
      final newTagPill = findTagPillByName(tester, '새 태그');
      expect(newTagPill.selected, isTrue);

      // [Then] 새 태그의 색상이 현재 테마('봄')의 세 번째 색상이어야 함
      final springTheme = getTagColorTheme('봄');
      expect(newTagPill.tag.color, springTheme.colors[2]);

      // [Then] 폼이 초기화됨
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('Add tag generates non-duplicate name', (tester) async {
      // [Given] '새 태그'가 이미 존재함
      final tags = [
        HiveTag(id: 't1', name: 'AI', color: firstTheme.colors[0]),
        HiveTag(id: 't2', name: 'Web', color: firstTheme.colors[1]),
        HiveTag(id: 't3', name: '새 태그', color: firstTheme.colors[2]),
      ];
      when(mockHiveManager.getTags()).thenReturn(tags);

      await pumpScreen(tester);

      // [When] '+' 버튼 탭
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then] '새 태그 (1)'이 생성됨
      expect(find.text('#새 태그 (1)'), findsOneWidget);

      // [Then] 새 태그의 색상이 현재 테마의 네 번째 색상이어야 함
      final newTagPill = findTagPillByName(tester, '새 태그 (1)');
      expect(newTagPill.tag.color, firstTheme.colors[3]);
    });

    testWidgets('Add tag respects 15 tag limit', (tester) async {
      // [Given] 15개 태그 추가
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

      // [When] '+' 버튼 탭 (화면 밖에 있을 수 있으므로 스크롤)
      await tester.ensureVisible(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then] 스낵바 표시, 태그 추가 안 됨
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('태그는 최대 15개까지 생성할 수 있습니다.'), findsOneWidget);
      expect(find.byType(SelectableTagPill), findsNWidgets(15));
    });

    testWidgets('Tag color cycles when adding 16th+ tag (after deleting)', (
      WidgetTester tester,
    ) async {
      // [Given] 14개 태그 추가
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

      // [When] '+' 버튼 탭 (15번째 태그 추가)
      await tester.ensureVisible(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then] 15번째 태그의 색상이 올바른 색상
      // 14개 태그가 있을 때 15번째 태그는 인덱스 14이므로 14 % 10 = 4
      final newTagPill = findTagPillByName(tester, '새 태그');
      final expectedColorIndex = 14 % firstTheme.colors.length;
      expect(newTagPill.tag.color, firstTheme.colors[expectedColorIndex]);

      // [When] 이름 변경 후 한 번 더 추가 시도 (16번째 태그 - 순환 테스트)
      await tester.enterText(find.byType(TextField), 'Tag 14');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      // 15개 제한이므로 더 이상 추가 불가
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

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 5: User Interaction - Tag Deletion
  // ------------------------------------------------------------------
  group('5. User Interaction - Tag Deletion', () {
    testWidgets('Delete tag (no warning) works', (tester) async {
      // [Given] 5개 태그 생성
      final tags = List.generate(
        5,
        (i) => HiveTag(id: 't$i', name: 'Tag$i', color: firstTheme.colors[i]),
      );

      // Tag0과 Tag1은 과목에서 사용 중
      final subjects = [
        HiveSubject(id: 's1', title: 'Subject A', tagIds: ['t0']),
        HiveSubject(id: 's2', title: 'Subject B', tagIds: ['t1']),
      ];

      when(mockHiveManager.getTags()).thenReturn(tags);
      when(mockHiveManager.getSubjects()).thenReturn(subjects);

      await pumpScreen(tester);

      // [Given] 초기 상태: 5개 태그 모두 정확한 색상을 가짐
      expect(find.byType(SelectableTagPill), findsNWidgets(5));
      for (int i = 0; i < 5; i++) {
        expect(
          findTagPillByName(tester, 'Tag$i').tag.color,
          firstTheme.colors[i],
        );
      }

      // [When] 중간 태그(Tag2) 삭제
      await tester.tap(find.text('#Tag2'));
      await tester.pumpAndSettle();

      // 삭제 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then] 경고 없이 즉시 삭제됨 (Tag2는 사용되지 않음)
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#Tag2'), findsNothing);
      expect(find.byType(SelectableTagPill), findsNWidgets(4));

      // [Then] 삭제 후 색상이 재할당됨
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

      // [When] 마지막 태그(Tag4) 삭제
      await tester.tap(find.text('#Tag4'));
      await tester.pumpAndSettle();

      // 삭제 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then] 남은 태그들의 색상이 여전히 정확함
      expect(find.byType(SelectableTagPill), findsNWidgets(3));
      expect(findTagPillByName(tester, 'Tag0').tag.color, firstTheme.colors[0]);
      expect(findTagPillByName(tester, 'Tag1').tag.color, firstTheme.colors[1]);
      expect(findTagPillByName(tester, 'Tag3').tag.color, firstTheme.colors[2]);

      // [Then] 선택이 이전 인덱스로 이동함
      expect(findTagPillByName(tester, 'Tag3').selected, isTrue);
    });

    testWidgets('Delete tag (with warning) shows dialog and handles No/Yes', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // [Given] 'AI' 태그(s1에서 사용 중)가 선택됨
      expect(findTagPillByName(tester, 'AI').selected, isTrue);

      // [When] '태그 삭제' 탭 (화면 밖에 있을 수 있으므로 스크롤)
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then] 경고 다이얼로그가 뜨고, 'Subject A'가 언급됨
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('경고'), findsOneWidget);
      expect(find.textContaining('Subject A'), findsOneWidget);

      // [When] '아니오' 탭
      await tester.tap(find.text('아니오'));
      await tester.pumpAndSettle();

      // [Then] 다이얼로그 닫힘, 태그 삭제 안 됨
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#AI'), findsOneWidget);

      // [When] 다시 '태그 삭제' 후 '예' 탭
      await tester.ensureVisible(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('예'));
      await tester.pumpAndSettle();

      // [Then] 다이얼로그 닫힘, 태그 삭제됨
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#AI'), findsNothing);
      expect(find.byType(SelectableTagPill), findsNWidgets(1));

      // [Then] 선택이 0번째 태그('Web')로 이동함
      expect(findTagPillByName(tester, 'Web').selected, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 6: Data Persistence & Navigation
  // ------------------------------------------------------------------
  group('6. Data Persistence & Navigation', () {
    testWidgets('Popping screen saves data via _onWillPop (PopScope)', (
      WidgetTester tester,
    ) async {
      // [Given] 네비게이터 스택 설정
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

      // [When] 1. 두 번째 테마로 변경
      await tester.tap(find.text(secondTheme.name));
      await tester.pumpAndSettle();

      // [When] 2. 'AI' 태그 이름 변경
      await tester.enterText(find.byType(TextField), 'AI-Renamed');
      await tester.pumpAndSettle();

      // 버튼이 화면 밖에 있을 수 있으므로 스크롤
      await tester.ensureVisible(find.text('이름 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이름 적용'));
      await tester.pumpAndSettle();

      // [When] 3. 'Web' 태그 삭제 (s2에서 사용 중)
      await tester.tap(find.text('#Web')); // 'Web' 선택
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('예')); // 경고 확인
      await tester.pumpAndSettle();

      expect(find.text('#Web'), findsNothing); // 로컬에서 삭제됨

      // [When] 4. 뒤로가기 버튼(AppBar) 탭 (PopScope 트리거)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // [Then] 5. 화면이 Pop되고, Hive가 업데이트됨
      expect(find.byType(TagsEditScreen), findsNothing);
      expect(find.text('Go'), findsOneWidget);

      // Hive.saveTags가 호출되었는지 확인
      final captured = verify(mockHiveManager.saveTags(captureAny)).captured;
      expect(captured, isNotEmpty);

      // 마지막으로 저장된 태그 목록 검증
      final savedTags = captured.last as List<HiveTag>;
      expect(savedTags.length, 1);
      expect(savedTags.first.name, 'AI-Renamed');

      // Hive.updateTagColorTheme이 호출되었는지 확인
      verify(
        mockHiveManager.updateTagColorTheme(secondTheme.name),
      ).called(greaterThan(0));
    });
  });
}
