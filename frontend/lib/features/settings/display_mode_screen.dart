import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/theme_manager.dart';

/// Figma: 2-4-1. Display Mode
/// - 라디오(라이트/다크/시스템) + 옆에 미니 프리뷰 목업(회색 박스) 느낌
/// ThemeManager를 통한 정보 관리
class DisplayModeScreen extends StatefulWidget {
  const DisplayModeScreen({super.key});
  @override
  State<DisplayModeScreen> createState() => _DisplayModeScreenState();
}

class _DisplayModeScreenState extends State<DisplayModeScreen> {
  String _mode = 'system'; // system | light | dark

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  /// 저장된 디스플레이 모드 불러오기
  void _loadMode() {
    final themeMode = ThemeManager.instance.themeMode;
    setState(() {
      _mode = _themeModeToString(themeMode);
    });
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  /// 디스플레이 모드 변경 및 저장
  Future<void> _changeMode(String mode) async {
    await ThemeManager.instance.setThemeMode(mode);
    setState(() {
      _mode = mode;
    });
  }

  /// 시스템의 현재 라이트/다크 모드 확인
  bool _isSystemDarkMode() {
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.displayMode)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _rowOption(l10n.lightMode, 'light'),
          _rowOption(l10n.darkMode, 'dark'),
          _rowOption(l10n.systemSettings, 'system'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // 미니 프리뷰(단순 자리 표시자)
          Row(
            children: [
              _previewBox(dark: false, label: l10n.lightMode),
              const SizedBox(width: 8),
              _previewBox(dark: true, label: l10n.darkMode),
              const SizedBox(width: 8),
              _previewBox(dark: _isSystemDarkMode(), label: l10n.systemSettings),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _rowOption(String label, String value) {
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _mode,
        onChanged: (v) => _changeMode(v!),
      ),
      title: Text(label),
      onTap: () => _changeMode(value),
    );
  }

  Widget _previewBox({bool dark = false, String? label}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2B2B2B) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(label ?? '', style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
        ),
      ),
    );
  }
}