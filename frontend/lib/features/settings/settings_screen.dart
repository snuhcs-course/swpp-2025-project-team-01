import 'package:flutter/material.dart';
import '../../app_router.dart';

/// Figma: 2-4. Settings (섹션 없이 심플한 목록)
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