import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/settings/language_screen.dart';

import 'language_screen_test.mocks.dart';

@GenerateMocks([HiveManager, AppSettings])
void main() {
  late MockHiveManager mockHiveManager;
  late MockAppSettings mockSettings;

  setUp(() {
    mockHiveManager = MockHiveManager();
    mockSettings = MockAppSettings();

    // 기본 mock 설정
    when(mockHiveManager.settings).thenReturn(mockSettings);
    when(mockSettings.language).thenReturn('ko');
    when(mockHiveManager.updateLanguage(any)).thenAnswer((_) async {});
  });

  // 테스트 헬퍼: 화면 펌핑
  Future<void> pumpLanguageScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LanguageScreen(hiveManager: mockHiveManager),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('language_screen.dart: Widget Test', () {
    group('1. UI Initial State Verification (Mock Data -> UI)', () {
      testWidgets('Korean should be selected when language is "ko"', (
        tester,
      ) async {
        // [Given] - 기본 한국어
        when(mockSettings.language).thenReturn('ko');

        // [When]
        await pumpLanguageScreen(tester);
        await tester.pump();

        // [Then] - 라디오 그룹이 한국어여야 함
        final koRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('한국어'),
            matching: find.byType(RadioGroup<String>),
          ),
        );
        final enRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('English'),
            matching: find.byType(RadioGroup<String>),
          ),
        );

        expect(koRadioGroup.groupValue, 'ko');
        expect(enRadioGroup.groupValue, 'ko');
      });

      testWidgets('English should be selected when language is "en"', (
        tester,
      ) async {
        // [Given]
        when(mockSettings.language).thenReturn('en');

        // [When]
        await pumpLanguageScreen(tester);
        await tester.pump();

        // [Then]
        final koRadioGroup = tester.widget<RadioGroup<String>>(
          find.ancestor(
            of: find.text('한국어'),
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

      testWidgets('AppBar title should display "Language / 언어"', (
        tester,
      ) async {
        // [Given]
        when(mockSettings.language).thenReturn('en');

        // [When]
        await pumpLanguageScreen(tester);

        // [Then]
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.title, isA<Text>());

        final titleText = appBar.title as Text;
        expect(titleText.data, 'Language / 언어');
      });
    });

    group('2. User Interaction Verification (UI -> Mock Logic)', () {
      testWidgets('Tapping Korean should call updateLanguage with "ko"', (
        tester,
      ) async {
        // [Given]
        when(mockSettings.language).thenReturn('en');
        await pumpLanguageScreen(tester);

        // [When]
        await tester.tap(find.text('한국어'));
        await tester.pumpAndSettle();

        // [Then]
        verify(mockHiveManager.updateLanguage('ko')).called(1);
      });

      testWidgets('Tapping English should call updateLanguage with "en"', (
        tester,
      ) async {
        // [Given]
        when(mockSettings.language).thenReturn('ko');
        await pumpLanguageScreen(tester);

        // [When]
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        // [Then]
        verify(mockHiveManager.updateLanguage('en')).called(1);
      });
    });

    group('3. State Change Listener Verification (Mock Logic -> UI)', () {
      testWidgets(
        'UI should update to English when external change to "en" occurs',
        (tester) async {
          // [Given]
          when(mockSettings.language).thenReturn('ko');
          await pumpLanguageScreen(tester);

          final initialRadioGroup = tester.widget<RadioGroup<String>>(
            find.ancestor(
              of: find.text('English'),
              matching: find.byType(RadioGroup<String>),
            ),
          );
          expect(initialRadioGroup.groupValue, 'ko');

          // [When] - 외부 변화 시뮬레이션
          when(mockSettings.language).thenReturn('en');
          // 리스너 수동으로 불러오기
          final listener =
              verify(mockHiveManager.addListener(captureAny)).captured.single
                  as VoidCallback;
          listener();
          await tester.pump();

          // [Then]
          final updatedRadioGroup = tester.widget<RadioGroup<String>>(
            find.ancestor(
              of: find.text('English'),
              matching: find.byType(RadioGroup<String>),
            ),
          );
          expect(updatedRadioGroup.groupValue, 'en');
        },
      );

      testWidgets(
        'UI should update to Korean when external change to "ko" occurs',
        (tester) async {
          // [Given]
          when(mockSettings.language).thenReturn('en');
          await pumpLanguageScreen(tester);

          final initialRadioGroup = tester.widget<RadioGroup<String>>(
            find.ancestor(
              of: find.text('한국어'),
              matching: find.byType(RadioGroup<String>),
            ),
          );
          expect(initialRadioGroup.groupValue, 'en');

          // [When] - 외부 변화 시뮬레이션
          when(mockSettings.language).thenReturn('ko');
          // 리스너 수동으로 불러오기
          final listener =
              verify(mockHiveManager.addListener(captureAny)).captured.single
                  as VoidCallback;
          listener();
          await tester.pump(); // 화면 리빌드

          // [Then]
          final updatedRadioGroup = tester.widget<RadioGroup<String>>(
            find.ancestor(
              of: find.text('한국어'),
              matching: find.byType(RadioGroup<String>),
            ),
          );
          expect(updatedRadioGroup.groupValue, 'ko');
        },
      );

      testWidgets('Listener should be removed on dispose', (tester) async {
        // [Given]
        await pumpLanguageScreen(tester);

        // 리스너 감지
        final listener =
            verify(mockHiveManager.addListener(captureAny)).captured.single
                as VoidCallback;

        // [When] - 위젯 디스포즈
        await tester.pumpWidget(Container());

        // [Then]
        verify(mockHiveManager.removeListener(listener)).called(1);
      });
    });
  });
}
