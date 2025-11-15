import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:re_view/app_router.dart';
import 'package:re_view/features/splash/splash_screen.dart';

import 'splash_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NavigatorObserver>()])
void main() {
  late MockNavigatorObserver mockObserver;

  setUp(() {
    mockObserver = MockNavigatorObserver();
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: const SplashScreen(),
      navigatorObservers: [mockObserver],
      routes: {Routes.home: (_) => const Placeholder(key: Key('home-screen'))},
    );
  }

  testWidgets('shows logo and gradient title text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Re:View'), findsOneWidget);
    expect(find.byType(GradientTitle), findsOneWidget);
  });

  testWidgets('fade animation progresses before navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    // At t = 0
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the animation finish (~900ms), but not the 1500ms timer
    await tester.pump(const Duration(milliseconds: 1000));

    // Still on SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('home-screen')), findsNothing);

    final opacityFinder = find.descendant(
      of: find.byType(AnimatedBuilder),
      matching: find.byType(Opacity),
    );
    expect(opacityFinder, findsOneWidget);

    final opacityWidget = tester.widget<Opacity>(opacityFinder);
    expect(opacityWidget.opacity, greaterThan(0.0));
  });

  testWidgets('navigates to home after 1500ms', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('home-screen')), findsNothing);

    // Just before timer fires
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('home-screen')), findsNothing);

    // Cross the 1500ms threshold
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Now on home screen
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    verify(
      mockObserver.didReplace(
        newRoute: anyNamed('newRoute'),
        oldRoute: anyNamed('oldRoute'),
      ),
    ).called(1);
  });
}
