import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/color_scheme.dart';
import 'features/home/home_screen.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); // ⬅️ 스플래시 유지
  runApp(const ReView());
}

class ReView extends StatefulWidget {
  const ReView({super.key});
  @override
  State<ReView> createState() => _ReViewState();
}

class _ReViewState extends State<ReView> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // TODO: 여기서 필요한 초기화 비동기 작업들을 처리
    // 예: await Future.wait([restoreAuth(), loadConfig(), warmUpDb()]);
    await Future.delayed(const Duration(seconds: 2)); // 데모용

    if (!mounted) return;
    FlutterNativeSplash.remove(); // 스플래시 해제
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re:View',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        extensions: [AppHighlights.fromScheme(lightScheme)],
      ),
      home: const HomeScreen(),
    );
  }
}
