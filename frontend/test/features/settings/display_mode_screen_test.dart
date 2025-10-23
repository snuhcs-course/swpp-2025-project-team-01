// test/features/settings/display_mode_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/settings/display_mode_screen.dart';
import 'package:re_view/data/hive_models.dart';

// ------------------------------------------------------------------
// 1. Mockito 대신 사용할 "가짜" 클래스 정의
// ------------------------------------------------------------------

/// AppSettings를 흉내내는 가짜 클래스
class FakeAppSettings extends AppSettings {
  String _theme = 'system';

  @override
  String get theme => _theme;

  // 테스트 코드에서 이 함수를 호출해 값을 설정합니다.
  void setFakeTheme(String newTheme) {
    _theme = newTheme;
  }
}

/// HiveManager를 흉내내는 가짜 클래스
class FakeHiveManager extends Fake implements HiveManager {
  final FakeAppSettings _fakeSettings = FakeAppSettings();
  bool updateThemeCalled = false;
  String lastThemeValue = '';

  @override
  AppSettings get settings => _fakeSettings;

  @override
  Future<void> updateTheme(String theme) async {
    // 이 함수가 호출되었는지, 어떤 값으로 호출되었는지 기록합니다.
    updateThemeCalled = true;
    lastThemeValue = theme;
    // 실제 앱처럼 가짜 설정 값도 변경합니다.
    _fakeSettings.setFakeTheme(theme);
  }

  // 테스트 리셋을 위한 헬퍼
  void resetCallHistory() {
    updateThemeCalled = false;
    lastThemeValue = '';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // ------------------------------------------------------------------
  // 테스트 설정 (Setup)
  // ------------------------------------------------------------------

  // 2. "Fake" 객체 선언
  late FakeHiveManager fakeHiveManager;

  // 3. 각 테스트 실행 *전*에 Fake 객체를 초기화
  setUp(() {
    fakeHiveManager = FakeHiveManager();
  });

  // 4. 테스트용 헬퍼 함수
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

  // 5. 테스트용 헬퍼 함수
  String? getRadioGroupValue(WidgetTester tester, String labelText) {
    final listTile = find.ancestor(
      of: find.text(labelText),
      matching: find.byType(ListTile),
    );
    final radioGroup = tester.widget<RadioGroup<String>>(
      find.descendant(of: listTile, matching: find.byType(RadioGroup<String>)),
    );
    return radioGroup.groupValue;
  }

  // 6. 테스트용 헬퍼 함수
  Color? getPreviewBoxColor(WidgetTester tester, String labelText) {
    final label = find.text(labelText);
    final previewBox = find.ancestor(
      of: label,
      matching: find.byType(Container),
    );
    final decoration =
        tester.widget<Container>(previewBox).decoration as BoxDecoration;
    return decoration.color;
  }

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 1: UI 초기 상태 검증
  // ------------------------------------------------------------------
  group('1. UI Initial State Verification (Mock Data -> UI)', () {
    testWidgets('Verify "System Settings" is selected when theme is "system"', (
      WidgetTester tester,
    ) async {
      // [Given] 'system'을 반환하도록 Fake 객체 설정
      (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('system');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then] '시스템 설정' 라디오 버튼의 groupValue가 'system'인지 확인
      expect(getRadioGroupValue(tester, '시스템 설정'), 'system');
    });

    testWidgets('Verify "Light Mode" is selected when theme is "light"', (
      WidgetTester tester,
    ) async {
      // [Given]
      (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('light');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getRadioGroupValue(tester, '라이트 모드'), 'light');
    });

    testWidgets('Verify "Dark Mode" is selected when theme is "dark"', (
      WidgetTester tester,
    ) async {
      // [Given]
      (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('dark');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getRadioGroupValue(tester, '다크 모드'), 'dark');
    });

    // [추가된 테스트 1-4]
    testWidgets('Verify all localized texts are displayed correctly', (
      WidgetTester tester,
    ) async {
      // [Given]
      (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('system');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(find.text('디스플레이 모드'), findsOneWidget); // AppBar 제목
      // '라이트 모드'는 라디오 텍스트 1개, 프리뷰 텍스트 1개 = 총 2개
      expect(find.text('라이트 모드'), findsNWidgets(2));
      expect(find.text('다크 모드'), findsNWidgets(2));
      expect(find.text('시스템 설정'), findsNWidgets(2));
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 2: 사용자 상호작용 검증
  // ------------------------------------------------------------------
  group('2. User Interaction Verification (UI -> Logic)', () {
    // [Given] 모든 테스트는 'system' 모드에서 시작
    setUp(() {
      (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('system');
    });

    testWidgets(
      'Tapping "Light Mode" calls updateTheme("light") exactly once',
      (WidgetTester tester) async {
        // [Given]
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
        );
        await tester.pumpAndSettle();
        fakeHiveManager.resetCallHistory(); // 호출 기록 초기화

        // [When] '라이트 모드' ListTile을 탭
        await tester.tap(find.text('라이트 모드').first);
        await tester.pumpAndSettle(); // setState 대기

        // [Then] Fake 객체의 updateTheme('light')가 호출되었는지 확인
        expect(fakeHiveManager.updateThemeCalled, isTrue);
        expect(fakeHiveManager.lastThemeValue, 'light');
      },
    );

    // [추가된 테스트 2-2]
    testWidgets('Tapping "Dark Mode" calls updateTheme("dark") exactly once', (
      WidgetTester tester,
    ) async {
      // [Given]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();
      fakeHiveManager.resetCallHistory();

      // [When] '다크 모드' ListTile을 탭
      await tester.tap(find.text('다크 모드').first);
      await tester.pumpAndSettle();

      // [Then]
      expect(fakeHiveManager.updateThemeCalled, isTrue);
      expect(fakeHiveManager.lastThemeValue, 'dark');
    });

    // [추가된 테스트 2-3]
    testWidgets(
      'Tapping "System Settings" calls updateTheme("system") exactly once',
      (WidgetTester tester) async {
        // [Given] (다른 값에서 변경하는 것을 확인하기 위해 'light'에서 시작)
        (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('light');
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
        );
        await tester.pumpAndSettle();
        fakeHiveManager.resetCallHistory();

        // [When] '시스템 설정' ListTile을 탭
        await tester.tap(find.text('시스템 설정').first);
        await tester.pumpAndSettle();

        // [Then]
        expect(fakeHiveManager.updateThemeCalled, isTrue);
        expect(fakeHiveManager.lastThemeValue, 'system');
      },
    );

    testWidgets(
      'Tapping "Light Mode" updates UI radio state (verifies setState)',
      (WidgetTester tester) async {
        // [Given] 'system' 모드에서 시작
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
        );
        await tester.pumpAndSettle();
        expect(getRadioGroupValue(tester, '시스템 설정'), 'system');

        // [When] '라이트 모드' 탭
        await tester.tap(find.text('라이트 모드').first);
        await tester.pumpAndSettle(); // setState() 대기

        // [Then] UI가 'light'로 변경되었는지 확인
        expect(getRadioGroupValue(tester, '라이트 모드'), 'light');
      },
    );
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 3: 프리뷰 박스 상태 검증
  // ------------------------------------------------------------------
  group('3. Preview Box State Verification', () {
    // 코드에 정의된 실제 색상값
    const Color darkColor = Color(0xFF2B2B2B);
    const Color lightColor = Color(0xFFF2F2F2);

    setUp(() {
      (fakeHiveManager.settings as FakeAppSettings).setFakeTheme('system');
    });

    // [추가된 테스트 3-1]
    testWidgets('Verify "Light Mode" preview box is light', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getPreviewBoxColor(tester, '라이트 모드'), lightColor);
    });

    // [추가된 테스트 3-2]
    testWidgets('Verify "Dark Mode" preview box is dark', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getPreviewBoxColor(tester, '다크 모드'), darkColor);
    });

    testWidgets(
      'Verify "System" preview box matches the actual platform brightness',
      (WidgetTester tester) async {
        // [Given]
        final brightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        final expectedColor = (brightness == Brightness.dark)
            ? darkColor
            : lightColor;

        // [When]
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: fakeHiveManager)),
        );
        await tester.pumpAndSettle();

        // [Then]
        expect(getPreviewBoxColor(tester, '시스템 설정'), expectedColor);
      },
    );
  });
}
