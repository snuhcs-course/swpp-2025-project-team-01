// 앱 엔트리: 테마 + 라우터 연결
import 'package:flutter/material.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repo.instance.init();
  runApp(const ReViewApp());
}

class ReViewApp extends StatelessWidget {
  const ReViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:View',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: Routes.home, // 온보딩 전이라면 Routes.onboarding 사용
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}