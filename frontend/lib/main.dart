// 앱 엔트리: 테마 + 라우터 연결
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_router.dart';
import 'core/accessibility_service.dart';
import 'core/language_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'data/repository.dart';

/// 앱 진입점 - Repository 초기화 후 앱 실행
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repo.instance.init();
  await ThemeManager.instance.loadThemeMode();
  await AccessibilityService().initialize();
  await LanguageService.instance.initialize();
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
    // ThemeManager 변경 리스너 등록
    ThemeManager.instance.addListener(_onThemeChanged);
    // AccessibilityService 변경 리스너 등록
    AccessibilityService().addListener(_onAccessibilityChanged);
    // LanguageService 변경 리스너 등록
    LanguageService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    ThemeManager.instance.removeListener(_onThemeChanged);
    AccessibilityService().removeListener(_onAccessibilityChanged);
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAccessibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    final languageService = LanguageService.instance;
    final themeMode = ThemeManager.instance.themeMode;
    final isHighContrast = accessibilityService.highContrast;
    final reduceMotion = accessibilityService.reduceMotion;

    // 고대비 모드가 활성화되면 고대비 테마 사용
    ThemeData lightTheme = isHighContrast ? AppTheme.lightHighContrast : AppTheme.light;
    ThemeData darkTheme = isHighContrast ? AppTheme.darkHighContrast : AppTheme.dark;

    // 모션 줄이기가 활성화되면 페이지 전환 애니메이션 제거
    return MaterialApp(
      title: 'Re:View',
      locale: languageService.locale,
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
            ? const DrawerThemeData(
                endShape: RoundedRectangleBorder(),
              )
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