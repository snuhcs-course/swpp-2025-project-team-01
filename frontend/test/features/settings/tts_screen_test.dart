import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/settings/tts_screen.dart';

import 'tts_screen_test.mocks.dart';

@GenerateMocks([HiveManager, AppSettings])
void main() {
  late MockHiveManager mockHiveManager;
  late MockAppSettings mockSettings;

  setUp(() {
    mockHiveManager = MockHiveManager();
    mockSettings = MockAppSettings();

    // 기본 mock 설정 - 여성으로 고정 (TTS 화면이 현재 여성만 지원)
    when(mockHiveManager.settings).thenReturn(mockSettings);
    when(mockSettings.ttsGender).thenReturn('여성');
    when(
      mockHiveManager.updateTts(gender: anyNamed('gender')),
    ).thenAnswer((_) async {});
    when(mockHiveManager.addListener(any)).thenReturn(null);
    when(mockHiveManager.removeListener(any)).thenReturn(null);
  });

  Future<void> pumpTtsScreen(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: TtsScreen(hiveManager: mockHiveManager),
      ),
    );

    await tester.pump(); // 로딩 시작
    await tester.pump(const Duration(seconds: 1)); // 로딩 완료 대기
  }

  group('tts_screen.dart: Widget Test', () {
    group('1. UI Initial State Verification (Mock Data -> UI)', () {
      testWidgets('Main Scaffold should be rendered', (tester) async {
        await pumpTtsScreen(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('AppBar title should be "TTS" with close button', (
        tester,
      ) async {
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

      testWidgets('Korean labels should be displayed in Korean locale', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('ko'));

        expect(find.text('TTS 음성 성별'), findsOneWidget);
        expect(find.text('남성'), findsOneWidget);
        expect(find.text('여성'), findsOneWidget);
      });

      testWidgets('English labels should be displayed in English locale', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('en'));

        expect(find.text('TTS Voice Gender'), findsOneWidget);
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
      });

      testWidgets('Gender selection buttons should be rendered', (
        tester,
      ) async {
        await pumpTtsScreen(tester, locale: const Locale('ko'));

        expect(find.text('남성'), findsOneWidget);
        expect(find.text('여성'), findsOneWidget);
      });

      testWidgets('Notice text should be displayed', (tester) async {
        await pumpTtsScreen(tester, locale: const Locale('ko'));

        expect(find.textContaining('현재 여성 TTS 음성만 지원됩니다'), findsOneWidget);
      });
    });
  });
}
