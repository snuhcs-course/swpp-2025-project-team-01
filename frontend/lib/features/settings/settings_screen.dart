import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../core/localization/app_localizations.dart';

/// 설정 메인 화면 - 각종 설정 메뉴로 이동
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ListView(
          children: [
            _navTile(context, l10n.displayMode, Routes.settingsDisplay),
            _navTile(context, 'TTS', Routes.settingsTts),
            _navTile(context, l10n.accessibility, Routes.settingsAccessibility),
            _navTile(context, l10n.language, Routes.settingsLanguage),
            _navTile(context, 'Help', Routes.settingsHelp),
          ],
        ),
      ),
    );
  }

  ListTile _navTile(BuildContext ctx, String title, String route) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 16),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(ctx, route),
    );
  }
}