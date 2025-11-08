import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/features/settings/help_screen.dart';

void main() {
  // 테스트 헬퍼: HelpScreen 위젯 펌프
  Future<void> pumpHelpScreen(
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
        home: const HelpScreen(),
      ),
    );
  }

  group('help_screen.dart: Widget Test', () {
    group('1. UI Initial State Verification', () {
      testWidgets('AppBar title should display "Help"', (tester) async {
        await pumpHelpScreen(tester);
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text('Help')),
          findsOneWidget,
        );
      });

      testWidgets('All FAQ items should be rendered in Korean', (tester) async {
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(HelpScreen)),
        );

        // [Then] - FAQ 질문들이 표시되어야 함
        expect(find.text(l10n.howToFindLecture), findsOneWidget);
        expect(find.text(l10n.howToDeleteLecture), findsOneWidget);
        expect(find.text(l10n.howToEditSubjectTag), findsOneWidget);
        expect(find.text(l10n.howToReorder), findsOneWidget);
        expect(find.text(l10n.howToHideLoading), findsOneWidget);
        expect(find.text(l10n.howToViewSlidesAtPlayer), findsOneWidget);
        expect(find.text(l10n.howToUnsync), findsOneWidget);
      });

      testWidgets('All FAQ items should be rendered in English', (
        tester,
      ) async {
        await pumpHelpScreen(tester, locale: const Locale('en', 'US'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(HelpScreen)),
        );

        // [Then] - 영어 로케일에서는 isKorean이 false여야 함
        expect(l10n.isKorean, false);

        // ExpansionTile이 렌더링되어야 함
        expect(find.byType(ExpansionTile), findsWidgets);
      });

      testWidgets('Info cards should be displayed based on locale', (
        tester,
      ) async {
        // [Given] - 한국어 로케일
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        // [Then] - 카드가 표시되어야 함
        expect(find.byType(Card), findsWidgets);

        // [Given] - 영어 로케일
        await tester.pumpWidget(Container()); // 위젯 트리 초기화
        await pumpHelpScreen(tester, locale: const Locale('en', 'US'));
        await tester.pumpAndSettle();

        // [Then] - 카드가 표시되어야 함
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('FAQ items should be rendered as ExpansionTile', (
        tester,
      ) async {
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        // [Then] - 7개의 ExpansionTile이 있어야 함 (7개 FAQ 항목)
        expect(find.byType(ExpansionTile), findsNWidgets(7));
      });
    });

    group('2. User Interaction Verification', () {
      testWidgets('FAQ answer should expand when question is tapped', (
        tester,
      ) async {
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(HelpScreen)),
        );

        // [Given] - 초기에는 답변이 보이지 않아야 함
        expect(find.text(l10n.deleteLectureAtHome), findsNothing);

        // [When] - 질문을 탭하여 펼치기
        await tester.tap(find.text(l10n.howToDeleteLecture));
        await tester.pumpAndSettle();

        // [Then] - 이제 답변이 보여야 함
        expect(find.text(l10n.deleteLectureAtHome), findsOneWidget);
      });

      testWidgets('Expanded FAQ should collapse when tapped again', (
        tester,
      ) async {
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(HelpScreen)),
        );

        // [Given] - 탭하여 펼치기
        await tester.tap(find.text(l10n.howToEditSubjectTag));
        await tester.pumpAndSettle();
        expect(find.text(l10n.editTagAtSubjectEdit), findsOneWidget);

        // [When] - 다시 탭하여 접기
        await tester.tap(find.text(l10n.howToEditSubjectTag));
        await tester.pumpAndSettle();

        // [Then] - 답변이 다시 숨겨져야 함
        expect(find.text(l10n.editTagAtSubjectEdit), findsNothing);
      });

      testWidgets('Multiple FAQs can be expanded simultaneously', (
        tester,
      ) async {
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(HelpScreen)),
        );

        // [When] - 첫 번째 FAQ 펼치기
        await tester.tap(find.text(l10n.howToDeleteLecture));
        await tester.pumpAndSettle();

        // 두 번째 FAQ 펼치기
        await tester.tap(find.text(l10n.howToEditSubjectTag));
        await tester.pumpAndSettle();

        // [Then] - 두 답변 모두 보여야 함
        expect(find.text(l10n.deleteLectureAtHome), findsOneWidget);
        expect(find.text(l10n.editTagAtSubjectEdit), findsOneWidget);
      });
    });

    group('3. Icons Verification', () {
      testWidgets('Each FAQ item should display appropriate icon', (
        tester,
      ) async {
        await pumpHelpScreen(tester, locale: const Locale('ko'));
        await tester.pumpAndSettle();

        // [Then] - 특정 아이콘들이 있는지 확인
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
        expect(find.byIcon(Icons.tag), findsOneWidget);
        expect(find.byIcon(Icons.reorder), findsOneWidget);
        expect(find.byIcon(Icons.update), findsOneWidget);
        expect(find.byIcon(Icons.menu_book), findsOneWidget);
        expect(find.byIcon(Icons.sync), findsOneWidget);
      });
    });
  });
}
