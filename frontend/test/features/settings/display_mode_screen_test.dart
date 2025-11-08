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
      expect(getRadioGroupValue(tester, '시스템 설정'), 'system');
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
      expect(getRadioGroupValue(tester, '라이트 모드'), 'light');
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
      expect(getRadioGroupValue(tester, '다크 모드'), 'dark');
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
      expect(find.text('라이트 모드'), findsNWidgets(2));
      expect(find.text('다크 모드'), findsNWidgets(2));
      expect(find.text('시스템 설정'), findsNWidgets(2));
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
        await tester.tap(find.text('라이트 모드').first);
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
      await tester.tap(find.text('다크 모드').first);
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
        await tester.tap(find.text('시스템 설정').first);
        await tester.pumpAndSettle();

        // [Then]
        verify(mockHiveManager.updateTheme('system')).called(1);
      },
    );

    testWidgets(
      'Tapping "Light Mode" updates UI radio state (verifies setState)',
      (WidgetTester tester) async {
        // [Given] - 'system'에서 시작
        await tester.pumpWidget(
          createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
        );
        await tester.pumpAndSettle();
        expect(getRadioGroupValue(tester, '시스템 설정'), 'system');

        // updateTheme 호출 후 테마 변경 시뮬레이션
        when(mockSettings.theme).thenReturn('light');

        // [When]
        await tester.tap(find.text('라이트 모드').first);
        await tester.pumpAndSettle();

        // [Then]
        expect(getRadioGroupValue(tester, '라이트 모드'), 'light');
      },
    );
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

    testWidgets('All preview boxes should have labels displayed twice', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then] - 모든 라벨이 2번씩 표시됨 (라디오 버튼 + 미리보기 박스)
      expect(find.text('라이트 모드'), findsNWidgets(2));
      expect(find.text('다크 모드'), findsNWidgets(2));
      expect(find.text('시스템 설정'), findsNWidgets(2));
    });

    testWidgets('Preview boxes should be inside Expanded widgets', (
      WidgetTester tester,
    ) async {
      // [When]
      await tester.pumpWidget(
        createTestableWidget(DisplayModeScreen(hiveManager: mockHiveManager)),
      );
      await tester.pumpAndSettle();

      // [Then] - Row 안에 3개의 Expanded 위젯이 있어야 함
      final rowFinder = find.byType(Row);
      final expandedInRow = find.descendant(
        of: rowFinder,
        matching: find.byType(Expanded),
      );
      expect(expandedInRow, findsAtLeastNWidgets(3));
    });
  });
}
