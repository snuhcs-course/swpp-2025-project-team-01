import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/settings/language_screen.dart';

// --- Fakes ---

/// AppSettings 인터페이스를 구현하는 Fake 클래스
class FakeAppSettings implements AppSettings {
  FakeAppSettings({
    this.language = 'ko',
    this.theme = 'system',
    this.accessibilityHighContrast = false,
    this.accessibilityReduceMotion = false,
    this.accessibilityEmphasizeCaptions = true,
    this.ttsGender = '남성',
    this.ttsSpeed = '보통',
    this.tagColorTheme = '파스텔',
  });

  @override
  String theme;

  @override
  String language;

  @override
  bool accessibilityHighContrast;

  @override
  bool accessibilityReduceMotion;

  @override
  bool accessibilityEmphasizeCaptions;

  @override
  String ttsGender;

  @override
  String ttsSpeed;

  @override
  String tagColorTheme;
}

/// HiveManager 인터페이스를 구현하는 Fake 클래스
class FakeHiveManager with ChangeNotifier implements HiveManager {
  FakeHiveManager({String initialLanguage = 'ko'}) {
    _fakeSettings = FakeAppSettings(language: initialLanguage);
  }

  late FakeAppSettings _fakeSettings;

  bool get hasActiveListeners => hasListeners;

  // --- 1. 이 테스트에서 "실제로" 동작해야 하는 멤버 ---

  @override
  AppSettings get settings => _fakeSettings;

  @override
  Future<void> updateLanguage(String language) async {
    _fakeSettings.language = language;
    notifyListeners();
  }

  // --- 2. HiveManager의 나머지 모든 멤버 (빈 구현) ---

  @override
  bool get isInitialized => true;

  @override
  Map<String, HiveSubject> get subjects => {};

  @override
  Map<String, HiveTag> get tags => {};

  @override
  UiState get uiState => UiState();

  @override
  Map<String, HiveLecture> get lectures => {};

  @override
  Future<void> init() async {}

  @override
  Future<void> initForTesting(Box<AppData> box) async {}

  @override
  Future<void> updateTheme(String theme) async {}

  @override
  Future<void> updateAccessibility({
    bool? highContrast,
    bool? reduceMotion,
    bool? emphasizeCaptions,
  }) async {}

  @override
  Future<void> updateTts({String? gender, String? speed}) async {}

  @override
  Future<void> updateTagColorTheme(String theme) async {}

  @override
  List<HiveSubject> getSubjects({
    bool favoritesOnly = false,
    List<String> filterTagIds = const [],
  }) => [];

  @override
  HiveSubject? getSubject(String id) => null;

  @override
  Future<void> toggleSubjectFavorite(String id) async {}

  @override
  Future<void> updateSubject(
    String id, {
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
  }) async {}

  @override
  Future<void> createSubject(String title, List<String> tagIds) async {}

  @override
  Future<void> deleteSubject(String id) async {}

  @override
  Future<void> updateSubjectTitle(String id, String title) async {}

  @override
  Future<void> updateSubjectLectures(
    String id,
    List<String> lectureIds,
  ) async {}

  @override
  Future<void> updateSubjectTags(String id, List<String> tagIds) async {}

  @override
  List<HiveTag> getTags() => [];

  @override
  Future<void> saveTags(List<HiveTag> newTags) async {}

  @override
  bool getSubjectExpandedState(String subjectId) => true;

  @override
  Future<void> setSubjectExpandedState(String subjectId, bool expanded) async {}

  @override
  List<String> getRecentSearches() => [];

  @override
  Future<void> addRecentSearch(String query) async {}

  @override
  Future<void> removeRecentSearch(String query) async {}

  @override
  Future<void> addLecture(HiveLecture lecture) async {}

  @override
  HiveLecture? getLecture(String id) => null;

  @override
  List<HiveLecture> getLecturesBySubject(String subjectId) => [];

  @override
  List<HiveLecture> getLecturesByIds(List<String> lectureIds) => [];

  @override
  Future<void> updateLecture(HiveLecture lecture) async {}

  @override
  Future<void> updateLectureMetadata(
    String id, {
    String? weekLabel,
    String? title,
  }) async {}

  @override
  Future<void> deleteLecture(String lectureId) async {}

  @override
  List<HiveLecture> searchLectures(String query) => [];

  @override
  List<HiveLecture> getAllLectures({bool newestFirst = true}) => [];

  @override
  Future<void> close() async {}
}
// --- End of Fakes ---

void main() {
  late FakeHiveManager fakeHiveManager;

  // 테스트 위젯을 펌핑하는 헬퍼 함수 (Fake 주입)
  Future<void> pumpLanguageScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LanguageScreen(hiveManager: fakeHiveManager)),
    );
  }

  // 테스트 전에 Fake 객체를 새로 생성
  setUp(() {
    fakeHiveManager = FakeHiveManager(initialLanguage: 'ko');
  });

  group('language_screen.dart: Widget Test', () {
    group('1. UI Initial State Verification (Fake Data -> UI)', () {
      testWidgets('언어가 "ko"일 때 "한국어"가 선택되어 있어야 함', (tester) async {
        await pumpLanguageScreen(tester);
        await tester.pump();

        // RadioGroup이 사용되므로 RadioGroup의 groupValue를 검사
        final koRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('한국어 / Korean'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        final enRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('English'),
            matching: find.byType(RadioGroup<String>),
          ),
        );

        // 'ko'가 선택된 상태 = RadioGroup의 groupValue가 'ko'여야 함
        expect(koRadioGroup.groupValue, 'ko');
        expect(enRadioGroup.groupValue, 'ko');
      });

      testWidgets('언어가 "en"일 때 "English"가 선택되어 있어야 함', (tester) async {
        fakeHiveManager = FakeHiveManager(initialLanguage: 'en');

        await pumpLanguageScreen(tester);
        await tester.pump();

        // RadioGroup이 사용되므로 RadioGroup의 groupValue를 검사
        final koRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('한국어 / Korean'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        final enRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('English'),
            matching: find.byType(RadioGroup<String>),
          ),
        );

        expect(koRadioGroup.groupValue, 'en');
        expect(enRadioGroup.groupValue, 'en');
      });

      testWidgets("AppBar 타이틀이 '언어 / Language'로 표시되어야 함", (tester) async {
        await pumpLanguageScreen(tester);

        expect(find.byType(AppBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('언어 / Language'),
          ),
          findsOneWidget,
        );
      });
    });

    group('2. User Interaction Verification (UI -> Fake Logic)', () {
      testWidgets("'한국어 / Korean' 탭 시 FakeManager 상태가 'ko'로 변경되어야 함", (
        tester,
      ) async {
        fakeHiveManager = FakeHiveManager(initialLanguage: 'en');
        await pumpLanguageScreen(tester);
        expect(fakeHiveManager.settings.language, 'en');

        await tester.tap(find.text('한국어 / Korean'));
        await tester.pumpAndSettle();

        // Fake 객체의 상태가 변경되었는지 확인
        expect(fakeHiveManager.settings.language, 'ko');
      });

      testWidgets("'English' 탭 시 FakeManager 상태가 'en'로 변경되어야 함", (
        tester,
      ) async {
        await pumpLanguageScreen(tester);
        expect(fakeHiveManager.settings.language, 'ko');

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        // Fake 객체의 상태가 변경되었는지 확인
        expect(fakeHiveManager.settings.language, 'en');
      });
    });

    group('3. State Change Listener Verification (Fake Logic -> UI)', () {
      testWidgets('외부 변경("en") 시 UI가 "English"로 업데이트되어야 함', (tester) async {
        await pumpLanguageScreen(tester);
        final initialRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('English'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        expect(initialRadioGroup.groupValue, 'ko');

        await fakeHiveManager.updateLanguage('en');
        await tester.pump();

        final updatedRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('English'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        expect(updatedRadioGroup.groupValue, 'en');
      });

      testWidgets('외부 변경("ko") 시 UI가 "한국어"로 업데이트되어야 함', (tester) async {
        fakeHiveManager = FakeHiveManager(initialLanguage: 'en');
        await pumpLanguageScreen(tester);
        final initialRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('한국어 / Korean'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        expect(initialRadioGroup.groupValue, 'en');

        await fakeHiveManager.updateLanguage('ko');
        await tester.pump(); // 리빌드

        final updatedRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('한국어 / Korean'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        expect(updatedRadioGroup.groupValue, 'ko');
      });

      testWidgets('화면 이탈(dispose) 시 리스너가 제거되어야 함', (tester) async {
        await pumpLanguageScreen(tester);

        expect(
          fakeHiveManager.hasActiveListeners,
          isTrue,
          reason: '초기 리스너가 등록되어야 함',
        );

        await tester.pumpWidget(Container());

        expect(
          fakeHiveManager.hasActiveListeners,
          isFalse,
          reason: 'Dispose 후 리스너가 제거되어야 함',
        );
      });
    });
  });
}
