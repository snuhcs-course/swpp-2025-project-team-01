import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/settings/accessibility_mode.dart';
import 'package:re_view/data/hive_models.dart';

import 'accessibility_mode_test.mocks.dart';

@GenerateMocks([HiveManager, AppSettings])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHiveManager mockHiveManager;
  late MockAppSettings mockSettings;

  setUp(() {
    mockHiveManager = MockHiveManager();
    mockSettings = MockAppSettings();

    // 기본 mock 설정
    when(mockHiveManager.settings).thenReturn(mockSettings);
    when(mockSettings.accessibilityHighContrast).thenReturn(false);
    when(mockSettings.accessibilityReduceMotion).thenReturn(false);
    when(mockSettings.accessibilityEmphasizeCaptions).thenReturn(false);
    when(
      mockHiveManager.updateAccessibility(
        highContrast: anyNamed('highContrast'),
        reduceMotion: anyNamed('reduceMotion'),
        emphasizeCaptions: anyNamed('emphasizeCaptions'),
      ),
    ).thenAnswer((_) async {});
  });

  // 테스트 헬퍼: 로컬라이제이션을 포함한 위젯 생성
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

  // 테스트 헬퍼: 스위치 값 가져오기
  bool getSwitchValue(WidgetTester tester, String titleText) {
    final switchTile = find.ancestor(
      of: find.text(titleText),
      matching: find.byType(SwitchListTile),
    );
    return tester.widget<SwitchListTile>(switchTile).value;
  }

  // 테스트 헬퍼: l10n 가져오기
  AppLocalizations getL10n(WidgetTester tester) {
    return AppLocalizations.of(
      tester.element(find.byType(AccessibilityScreen)),
    );
  }

  group('1. UI Initial State Verification (Mock Data -> UI)', () {
    testWidgets('Verify all switches are off when settings are false', (
      WidgetTester tester,
    ) async {
      // [Given] - 기본 mock 설정

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
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
      when(mockSettings.accessibilityHighContrast).thenReturn(true);

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
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
      when(mockSettings.accessibilityReduceMotion).thenReturn(true);

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
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
      when(mockSettings.accessibilityEmphasizeCaptions).thenReturn(true);

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
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
      when(mockSettings.accessibilityHighContrast).thenReturn(true);
      when(mockSettings.accessibilityReduceMotion).thenReturn(true);
      when(mockSettings.accessibilityEmphasizeCaptions).thenReturn(true);

      // [When]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
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
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);

      // [Then]
      expect(find.text(l10n.accessibility), findsOneWidget); // 앱바
      expect(find.text(l10n.highContrast), findsOneWidget);
      expect(find.text(l10n.highContrastDesc), findsOneWidget);
      expect(find.text(l10n.reduceMotion), findsOneWidget);
      expect(find.text(l10n.reduceMotionDesc), findsOneWidget);
      expect(find.text(l10n.emphasizeCaptions), findsOneWidget);
      expect(find.text(l10n.emphasizeCaptionsDesc), findsOneWidget);
      expect(find.text(l10n.accessibilityAppliedImmediately), findsOneWidget);
    });
  });

  group('2. User Interaction Verification (UI -> Logic)', () {
    testWidgets(
      'Tapping "High Contrast" (off -> on) calls updateAccessibility(highContrast: true)',
      (WidgetTester tester) async {
        // [Given] - 스위치가 꺼져있음
        when(mockSettings.accessibilityHighContrast).thenReturn(false);
        await tester.pumpWidget(
          createTestableWidget(
            AccessibilityScreen(hiveManager: mockHiveManager),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = getL10n(tester);

        // [When] - 고대비 텍스트 탭
        await tester.tap(find.text(l10n.highContrast));
        await tester.pumpAndSettle();

        // [Then]
        verify(
          mockHiveManager.updateAccessibility(highContrast: true),
        ).called(1);
      },
    );

    testWidgets(
      'Tapping "High Contrast" (on -> off) calls updateAccessibility(highContrast: false)',
      (WidgetTester tester) async {
        // [Given] - 스위치가 켜져있음
        when(mockSettings.accessibilityHighContrast).thenReturn(true);
        await tester.pumpWidget(
          createTestableWidget(
            AccessibilityScreen(hiveManager: mockHiveManager),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = getL10n(tester);

        // [When] - 고대비 텍스트 탭
        await tester.tap(find.text(l10n.highContrast));
        await tester.pumpAndSettle();

        // [Then]
        verify(
          mockHiveManager.updateAccessibility(highContrast: false),
        ).called(1);
      },
    );

    testWidgets(
      'Tapping "Reduce Motion" (off -> on) calls updateAccessibility(reduceMotion: true)',
      (WidgetTester tester) async {
        // [Given]
        when(mockSettings.accessibilityReduceMotion).thenReturn(false);
        await tester.pumpWidget(
          createTestableWidget(
            AccessibilityScreen(hiveManager: mockHiveManager),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = getL10n(tester);

        // [When]
        await tester.tap(find.text(l10n.reduceMotion));
        await tester.pumpAndSettle();

        // [Then]
        verify(
          mockHiveManager.updateAccessibility(reduceMotion: true),
        ).called(1);
      },
    );

    testWidgets(
      'Tapping "Emphasize Captions" (off -> on) calls updateAccessibility(emphasizeCaptions: true)',
      (WidgetTester tester) async {
        // [Given]
        when(mockSettings.accessibilityEmphasizeCaptions).thenReturn(false);
        await tester.pumpWidget(
          createTestableWidget(
            AccessibilityScreen(hiveManager: mockHiveManager),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = getL10n(tester);

        // [When]
        await tester.tap(find.text(l10n.emphasizeCaptions));
        await tester.pumpAndSettle();

        // [Then]
        verify(
          mockHiveManager.updateAccessibility(emphasizeCaptions: true),
        ).called(1);
      },
    );
  });

  group('3. State Change Listener Verification (Logic -> UI)', () {
    testWidgets('Verify notifyListeners() updates UI (off -> on)', (
      WidgetTester tester,
    ) async {
      // [Given] - 스위치가 꺼져있음
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);

      // [When] - 설정의 외부 변경
      when(mockSettings.accessibilityHighContrast).thenReturn(true);
      // 리스너 수동 트리거
      final listener =
          verify(mockHiveManager.addListener(captureAny)).captured.single
              as VoidCallback;
      listener();
      await tester.pump(); // setState 반영

      // [Then] - UI가 업데이트됨
      expect(getSwitchValue(tester, l10n.highContrast), isTrue);
    });

    testWidgets('Verify notifyListeners() updates UI (on -> off)', (
      WidgetTester tester,
    ) async {
      // [Given] - 스위치가 켜져있음
      when(mockSettings.accessibilityHighContrast).thenReturn(true);
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();
      final l10n = getL10n(tester);
      expect(getSwitchValue(tester, l10n.highContrast), isTrue);

      // [When] - 설정의 외부 변경
      when(mockSettings.accessibilityHighContrast).thenReturn(false);
      // 리스너 수동 트리거
      final listener =
          verify(mockHiveManager.addListener(captureAny)).captured.single
              as VoidCallback;
      listener();
      await tester.pump(); // setState 반영

      // [Then] - UI가 업데이트됨
      expect(getSwitchValue(tester, l10n.highContrast), isFalse);
    });

    testWidgets('Verify removeListener is called on dispose', (
      WidgetTester tester,
    ) async {
      // [Given]
      await tester.pumpWidget(
        createTestableWidget(AccessibilityScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // 리스너 캡처
      final listener =
          verify(mockHiveManager.addListener(captureAny)).captured.single
              as VoidCallback;

      // [When] - 위젯 트리에서 제거 (dispose)
      await tester.pumpWidget(Container());

      // [Then]
      verify(mockHiveManager.removeListener(listener)).called(1);
    });
  });
}
