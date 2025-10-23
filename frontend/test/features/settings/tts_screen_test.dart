// test/features/settings/tts_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// TODO: 실제 앱 경로로 수정해주세요
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/settings/tts_screen.dart'; // 수정된 TtsScreen 임포트

// --- Fakes ---

// (FakeAppSettings는 이전과 동일)
class FakeAppSettings implements AppSettings {
  FakeAppSettings({
    this.ttsGender = '남성',
    this.ttsSpeed = '보통',
    this.theme = 'system',
    this.language = 'ko',
    this.accessibilityHighContrast = false,
    this.accessibilityReduceMotion = false,
    this.accessibilityEmphasizeCaptions = true,
    this.tagColorTheme = '파스텔',
  });

  @override
  String ttsGender;
  @override
  String ttsSpeed;

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
  String tagColorTheme;
}

// (FakeHiveManager는 이전과 동일)
class FakeHiveManager with ChangeNotifier implements HiveManager {
  FakeHiveManager({String initialGender = '남성', String initialSpeed = '보통'}) {
    _fakeSettings = FakeAppSettings(
      ttsGender: initialGender,
      ttsSpeed: initialSpeed,
    );
  }

  late FakeAppSettings _fakeSettings;

  bool updateTtsCalled = false;
  String? lastGender;
  String? lastSpeed;

  @override
  AppSettings get settings => _fakeSettings;

  @override
  Future<void> updateTts({String? gender, String? speed}) async {
    updateTtsCalled = true;
    if (gender != null) {
      _fakeSettings.ttsGender = gender;
      lastGender = gender;
    }
    if (speed != null) {
      _fakeSettings.ttsSpeed = speed;
      lastSpeed = speed;
    }
  }

  void resetCallHistory() {
    updateTtsCalled = false;
    lastGender = null;
    lastSpeed = null;
  }

  // (HiveManager의 나머지 모든 멤버 (빈 구현) - 이전과 동일)
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
  Future<void> updateTheme(String theme) async {}
  @override
  Future<void> updateLanguage(String language) async {}
  @override
  Future<void> updateAccessibility({
    bool? highContrast,
    bool? reduceMotion,
    bool? emphasizeCaptions,
  }) async {}
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

/// ⬇️ **수정**: 'didPop' 충돌 해결
class FakeNavigatorObserver extends NavigatorObserver {
  // 'didPop' 필드 대신 'popCalled' 필드 사용
  bool popCalled = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 'didPop' *메서드*가 호출되면, 'popCalled' *변수*를 true로 설정
    popCalled = true;
  }
}
// --- End of Fakes ---

void main() {
  late FakeHiveManager fakeHiveManager;
  late FakeNavigatorObserver fakeNavigatorObserver;

  setUp(() {
    fakeHiveManager = FakeHiveManager();
    fakeNavigatorObserver = FakeNavigatorObserver();
  });

  Future<void> pumpTtsScreen(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // l10n 설정 (isKorean을 위해 필수)
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,

        navigatorObservers: [fakeNavigatorObserver],
        home: TtsScreen(hiveManager: fakeHiveManager),
      ),
    );

    await tester.pump(); // 로딩 시작
    await tester.pumpAndSettle(); // 로딩 완료
  }

  // (선택 상태 검증 헬퍼는 이전과 동일)
  bool isGenderSelected(WidgetTester tester, String label) {
    final text = tester.widget<Text>(find.text(label));
    return text.style?.fontWeight == FontWeight.w600;
  }

  bool isSpeedSelected(WidgetTester tester, String label) {
    final text = tester.widget<Text>(find.text(label));
    return text.style?.fontWeight == FontWeight.w600;
  }

  group('tts_screen.dart: Widget Test', () {
    group('1. UI Initial State Verification (Mock Data -> UI)', () {
      // (로딩 테스트는 동일)
      testWidgets('로딩 중에는 CircularProgressIndicator가 표시되어야 함', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: TtsScreen(hiveManager: fakeHiveManager)),
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle();
      });

      // (로딩 완료 테스트는 동일)
      testWidgets('로딩 완료 후 메인 Scaffold가 렌더링되어야 함', (tester) async {
        await pumpTtsScreen(tester);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      // [ ] ⬇️ **수정**: l10n.male 대신 하드코딩된 '남성'/'보통' 사용
      testWidgets('설정이 "남성", "보통"일 때 UI에 반영되어야 함', (tester) async {
        await pumpTtsScreen(tester, locale: const Locale('ko'));

        expect(isGenderSelected(tester, '남성'), isTrue);
        expect(isGenderSelected(tester, '여성'), isFalse);
        expect(isSpeedSelected(tester, '보통'), isTrue);
        expect(isSpeedSelected(tester, '빠르게'), isFalse);
        expect(isSpeedSelected(tester, '느리게'), isFalse);
      });

      // [ ] ⬇️ **수정**: l10n.female 대신 하드코딩된 '여성'/'빠르게' 사용
      testWidgets('설정이 "여성", "빠르게"일 때 UI에 반영되어야 함', (tester) async {
        fakeHiveManager = FakeHiveManager(
          initialGender: '여성',
          initialSpeed: '빠르게',
        );
        await pumpTtsScreen(tester, locale: const Locale('ko'));

        expect(isGenderSelected(tester, '여성'), isTrue);
        expect(isGenderSelected(tester, '남성'), isFalse);
        expect(isSpeedSelected(tester, '빠르게'), isTrue);
        expect(isSpeedSelected(tester, '보통'), isFalse);
      });

      // [ ] (한국어 로컬라이제이션 테스트는 이미 하드코딩되어 있으므로 통과)
      testWidgets('한국어(ko) 로케일일 때 한국어 라벨이 표시되어야 함', (tester) async {
        await pumpTtsScreen(tester, locale: const Locale('ko'));
        expect(find.text('TTS 음성 성별'), findsOneWidget);
        expect(find.text('남성'), findsOneWidget);
        expect(find.text('여성'), findsOneWidget);
      });

      // [ ] (영어 로컬라이제이션 테스트는 이미 하드코딩되어 있으므로 통과)
      testWidgets('영어(en) 로케일일 때 영어 라벨이 표시되어야 함', (tester) async {
        await pumpTtsScreen(tester, locale: const Locale('en'));
        expect(find.text('TTS Voice Gender'), findsOneWidget);
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
      });

      // (AppBar 테스트는 동일)
      testWidgets('AppBar 타이틀이 "TTS"이고 닫기 버튼이 있어야 함', (tester) async {
        await pumpTtsScreen(tester);
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text('TTS')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.close),
          ),
          findsOneWidget,
        );
      });
    });

    group('2. User Interaction Verification (UI -> Logic & State)', () {
      // [ ] ⬇️ **수정**: l10n.female 대신 '여성' 사용
      testWidgets('"여성" 버튼 탭 시 updateTts(gender: "여성") 호출 및 UI 변경', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('ko')); // '남성'으로 시작
        expect(isGenderSelected(tester, '남성'), isTrue);

        await tester.tap(find.text('여성'));
        await tester.pumpAndSettle();

        expect(fakeHiveManager.updateTtsCalled, isTrue);
        expect(fakeHiveManager.lastGender, '여성');
        expect(isGenderSelected(tester, '여성'), isTrue);
      });

      // [ ] (영어 "Male" 버튼 테스트는 하드코딩되어 있으므로 통과)
      testWidgets('영어 "Male" 버튼 탭 시 updateTts(gender: "남성") 호출', (
        tester,
      ) async {
        fakeHiveManager = FakeHiveManager(initialGender: '여성');
        await pumpTtsScreen(tester, locale: const Locale('en'));

        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();

        expect(fakeHiveManager.updateTtsCalled, isTrue);
        expect(fakeHiveManager.lastGender, '남성');
      });

      // [ ] (영어 "Female" 버튼 테스트는 하드코딩되어 있으므로 통과)
      testWidgets('영어 "Female" 버튼 탭 시 updateTts(gender: "여성") 호출', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('en'));

        await tester.tap(find.text('Female'));
        await tester.pumpAndSettle();

        expect(fakeHiveManager.updateTtsCalled, isTrue);
        expect(fakeHiveManager.lastGender, '여성');
      });

      // [ ] ⬇️ **수정**: l10n.fast 대신 '빠르게' 사용
      testWidgets('"빠르게" 버튼 탭 시 updateTts(speed: "빠르게") 호출 및 UI 변경', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('ko')); // '보통'으로 시작

        await tester.tap(find.text('빠르게'));
        await tester.pumpAndSettle();

        expect(fakeHiveManager.updateTtsCalled, isTrue);
        expect(fakeHiveManager.lastSpeed, '빠르게');
        expect(isSpeedSelected(tester, '빠르게'), isTrue);
      });

      // [ ] ⬇️ **수정**: l10n.slow 대신 '느리게' 사용
      testWidgets('"느리게" 버튼 탭 시 updateTts(speed: "느리게") 호출 및 UI 변경', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('ko'));

        await tester.tap(find.text('느리게'));
        await tester.pumpAndSettle();

        expect(fakeHiveManager.updateTtsCalled, isTrue);
        expect(fakeHiveManager.lastSpeed, '느리게');
        expect(isSpeedSelected(tester, '느리게'), isTrue);
      });

      // [ ] ⬇️ **수정**: didPop 대신 popCalled 확인
      testWidgets('AppBar 닫기 버튼 탭 시 Navigator.pop 호출', (tester) async {
        await pumpTtsScreen(tester);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // 'didPop'이 아닌 'popCalled' 변수를 확인
        expect(fakeNavigatorObserver.popCalled, isTrue);
      });
    });

    // ⬇️ **수정**: TtsScreen.speedToRate 호출 (사용자가 1번 항목에서 수정한 것을 전제)
    group('3. Static Method Unit Tests (speedToRate)', () {
      test('TtsScreen.speedToRate("빠르게")는 1.5를 반환해야 함', () {
        expect(TtsScreen.speedToRate('빠르게'), 1.5);
      });

      test('TtsScreen.speedToRate("보통")는 1.0을 반환해야 함', () {
        expect(TtsScreen.speedToRate('보통'), 1.0);
      });

      test('TtsScreen.speedToRate("느리게")는 0.7을 반환해야 함', () {
        expect(TtsScreen.speedToRate('느리게'), 0.7);
      });

      test('TtsScreen.speedToRate("other")는 1.0 (기본값)을 반환해야 함', () {
        expect(TtsScreen.speedToRate('some_other_value'), 1.0);
        expect(TtsScreen.speedToRate(''), 1.0);
      });
    });
  });
}
