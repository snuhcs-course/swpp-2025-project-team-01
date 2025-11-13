// 앱 엔트리: 테마 + 라우터 연결
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

import 'dart:io' show Platform, Directory, File;

import 'package:path_provider/path_provider.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/app_theme.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/shared/widgets.dart';

// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 캐시 디렉토리 정리 (앱 시작 시)
/// pdfx 라이브러리가 생성한 UUID 형태의 PDF 캐시 파일들을 삭제
Future<void> _cleanupCache() async {
  try {
    final cacheDir = await getTemporaryDirectory();

    if (!cacheDir.existsSync()) {
      return;
    }

    // 캐시 디렉토리의 모든 파일 삭제
    final files = cacheDir.listSync();
    int deletedCount = 0;

    for (final file in files) {
      try {
        if (file is File) {
          await file.delete();
          deletedCount++;
        } else if (file is Directory) {
          await file.delete(recursive: true);
          deletedCount++;
        }
      } catch (e) {
        // 삭제 실패는 무시 (파일이 사용 중일 수 있음)
      }
    }

    debugPrint('✅ Cache cleanup completed: $deletedCount items deleted');
  } catch (e) {
    debugPrint('⚠️ Failed to cleanup cache: $e');
  }
}

/// 앱 진입점 - HiveManager 초기화 후 앱 실행
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // pdfx가 생성한 캐시 파일들 정리
  await _cleanupCache();

  // HiveManager 초기화
  await HiveManager.instance.init();

  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  runApp(const ReViewApp());
}

/// Re:View 앱의 루트 위젯
class ReViewApp extends StatefulWidget {
  const ReViewApp({super.key});

  @override
  State<ReViewApp> createState() => _ReViewAppState();
}

class _ReViewAppState extends State<ReViewApp> {
  late final HiveManager _manager = HiveManager.instance;

  @override
  void initState() {
    super.initState();
    // HiveManager 변경 리스너 등록 (테마, 언어, 접근성 모두 통합)
    _manager.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    _manager.removeListener(_onDataChanged);
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
      navigatorKey: navigatorKey,
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
      initialRoute: Routes.onboarding,

      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // NativeDeviceOrientationReader로 정확한 디바이스 방향 감지
        return NativeDeviceOrientationReader(
          builder: (context) {
            Widget wrappedChild = child!;

            if (reduceMotion) {
              wrappedChild = ScrollConfiguration(
                behavior: const _NoBouncingScrollBehavior(),
                child: wrappedChild,
              );
            }

            // 모든 화면 위에 로딩 바 오버레이 추가
            return Stack(children: [wrappedChild, const LectureLoadingBar()]);
          },
        );
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
