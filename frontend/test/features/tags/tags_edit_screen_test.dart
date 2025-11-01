import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/tags/tags_edit_screen.dart';
import 'package:re_view/shared/widgets.dart';

// ------------------------------------------------------------------
// 1. Fake/Stub 클래스 정의
// ------------------------------------------------------------------

/// AppSettings를 흉내내는 가짜 클래스
class FakeAppSettings implements AppSettings {
  FakeAppSettings({
    this.language = 'ko',
    this.theme = 'system',
    this.accessibilityHighContrast = false,
    this.accessibilityReduceMotion = false,
    this.accessibilityEmphasizeCaptions = false,
    this.ttsGender = '남성',
    this.tagColorTheme = '봄', // 기본값 '봄'
    this.hasCompletedTutorial = false,
  });

  @override
  bool accessibilityEmphasizeCaptions;
  @override
  bool accessibilityHighContrast;
  @override
  bool accessibilityReduceMotion;
  @override
  String language;
  @override
  String tagColorTheme;
  @override
  String theme;
  @override
  String ttsGender;
  @override
  bool hasCompletedTutorial;
}

/// HiveManager를 흉내내는 가짜 클래스
class FakeHiveManager extends Fake implements HiveManager {
  FakeHiveManager() {
    _fakeSettings = FakeAppSettings();
  }

  late FakeAppSettings _fakeSettings;

  // --- 테스트용 데이터 ---
  Map<String, HiveTag> fakeTags = {};
  Map<String, HiveSubject> fakeSubjects = {};

  // --- 호출 검증용 변수 ---
  String? updatedTagColorTheme;
  List<HiveTag>? savedTags;

  void reset() {
    fakeTags.clear();
    fakeSubjects.clear();
    _fakeSettings = FakeAppSettings();
    updatedTagColorTheme = null;
    savedTags = null;
  }

  // --- 가짜 데이터 추가 헬퍼 ---
  void addFakeTag(HiveTag t) => fakeTags[t.id] = t;
  void addFakeSubject(HiveSubject s) => fakeSubjects[s.id] = s;

  // --- Overridden Methods ---
  @override
  AppSettings get settings => _fakeSettings;

  @override
  List<HiveTag> getTags() => fakeTags.values.toList();

  @override
  List<HiveSubject> getSubjects({
    bool favoritesOnly = false,
    List<String> filterTagIds = const [],
  }) {
    return fakeSubjects.values.toList();
  }

  @override
  Future<void> updateTagColorTheme(String theme) async {
    updatedTagColorTheme = theme;
    _fakeSettings.tagColorTheme = theme; // 내부 상태도 업데이트
  }

  @override
  Future<void> saveTags(List<HiveTag> tags) async {
    savedTags = tags;
    // 시뮬레이션을 위해 내부 데이터도 업데이트
    fakeTags.clear();
    for (var tag in tags) {
      fakeTags[tag.id] = tag;
    }
  }

  // --- ChangeNotifier 흉내 ---
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

// ------------------------------------------------------------------
// 2. 테스트 Main
// ------------------------------------------------------------------
void main() {
  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 7: Static Class
  // (위젯과 관련 없는 순수 유닛 테스트)
  // ------------------------------------------------------------------
  group('7. Static Class (TagColorTheme)', () {
    test('getTagColorTheme works correctly', () {
      // [Given] '봄'과 '비비드' 테마
      final spring = getTagColorTheme('봄');
      final vivid = getTagColorTheme('비비드');

      // [Then] 이름이 일치하는지 확인
      expect(spring.name, '봄');
      expect(vivid.name, '비비드');

      // [Given] 존재하지 않는 테마
      final fallback = getTagColorTheme('non_existent_theme');

      // [Then] 첫 번째 테마('봄')로 대체되는지 확인
      expect(fallback.name, '봄');
      expect(fallback, equals(tagColorThemes[0]));
    });
  });

  // --- 위젯 테스트 설정 (Setup) ---
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHiveManager fakeHiveManager;

  setUp(() {
    fakeHiveManager = FakeHiveManager();
    // 테스트 데이터 초기화
    // 색상은 실제 로직처럼 '봄' 테마의 색상을 사용
    final springTheme = getTagColorTheme('봄');
    fakeHiveManager.addFakeTag(
      HiveTag(id: 't1', name: 'AI', color: springTheme.colors[0]),
    );
    fakeHiveManager.addFakeTag(
      HiveTag(id: 't2', name: 'Web', color: springTheme.colors[1]),
    );
    // 'AI' 태그를 사용하는 과목
    fakeHiveManager.addFakeSubject(
      HiveSubject(id: 's1', title: 'Subject A', tagIds: ['t1']),
    );
    // 'Web' 태그를 사용하는 과목
    fakeHiveManager.addFakeSubject(
      HiveSubject(id: 's2', title: 'Subject B', tagIds: ['t2']),
    );
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
    // (리팩토링 가정) TagsEditScreen에 FakeHiveManager 주입
    await tester.pumpWidget(
      createTestableWidget(TagsEditScreen(hiveManager: fakeHiveManager)),
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

      // AppBar 제목
      expect(find.text('태그 수정'), findsOneWidget);

      // _loadData -> _assignColors 호출 확인 (봄 테마 색상)
      final aiTagPill = findTagPillByName(tester, 'AI');
      expect(aiTagPill.tag.color, getTagColorTheme('봄').colors[0]);

      // 테마 선택기 ('봄' 선택됨)
      final springChips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => (chip.label as Text).data == '봄');
      expect(springChips.first.selected, isTrue);
      expect(find.text('비비드'), findsOneWidget);

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
      fakeHiveManager.reset();

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

      // [Given] '봄' 테마가 적용된 'AI'와 'Web' 태그
      final springTheme = getTagColorTheme('봄');
      final aiTagPill = findTagPillByName(tester, 'AI');
      final webTagPill = findTagPillByName(tester, 'Web');
      expect(aiTagPill.tag.color, springTheme.colors[0]);
      expect(webTagPill.tag.color, springTheme.colors[1]);

      final vividChips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => (chip.label as Text).data == '비비드');
      expect(vividChips.first.selected, isFalse);

      // [When] '비비드' 테마 탭
      await tester.tap(find.text('비비드'));
      await tester.pumpAndSettle();

      // [Then] '비비드'가 선택되고 Hive가 호출됨
      final vividChipsAfter = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => (chip.label as Text).data == '비비드');
      expect(vividChipsAfter.first.selected, isTrue);
      expect(fakeHiveManager.updatedTagColorTheme, '비비드');

      // [Then] 모든 태그의 색상이 '비비드' 테마 색상으로 변경됨
      // _applyThemeToAllTags()는 모든 태그를 재할당하므로 모두 검증
      final vividTheme = getTagColorTheme('비비드');
      final updatedAiTagPill = findTagPillByName(tester, 'AI');
      final updatedWebTagPill = findTagPillByName(tester, 'Web');
      expect(updatedAiTagPill.tag.color, vividTheme.colors[0]);
      expect(updatedWebTagPill.tag.color, vividTheme.colors[1]);
      expect(updatedAiTagPill.tag.color, isNot(springTheme.colors[0]));
      expect(updatedWebTagPill.tag.color, isNot(springTheme.colors[1]));
    });

    testWidgets('Theme change reassigns colors to all tags correctly', (
      WidgetTester tester,
    ) async {
      // [Given] 5개 태그가 있는 상태
      fakeHiveManager.reset();
      final springTheme = getTagColorTheme('봄');
      for (int i = 0; i < 5; i++) {
        fakeHiveManager.addFakeTag(
          HiveTag(
            id: 't${i + 1}',
            name: 'Tag $i',
            color: springTheme.colors[i],
          ),
        );
      }
      await pumpScreen(tester);

      // [Then] 모든 태그가 '봄' 테마 색상을 가짐
      for (int i = 0; i < 5; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        expect(tagPill.tag.color, springTheme.colors[i]);
      }

      // [When] '바다' 테마로 변경
      await tester.tap(find.text('바다'));
      await tester.pumpAndSettle();

      // [Then] 모든 태그가 '바다' 테마 색상으로 변경됨
      final neonTheme = getTagColorTheme('바다');
      for (int i = 0; i < 5; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        expect(tagPill.tag.color, neonTheme.colors[i]);
        expect(tagPill.tag.color, isNot(springTheme.colors[i]));
      }
    });

    testWidgets('All 15 tag positions get correct colors from theme', (
      WidgetTester tester,
    ) async {
      // [Given] 15개 태그 생성 (최대 개수)
      fakeHiveManager.reset();
      final springTheme = getTagColorTheme('봄');
      for (int i = 0; i < 15; i++) {
        final colorIndex = i % springTheme.colors.length;
        fakeHiveManager.addFakeTag(
          HiveTag(
            id: 't${i + 1}',
            name: 'Tag $i',
            color: springTheme.colors[colorIndex],
          ),
        );
      }
      await pumpScreen(tester);

      // [Then] 15개 태그 모두 정확한 위치의 색상을 가짐
      for (int i = 0; i < 15; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        final colorIndex = i % springTheme.colors.length;
        expect(
          tagPill.tag.color,
          springTheme.colors[colorIndex],
          reason: 'Tag $i should have color at index $i from 봄 theme',
        );
      }

      // [When] '비비드' 테마로 변경
      await tester.tap(find.text('비비드'));
      await tester.pumpAndSettle();

      // [Then] 15개 태그 모두 '비비드' 테마의 정확한 위치 색상으로 변경됨
      final vividTheme = getTagColorTheme('비비드');
      for (int i = 0; i < 15; i++) {
        final tagPill = findTagPillByName(tester, 'Tag $i');
        final colorIndex = i % vividTheme.colors.length;
        final oldColorIndex = i % springTheme.colors.length;
        expect(
          tagPill.tag.color,
          vividTheme.colors[colorIndex],
          reason: 'Tag $i should have color at index $i from 비비드 theme',
        );
        expect(
          tagPill.tag.color,
          isNot(springTheme.colors[oldColorIndex]),
          reason: 'Tag $i color should change from 봄 to 비비드',
        );
      }
    });

    testWidgets('All 5 themes apply colors correctly to 15 tags', (
      WidgetTester tester,
    ) async {
      // [Given] 15개 태그 생성
      fakeHiveManager.reset();
      // FakeHiveManager의 현재 설정된 테마를 가져와서 초기 색상 설정
      final initialTheme = getTagColorTheme(
        fakeHiveManager.settings.tagColorTheme,
      );
      for (int i = 0; i < 15; i++) {
        final colorIndex = i % initialTheme.colors.length;
        fakeHiveManager.addFakeTag(
          HiveTag(
            id: 't${i + 1}',
            name: 'Tag $i',
            color: initialTheme.colors[colorIndex],
          ),
        );
      }
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

      // [When] 이름 변경 후 '적용'
      await tester.enterText(find.byType(TextField), 'AI-Renamed');
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      // [Then] 태그 칩의 이름이 변경됨
      expect(find.text('AI'), findsNothing);
      expect(find.text('AI-Renamed'), findsOneWidget);
    });

    testWidgets('Apply with empty name shows snackbar', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), '   '); // 공백
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('태그 이름을 입력해주세요.'), findsOneWidget);
    });

    testWidgets('Apply with duplicate name shows snackbar', (tester) async {
      await pumpScreen(tester); // 'AI'가 선택됨
      await tester.enterText(find.byType(TextField), 'Web'); // 'Web' (중복)
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('이미 사용 중인 이름입니다. 다른 이름을 입력해주세요.'), findsOneWidget);
    });

    testWidgets('Cancel button reverts text field', (tester) async {
      await pumpScreen(tester); // 'AI'가 선택됨
      await tester.enterText(find.byType(TextField), 'Temporary Change');
      await tester.pump();

      expect(find.text('Temporary Change'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // 폼의 텍스트가 원래 'AI'로 복원됨
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'AI',
      );
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
      // 기존 태그가 2개(index 0, 1)이므로 새 태그는 index 2의 색상을 받음
      final springTheme = getTagColorTheme('봄');
      expect(newTagPill.tag.color, springTheme.colors[2]);

      // [Then] 폼이 초기화됨 (코드 로직: _nameC.clear())
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('Add tag generates non-duplicate name', (tester) async {
      // [Given] '새 태그'가 이미 존재함
      fakeHiveManager.reset();
      final springTheme = getTagColorTheme('봄');
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't1', name: 'AI', color: springTheme.colors[0]),
      );
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't2', name: 'Web', color: springTheme.colors[1]),
      );
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't3', name: '새 태그', color: springTheme.colors[2]),
      );
      await pumpScreen(tester);

      // [When] '+' 버튼 탭
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then] '새 태그 (1)'이 생성됨 - '#새 태그 (1)' 형식으로 표시됨
      expect(find.text('#새 태그 (1)'), findsOneWidget);

      // [Then] 새 태그의 색상이 현재 테마('봄')의 네 번째 색상이어야 함
      final newTagPill = findTagPillByName(tester, '새 태그 (1)');
      expect(newTagPill.tag.color, springTheme.colors[3]);
    });

    testWidgets('Add tag respects 15 tag limit', (tester) async {
      // [Given] 15개 태그 추가
      fakeHiveManager.reset();
      final springTheme = getTagColorTheme('봄');
      for (int i = 0; i < 15; i++) {
        // 색상 순환 로직 적용: i % theme.colors.length
        final colorIndex = i % springTheme.colors.length;
        fakeHiveManager.addFakeTag(
          HiveTag(
            id: 't${i + 1}',
            name: 'Tag $i',
            color: springTheme.colors[colorIndex],
          ),
        );
      }
      await pumpScreen(tester);
      expect(find.byType(SelectableTagPill), findsNWidgets(15));

      // [When] '+' 버튼 탭
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
      // [Given] 15개 태그 추가 후 하나 삭제하여 14개 상태
      fakeHiveManager.reset();
      final springTheme = getTagColorTheme('봄');
      for (int i = 0; i < 14; i++) {
        final colorIndex = i % springTheme.colors.length;
        fakeHiveManager.addFakeTag(
          HiveTag(
            id: 't${i + 1}',
            name: 'Tag $i',
            color: springTheme.colors[colorIndex],
          ),
        );
      }
      await pumpScreen(tester);

      // [When] '+' 버튼 탭 (15번째 태그 추가)
      await tester.tap(find.widgetWithText(ActionChip, '+'));
      await tester.pumpAndSettle();

      // [Then] 15번째 태그의 색상이 첫 번째 색상과 동일 (14 % 15 = 14)
      // 봄 테마는 10개 색상. 14번째 태그는 index 14 % 10 = 4의 색상을 가짐
      final newTagPill = findTagPillByName(tester, '새 태그');
      expect(newTagPill.tag.color, springTheme.colors[4]);

      // [When] 이름 변경 후 한 번 더 추가 시도 (16번째 태그 - 순환 테스트)
      await tester.enterText(find.byType(TextField), 'Tag 14');
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      // 15개 제한이므로 더 이상 추가 불가 (이 테스트는 순환 로직 검증)
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
      // [Given] 5개 태그 생성 (중간 태그 삭제 시 색상 재할당 테스트)
      fakeHiveManager.reset();
      final springTheme = getTagColorTheme('봄');
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't0', name: 'Tag0', color: springTheme.colors[0]),
      );
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't1', name: 'Tag1', color: springTheme.colors[1]),
      );
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't2', name: 'Tag2', color: springTheme.colors[2]),
      );
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't3', name: 'Tag3', color: springTheme.colors[3]),
      );
      fakeHiveManager.addFakeTag(
        HiveTag(id: 't4', name: 'Tag4', color: springTheme.colors[4]),
      );
      // Tag0과 Tag1은 과목에서 사용 중 (삭제 시 경고 표시됨)
      fakeHiveManager.addFakeSubject(
        HiveSubject(id: 's1', title: 'Subject A', tagIds: ['t0']),
      );
      fakeHiveManager.addFakeSubject(
        HiveSubject(id: 's2', title: 'Subject B', tagIds: ['t1']),
      );
      await pumpScreen(tester);

      // [Given] 초기 상태: 5개 태그 모두 정확한 색상을 가짐
      expect(find.byType(SelectableTagPill), findsNWidgets(5));
      for (int i = 0; i < 5; i++) {
        expect(
          findTagPillByName(tester, 'Tag$i').tag.color,
          springTheme.colors[i],
        );
      }

      // [When] 중간 태그(Tag2) 삭제
      await tester.tap(find.text('#Tag2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then] 경고 없이 즉시 삭제됨 (Tag2는 사용되지 않음)
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('#Tag2'), findsNothing);
      expect(find.byType(SelectableTagPill), findsNWidgets(4));

      // [Then] 삭제 후 색상이 재할당됨
      // 남은 태그: Tag0, Tag1, Tag3, Tag4
      // 위치 재할당: Tag0(색0), Tag1(색1), Tag3(색2로 변경됨), Tag4(색3으로 변경됨)
      expect(
        findTagPillByName(tester, 'Tag0').tag.color,
        springTheme.colors[0],
      );
      expect(
        findTagPillByName(tester, 'Tag1').tag.color,
        springTheme.colors[1],
      );
      expect(
        findTagPillByName(tester, 'Tag3').tag.color,
        springTheme.colors[2],
        reason: 'Tag3 should be reassigned to color[2] after Tag2 deletion',
      );
      expect(
        findTagPillByName(tester, 'Tag4').tag.color,
        springTheme.colors[3],
        reason: 'Tag4 should be reassigned to color[3] after Tag2 deletion',
      );

      // [When] 마지막 태그(Tag4) 삭제
      await tester.tap(find.text('#Tag4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();

      // [Then] 남은 태그들의 색상이 여전히 정확함
      expect(find.byType(SelectableTagPill), findsNWidgets(3));
      expect(
        findTagPillByName(tester, 'Tag0').tag.color,
        springTheme.colors[0],
      );
      expect(
        findTagPillByName(tester, 'Tag1').tag.color,
        springTheme.colors[1],
      );
      expect(
        findTagPillByName(tester, 'Tag3').tag.color,
        springTheme.colors[2],
      );

      // [Then] 선택이 이전 인덱스로 이동함
      expect(findTagPillByName(tester, 'Tag3').selected, isTrue);
    });

    testWidgets('Delete tag (with warning) shows dialog and handles No/Yes', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // [Given] 'AI' 태그(s1에서 사용 중)가 선택됨
      expect(findTagPillByName(tester, 'AI').selected, isTrue);

      // [When] '태그 삭제' 탭
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
                          TagsEditScreen(hiveManager: fakeHiveManager),
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

      // [When] 1. '비비드' 테마로 변경
      await tester.tap(find.text('비비드'));
      await tester.pumpAndSettle();

      // [When] 2. 'AI' 태그 이름 변경
      await tester.enterText(find.byType(TextField), 'AI-Renamed');
      await tester.tap(find.text('적용'));
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
      expect(fakeHiveManager.savedTags, isNotNull);
      // 'Web' 태그가 삭제되었으므로 1개만 저장되어야 함
      expect(fakeHiveManager.savedTags!.length, 1);
      // 'AI' 태그의 이름이 변경되어 저장되어야 함
      expect(fakeHiveManager.savedTags!.first.name, 'AI-Renamed');

      // Hive.updateTagColorTheme이 호출되었는지 확인
      expect(fakeHiveManager.updatedTagColorTheme, '비비드');
    });
  });
}
