// 앱 엔트리: 테마 + 라우터 연결
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/app_theme.dart';
import 'package:re_view/data/hive_manager.dart';

/// 앱 진입점 - HiveManager 초기화 후 앱 실행
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveManager.instance.init();
  runApp(const ReViewApp());
}

/// Re:View 앱의 루트 위젯
class ReViewApp extends StatefulWidget {
  const ReViewApp({super.key});

  @override
  State<ReViewApp> createState() => _ReViewAppState();
}

class _ReViewAppState extends State<ReViewApp> {
  @override
  void initState() {
    super.initState();
    // HiveManager 변경 리스너 등록 (테마, 언어, 접근성 모두 통합)
    HiveManager.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    HiveManager.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // String → ThemeMode 변환
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // String → Locale 변환
  Locale _localeFromString(String lang) {
    switch (lang) {
      case 'ko':
        return const Locale('ko', 'KR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ko', 'KR');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveManager.instance;
    final themeMode = _themeModeFromString(hive.settings.theme);
    final locale = _localeFromString(hive.settings.language);
    final isHighContrast = hive.settings.accessibilityHighContrast;
    final reduceMotion = hive.settings.accessibilityReduceMotion;

    // 고대비 모드가 활성화되면 고대비 테마 사용
    final ThemeData lightTheme = isHighContrast
        ? AppTheme.lightHighContrast
        : AppTheme.light;
    final ThemeData darkTheme = isHighContrast
        ? AppTheme.darkHighContrast
        : AppTheme.dark;

    // 모션 줄이기가 활성화되면 페이지 전환 애니메이션 제거
    return MaterialApp(
      title: 'Re:View',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: lightTheme.copyWith(
        pageTransitionsTheme: reduceMotion
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
                },
              )
            : null,
        drawerTheme: reduceMotion
            ? const DrawerThemeData(
                // Drawer 애니메이션 시간을 0으로 설정
                endShape: RoundedRectangleBorder(),
              )
            : null,
      ),
      darkTheme: darkTheme.copyWith(
        pageTransitionsTheme: reduceMotion
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
                },
              )
            : null,
        drawerTheme: reduceMotion
            ? const DrawerThemeData(endShape: RoundedRectangleBorder())
            : null,
      ),
      themeMode: themeMode,
      initialRoute: Routes.home, // 온보딩 전이라면 Routes.onboarding 사용
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // 모션 줄이기가 활성화되면 스크롤 물리 효과 제거
        if (reduceMotion) {
          return ScrollConfiguration(
            behavior: const _NoBouncingScrollBehavior(),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}

/// 페이지 전환 애니메이션 없음
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// 스크롤 바운싱 효과 제거
class _NoBouncingScrollBehavior extends ScrollBehavior {
  const _NoBouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
