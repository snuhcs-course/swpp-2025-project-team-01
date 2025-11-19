import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/features/settings/settings_screen.dart';

import 'settings_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NavigatorObserver>()])
void main() {
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockNavigatorObserver = MockNavigatorObserver();
  });

  // 테스트 헬퍼: 화면 펌핑
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
        navigatorObservers: [mockNavigatorObserver],
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

  // 테스트 헬퍼: 화면 펌핑 & 로컬라이제이션 가져오기
  Future<void> pumpAndGetL10n(WidgetTester tester) async {
    await pumpSettingsScreen(tester);
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(SettingsScreen)));
  }

  group('settings_screen.dart: Widget Test', () {
    group('1. UI Initial State Verification', () {
      testWidgets('AppBar title should display l10n.settings value', (
        tester,
      ) async {
        await pumpAndGetL10n(tester);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text(l10n.settings),
          ),
          findsOneWidget,
        );
      });

      testWidgets(
        'All settings menu ListTiles should be rendered with l10n text',
        (tester) async {
          await pumpAndGetL10n(tester);
          expect(find.text(l10n.displayMode), findsOneWidget);
          expect(find.text(l10n.accessibility), findsOneWidget);
          expect(find.text(l10n.language), findsOneWidget);
          expect(find.text(l10n.tts), findsOneWidget);
          expect(find.text(l10n.help), findsOneWidget);
        },
      );

      testWidgets('All ListTiles should display chevron_right icon', (
        tester,
      ) async {
        await pumpAndGetL10n(tester);
        expect(find.byType(ListTile), findsNWidgets(5));
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
      });
    });

    group('2. User Interaction Verification (Navigation)', () {
      testWidgets(
        'Tapping displayMode should navigate to settingsDisplay route',
        (tester) async {
          await pumpAndGetL10n(tester);

          await tester.tap(find.text(l10n.displayMode));
          await tester.pumpAndSettle();

          // 올바르게 이동하는지 확인
          verify(
            mockNavigatorObserver.didPush(
              argThat(
                isA<Route<dynamic>>().having(
                  (route) => route.settings.name,
                  'name',
                  Routes.settingsDisplay,
                ),
              ),
              any,
            ),
          ).called(1);
        },
      );

      testWidgets('Tapping TTS should navigate to settingsTts route', (
        tester,
      ) async {
        await pumpAndGetL10n(tester);

        await tester.tap(find.text('TTS 설정'));
        await tester.pumpAndSettle();

        verify(
          mockNavigatorObserver.didPush(
            argThat(
              isA<Route<dynamic>>().having(
                (route) => route.settings.name,
                'name',
                Routes.settingsTts,
              ),
            ),
            any,
          ),
        ).called(1);
      });

      testWidgets(
        'Tapping accessibility should navigate to settingsAccessibility route',
        (tester) async {
          await pumpAndGetL10n(tester);

          await tester.tap(find.text(l10n.accessibility));
          await tester.pumpAndSettle();

          verify(
            mockNavigatorObserver.didPush(
              argThat(
                isA<Route<dynamic>>().having(
                  (route) => route.settings.name,
                  'name',
                  Routes.settingsAccessibility,
                ),
              ),
              any,
            ),
          ).called(1);
        },
      );

      testWidgets(
        'Tapping language should navigate to settingsLanguage route',
        (tester) async {
          await pumpAndGetL10n(tester);

          await tester.tap(find.text(l10n.language));
          await tester.pumpAndSettle();

          verify(
            mockNavigatorObserver.didPush(
              argThat(
                isA<Route<dynamic>>().having(
                  (route) => route.settings.name,
                  'name',
                  Routes.settingsLanguage,
                ),
              ),
              any,
            ),
          ).called(1);
        },
      );

      testWidgets('Tapping Help should navigate to settingsHelp route', (
        tester,
      ) async {
        await pumpAndGetL10n(tester);

        await tester.tap(find.text('도움말'));
        await tester.pumpAndSettle();

        verify(
          mockNavigatorObserver.didPush(
            argThat(
              isA<Route<dynamic>>().having(
                (route) => route.settings.name,
                'name',
                Routes.settingsHelp,
              ),
            ),
            any,
          ),
        ).called(1);
      });
    });
  });
}
