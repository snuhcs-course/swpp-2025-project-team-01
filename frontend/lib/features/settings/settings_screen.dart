import 'package:flutter/material.dart';
import '../../app_router.dart';

/// 설정 메인 화면 - 각종 설정 메뉴로 이동
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _navTile(context, '디스플레이 모드', Routes.settingsDisplay),
          _navTile(context, 'TTS', Routes.settingsTts),
          _navTile(context, '접근성', Routes.settingsAccessibility),
          _navTile(context, '언어 / Language', Routes.settingsLanguage),
          _navTile(context, 'Help', Routes.settingsHelp),
        ],
      ),
    );
  }

  ListTile _navTile(BuildContext ctx, String title, String route) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(ctx, route),
    );
  }
}