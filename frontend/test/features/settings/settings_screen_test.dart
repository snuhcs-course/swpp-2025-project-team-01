// test/features/settings/settings_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/features/settings/settings_screen.dart';

// --- Fakes ---
class FakeNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedRouteNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
// --- End of Fakes ---

void main() {
  late FakeNavigatorObserver fakeNavigatorObserver;

  setUp(() {
    fakeNavigatorObserver = FakeNavigatorObserver();
  });

  // 위젯을 펌핑하는 헬퍼 함수
  Future<void> pumpSettingsScreen(WidgetTester tester) async {
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
        navigatorObservers: [fakeNavigatorObserver],
        routes: {
          Routes.settingsDisplay: (_) => const SizedBox.shrink(),
          Routes.settingsTts: (_) => const SizedBox.shrink(),
          Routes.settingsAccessibility: (_) => const SizedBox.shrink(),
          Routes.settingsLanguage: (_) => const SizedBox.shrink(),
          Routes.settingsHelp: (_) => const SizedBox.shrink(),
        },
        home: const SettingsScreen(),
      ),
    );
  }

  late AppLocalizations l10n;

  // 헬퍼 함수: 펌프 후 l10n 객체를 초기화
  Future<void> pumpAndGetL10n(WidgetTester tester) async {
    await pumpSettingsScreen(tester);
    await tester.pumpAndSettle(); 
    l10n = AppLocalizations.of(tester.element(find.byType(SettingsScreen)));
  }

  group('settings_screen.dart: Widget Test', () {
    // (group 1은 오류가 없었으므로 동일)
    group('1. UI Initial State Verification', () {
      testWidgets('AppBar 타이틀이 l10n.settings 값으로 표시되어야 함', (tester) async {
        await pumpAndGetL10n(tester);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text(l10n.settings),
          ),
          findsOneWidget,
        );
      });

      testWidgets('모든 설정 메뉴 ListTile이 l10n 텍스트와 함께 렌더링되어야 함',
          (tester) async {
        await pumpAndGetL10n(tester);
        expect(find.text(l10n.displayMode), findsOneWidget);
        expect(find.text(l10n.accessibility), findsOneWidget);
        expect(find.text(l10n.language), findsOneWidget);
        expect(find.text('TTS'), findsOneWidget);
        expect(find.text('Help'), findsOneWidget);
      });

      testWidgets('모든 ListTile이 chevron_right 아이콘을 표시해야 함', (tester) async {
        await pumpAndGetL10n(tester);
        expect(find.byType(ListTile), findsNWidgets(5));
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
      });
    });

    group('2. User Interaction Verification (Navigation)', () {
      
      testWidgets("'l10n.displayMode' 탭 시 settingsDisplay 라우트로 이동해야 함",
          (tester) async {
        await pumpAndGetL10n(tester);

        // ⬇️ **수정**: 탭하기 전에 네비게이터 기록을 초기화합니다.
        fakeNavigatorObserver.pushedRouteNames.clear();

        await tester.tap(find.text(l10n.displayMode));
        await tester.pumpAndSettle();

        expect(fakeNavigatorObserver.pushedRouteNames.length, 1);
        expect(
            fakeNavigatorObserver.pushedRouteNames.first, Routes.settingsDisplay);
      });

      testWidgets("'TTS' 탭 시 settingsTts 라우트로 이동해야 함", (tester) async {
        await pumpAndGetL10n(tester);

        // ⬇️ **수정**: 탭하기 전에 네비게이터 기록을 초기화합니다.
        fakeNavigatorObserver.pushedRouteNames.clear();

        await tester.tap(find.text('TTS'));
        await tester.pumpAndSettle();

        expect(fakeNavigatorObserver.pushedRouteNames.length, 1);
        expect(fakeNavigatorObserver.pushedRouteNames.first, Routes.settingsTts);
      });

      testWidgets("'l10n.accessibility' 탭 시 settingsAccessibility 라우트로 이동해야 함",
          (tester) async {
        await pumpAndGetL10n(tester);
        
        // ⬇️ **수정**: 탭하기 전에 네비게이터 기록을 초기화합니다.
        fakeNavigatorObserver.pushedRouteNames.clear();

        await tester.tap(find.text(l10n.accessibility));
        await tester.pumpAndSettle();

        expect(fakeNavigatorObserver.pushedRouteNames.length, 1);
        expect(fakeNavigatorObserver.pushedRouteNames.first,
            Routes.settingsAccessibility);
      });

      testWidgets("'l10n.language' 탭 시 settingsLanguage 라우트로 이동해야 함",
          (tester) async {
        await pumpAndGetL10n(tester);
        
        // ⬇️ **수정**: 탭하기 전에 네비게이터 기록을 초기화합니다.
        fakeNavigatorObserver.pushedRouteNames.clear();

        await tester.tap(find.text(l10n.language));
        await tester.pumpAndSettle();

        expect(fakeNavigatorObserver.pushedRouteNames.length, 1);
        expect(
            fakeNavigatorObserver.pushedRouteNames.first, Routes.settingsLanguage);
      });

      testWidgets("'Help' 탭 시 settingsHelp 라우트로 이동해야 함", (tester) async {
        await pumpAndGetL10n(tester);

        // ⬇️ **수정**: 탭하기 전에 네비게이터 기록을 초기화합니다.
        fakeNavigatorObserver.pushedRouteNames.clear();

        await tester.tap(find.text('Help'));
        await tester.pumpAndSettle();

        expect(fakeNavigatorObserver.pushedRouteNames.length, 1);
        expect(fakeNavigatorObserver.pushedRouteNames.first, Routes.settingsHelp);
      });
    });
  });
}