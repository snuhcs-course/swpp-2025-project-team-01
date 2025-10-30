// test/features/settings/accessibility_mode_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/settings/accessibility_mode.dart';
import 'package:re_view/data/hive_models.dart';

// ------------------------------------------------------------------
// 1. Mockito 대신 사용할 "가짜" (Fake/Stub) 클래스 정의
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
    this.ttsSpeed = '보통',
    this.tagColorTheme = '파스텔',
    this.hasCompletedTutorial = true,
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

  @override
  bool hasCompletedTutorial;
}

/// HiveManager를 흉내내는 가짜 클래스
/// ChangeNotifier의 핵심 기능(listener)을 간단히 구현
class FakeHiveManager extends Fake implements HiveManager {
  final FakeAppSettings _fakeSettings = FakeAppSettings();
  VoidCallback? _listener; // 리스너를 저장할 변수 (단일 리스너만 가정)

  // 테스트 검증용 변수
  bool updateAccessibilityCalled = false;
  Map<String, bool> lastAccessibilityValues = {};
  bool removeListenerCalled = false;

  @override
  AppSettings get settings => _fakeSettings;

  @override
  Future<void> updateAccessibility({
    bool? highContrast,
    bool? reduceMotion,
    bool? emphasizeCaptions,
  }) async {
    updateAccessibilityCalled = true;
    if (highContrast != null) {
      _fakeSettings.accessibilityHighContrast = highContrast;
      lastAccessibilityValues['highContrast'] = highContrast;
    }
    if (reduceMotion != null) {
      _fakeSettings.accessibilityReduceMotion = reduceMotion;
      lastAccessibilityValues['reduceMotion'] = reduceMotion;
    }
    if (emphasizeCaptions != null) {
      _fakeSettings.accessibilityEmphasizeCaptions = emphasizeCaptions;
      lastAccessibilityValues['emphasizeCaptions'] = emphasizeCaptions;
    }
  }

  // --- ChangeNotifier 흉내내기 ---
  @override
  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_listener == listener) {
      _listener = null;
      removeListenerCalled = true; // dispose() 테스트용
    }
  }

  // Tutorial methods (not used in this test)
  @override
  bool get hasTutorialCompleted => _fakeSettings.hasCompletedTutorial;

  @override
  Future<void> completeTutorial() async {}

  @override
  Future<void> resetTutorial() async {}

  /// 테스트를 위해 'setState'를 수동으로 트리거하는 함수
  void triggerNotifyListeners() {
    _listener?.call();
  }

  // 테스트 리셋을 위한 헬퍼
  void resetCallHistory() {
    updateAccessibilityCalled = false;
    lastAccessibilityValues.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // ------------------------------------------------------------------
  // 테스트 설정 (Setup)
  // ------------------------------------------------------------------

  late FakeHiveManager fakeHiveManager;

  setUp(() {
    fakeHiveManager = FakeHiveManager();
  });

  // 테스트용 헬퍼 함수: 위젯 빌드
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: child,
    );
  }

  // 테스트용 헬퍼 함수: 스위치 상태 찾기
  // l10n에서 텍스트를 가져와 SwitchListTile을 찾고, 그 value를 반환
  bool getSwitchValue(WidgetTester tester, String titleText) {
    final switchTile = find.ancestor(
      of: find.text(titleText),
      matching: find.byType(SwitchListTile),
    );
    return tester.widget<SwitchListTile>(switchTile).value;
  }

  // l10n 인스턴스를 가져오는 헬퍼. (l10n 테스트용)
  AppLocalizations getL10n(WidgetTester tester) {
    return AppLocalizations.of(
      tester.element(find.byType(AccessibilityScreen)),
    );
  }

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 1: UI 초기 상태 검증
  // ------------------------------------------------------------------
  group('1. UI Initial State Verification (Mock Data -> UI)', () {
    testWidgets('Verify all switches are off when settings are false', (
      WidgetTester tester,
    ) async {
      // [Given] (기본값이 모두 false)

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);

      // [Then]
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);
      expect(getSwitchValue(tester, l10n.reduceMotion), isFalse);
      expect(getSwitchValue(tester, l10n.emphasizeCaptions), isFalse);
    });

    testWidgets('Verify only High Contrast switch is on', (
      WidgetTester tester,
    ) async {
      // [Given]
      fakeHiveManager.settings.accessibilityHighContrast = true;

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);

      // [Then]
      expect(getSwitchValue(tester, l10n.highContrast), isTrue);
      expect(getSwitchValue(tester, l10n.reduceMotion), isFalse);
      expect(getSwitchValue(tester, l10n.emphasizeCaptions), isFalse);
    });

    testWidgets('Verify only Reduce Motion switch is on', (
      WidgetTester tester,
    ) async {
      // [Given]
      fakeHiveManager.settings.accessibilityReduceMotion = true;
      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);
      // [Then]
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);
      expect(getSwitchValue(tester, l10n.reduceMotion), isTrue);
      expect(getSwitchValue(tester, l10n.emphasizeCaptions), isFalse);
    });

    testWidgets('Verify only Emphasize Captions switch is on', (
      WidgetTester tester,
    ) async {
      // [Given]
      fakeHiveManager.settings.accessibilityEmphasizeCaptions = true;
      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);
      // [Then]
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);
      expect(getSwitchValue(tester, l10n.reduceMotion), isFalse);
      expect(getSwitchValue(tester, l10n.emphasizeCaptions), isTrue);
    });

    testWidgets('Verify all switches are on when settings are true', (
      WidgetTester tester,
    ) async {
      // [Given]
      fakeHiveManager.settings.accessibilityHighContrast = true;
      fakeHiveManager.settings.accessibilityReduceMotion = true;
      fakeHiveManager.settings.accessibilityEmphasizeCaptions = true;

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);

      // [Then]
      expect(getSwitchValue(tester, l10n.highContrast), isTrue);
      expect(getSwitchValue(tester, l10n.reduceMotion), isTrue);
      expect(getSwitchValue(tester, l10n.emphasizeCaptions), isTrue);
    });

    testWidgets('Verify all localized texts are displayed', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);

      // [Then]
      expect(find.text(l10n.accessibility), findsOneWidget); // AppBar
      expect(find.text(l10n.highContrast), findsOneWidget);
      expect(find.text(l10n.highContrastDesc), findsOneWidget);
      expect(find.text(l10n.reduceMotion), findsOneWidget);
      expect(find.text(l10n.reduceMotionDesc), findsOneWidget);
      expect(find.text(l10n.emphasizeCaptions), findsOneWidget);
      expect(find.text(l10n.emphasizeCaptionsDesc), findsOneWidget);
      expect(find.text(l10n.accessibilityAppliedImmediately), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 2: 사용자 상호작용 검증
  // ------------------------------------------------------------------
  group('2. User Interaction Verification (UI -> Logic)', () {
    testWidgets(
      'Tapping "High Contrast" (off -> on) calls updateAccessibility(highContrast: true)',
      (WidgetTester tester) async {
        // [Given] 스위치가 꺼진 상태
        fakeHiveManager.settings.accessibilityHighContrast = false;
        await tester.pumpWidget(
          createTestableWidget(
            AccessibilityScreen(hiveManager: fakeHiveManager),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = getL10n(tester);
        fakeHiveManager.resetCallHistory();

        // [When] '고대비' 텍스트를 탭
        await tester.tap(find.text(l10n.highContrast));
        await tester.pumpAndSettle();

        // [Then]
        expect(fakeHiveManager.updateAccessibilityCalled, isTrue);
        expect(fakeHiveManager.lastAccessibilityValues['highContrast'], isTrue);
      },
    );

    testWidgets(
      'Tapping "High Contrast" (on -> off) calls updateAccessibility(highContrast: false)',
      (WidgetTester tester) async {
        // [Given] 스위치가 켜진 상태
        fakeHiveManager.settings.accessibilityHighContrast = true;
        await tester.pumpWidget(
          createTestableWidget(
            AccessibilityScreen(hiveManager: fakeHiveManager),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = getL10n(tester);
        fakeHiveManager.resetCallHistory();

        // [When] '고대비' 텍스트를 탭
        await tester.tap(find.text(l10n.highContrast));
        await tester.pumpAndSettle();

        // [Then]
        expect(fakeHiveManager.updateAccessibilityCalled, isTrue);
        expect(
          fakeHiveManager.lastAccessibilityValues['highContrast'],
          isFalse,
        );
      },
    );

    // (다른 두 스위치도 동일하게 검증 가능)
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 3: 리스너 검증
  // ------------------------------------------------------------------
  group('3. State Change Listener Verification (Logic -> UI)', () {
    testWidgets('Verify notifyListeners() updates UI (off -> on)', (
      WidgetTester tester,
    ) async {
      // [Given] 스위치가 모두 꺼진 상태
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);

      // [When] 1. 외부에서 설정이 변경됨
      fakeHiveManager.settings.accessibilityHighContrast = true;
      // [When] 2. 리스너가 호출됨
      fakeHiveManager.triggerNotifyListeners();
      await tester.pump(); // setState 반영

      // [Then] UI가 업데이트됨
      expect(getSwitchValue(tester, l10n.highContrast), isTrue);
    });

    testWidgets('Verify notifyListeners() updates UI (on -> off)', (
      WidgetTester tester,
    ) async {
      // [Given] 스위치가 모두 켜진 상태
      fakeHiveManager.settings.accessibilityHighContrast = true;
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);
      expect(getSwitchValue(tester, l10n.highContrast), isTrue);

      // [When] 1. 외부에서 설정이 변경됨
      fakeHiveManager.settings.accessibilityHighContrast = false;
      // [When] 2. 리스너가 호출됨
      fakeHiveManager.triggerNotifyListeners();
      await tester.pump(); // setState 반영

      // [Then] UI가 업데이트됨
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);
    });

    testWidgets('Verify removeListener is called on dispose', (
      WidgetTester tester,
    ) async {
      // [Given]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      expect(fakeHiveManager.removeListenerCalled, isFalse);

      // [When] 위젯을 트리에서 제거 (dispose)
      await tester.pumpWidget(Container());

      // [Then]
      expect(fakeHiveManager.removeListenerCalled, isTrue);
    });
  });
}
