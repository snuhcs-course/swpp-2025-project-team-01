import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/settings/display_mode_screen.dart';
import 'package:re_view/data/hive_models.dart';

import 'display_mode_screen_test.mocks.dart';

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
    when(mockSettings.theme).thenReturn('system');
    when(mockHiveManager.updateTheme(any)).thenAnswer((_) async {});
  });

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

  String? getCurrentThemeMode(WidgetTester tester) {
    final radioGroupFinder = find.byType(RadioGroup<String>);
    // RadioGroup 위젯을 찾아 현재 groupValue를 반환
    final radioGroup = tester.widget<RadioGroup<String>>(radioGroupFinder);
    return radioGroup.groupValue;
  }

  group('1. UI Initial State Verification (Mock Data -> UI)', () {
    testWidgets('Verify "System Settings" is selected when theme is "system"', (
      WidgetTester tester,
    ) async {
      // [Given] - 기본 mock 설정에 'system'이 있음
      when(mockSettings.theme).thenReturn('system');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getCurrentThemeMode(tester), 'system');
    });

    testWidgets('Verify "Light Mode" is selected when theme is "light"', (
      WidgetTester tester,
    ) async {
      // [Given]
      when(mockSettings.theme).thenReturn('light');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getCurrentThemeMode(tester), 'light');
    });

    testWidgets('Verify "Dark Mode" is selected when theme is "dark"', (
      WidgetTester tester,
    ) async {
      // [Given]
      when(mockSettings.theme).thenReturn('dark');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(getCurrentThemeMode(tester), 'dark');
    });

    testWidgets('Verify all localized texts are displayed correctly', (
      WidgetTester tester,
    ) async {
      // [Given]
      when(mockSettings.theme).thenReturn('system');

      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      expect(find.text('디스플레이 모드'), findsOneWidget);
      expect(find.text('라이트 모드'), findsOneWidget);
      expect(find.text('다크 모드'), findsOneWidget);
      expect(find.text('시스템 설정'), findsOneWidget);
    });
  });

  group('2. User Interaction Verification (UI -> Logic)', () {
    setUp(() {
      when(mockSettings.theme).thenReturn('system');
    });

    testWidgets(
      'Tapping "Light Mode" calls updateTheme("light") exactly once',
      (WidgetTester tester) async {
        // [Given]
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
        );
        await tester.pumpAndSettle();

        // [When]
        await tester.tap(find.byType(Image).at(0));
        await tester.pumpAndSettle();

        // [Then]
        verify(mockHiveManager.updateTheme('light')).called(1);
      },
    );

    testWidgets('Tapping "Dark Mode" calls updateTheme("dark") exactly once', (
      WidgetTester tester,
    ) async {
      // [Given]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [When]
      await tester.tap(find.byType(Image).at(1));
      await tester.pumpAndSettle();

      // [Then]
      verify(mockHiveManager.updateTheme('dark')).called(1);
    });

    testWidgets(
      'Tapping "System Settings" calls updateTheme("system") exactly once',
      (WidgetTester tester) async {
        // [Given] - 변경 확인을 위해 'light'에서 시작
        when(mockSettings.theme).thenReturn('light');
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
        );
        await tester.pumpAndSettle();

        // [When]
        await tester.tap(find.byType(Image).at(2));
        await tester.pumpAndSettle();

        // [Then]
        verify(mockHiveManager.updateTheme('system')).called(1);
      },
    );

    testWidgets('Tapping updates UI radio state (verifies setState)', (
      WidgetTester tester,
    ) async {
      // [Given] - 'system'에서 시작
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();
      expect(getCurrentThemeMode(tester), 'system');

      // updateTheme 호출 후 테마 변경 시뮬레이션
      when(mockSettings.theme).thenReturn('light');

      // [When]
      await tester.tap(find.byType(Image).at(0));
      await tester.pumpAndSettle();

      // [Then]
      expect(getCurrentThemeMode(tester), 'light');
    });
  });

  group('3. Preview Images Verification', () {
    setUp(() {
      when(mockSettings.theme).thenReturn('system');
    });

    testWidgets('Preview images should be rendered for all modes', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then] - 3개의 미리보기 이미지가 있어야 함 (light, dark, system)
      expect(find.byType(Image), findsNWidgets(3));
    });

    testWidgets('Layout should use Wrap for responsiveness', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then]
      // 1. Wrap 위젯이 존재해야 함
      expect(find.byType(Wrap), findsOneWidget);

      // 2. Expanded 위젯은 더 이상 사용되지 않아야 함
      expect(find.byType(Expanded), findsNothing);

      // 3. 아이템들은 SizedBox로 너비가 지정되어야 함
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
