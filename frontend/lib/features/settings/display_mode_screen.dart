import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/theme_manager.dart';

/// 디스플레이 모드 설정 화면 (Figma 2-4-1. Display Mode)
///
/// 이 화면은 앱의 테마를 라이트 모드, 다크 모드, 시스템 설정 중 선택할 수 있습니다.
///
/// 제공 옵션:
/// - 라이트 모드: 밝은 테마
/// - 다크 모드: 어두운 테마
/// - 시스템 설정: OS 설정 따름
///
/// UI 구조:
/// - 상단: 앱바 (제목: "Display Mode")
/// - 본문: 라디오 버튼 3개 (각 모드 선택)
/// - 하단: 미니 프리뷰 박스 3개 (각 모드의 시각적 미리보기)
///
/// ThemeManager를 통해 설정을 저장 및 관리합니다.
class DisplayModeScreen extends StatefulWidget {
  const DisplayModeScreen({super.key});

  @override
  State<DisplayModeScreen> createState() => _DisplayModeScreenState();
}

class _DisplayModeScreenState extends State<DisplayModeScreen> {
  // 현재 선택된 모드 (system | light | dark)
  String _mode = 'system';

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  /// ThemeManager에서 저장된 디스플레이 모드 불러오기
  void _loadMode() {
    final themeMode = ThemeManager.instance.themeMode;
    setState(() {
      _mode = _themeModeToString(themeMode);
    });
  }

  /// ThemeMode를 문자열로 변환
  ///
  /// [mode]: Flutter의 ThemeMode 열거형
  /// 반환값: 'light', 'dark', 또는 'system'
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
  ///
  /// ThemeManager를 통해 선택한 모드를 저장하고 즉시 적용합니다.
  ///
  /// [mode]: 'light', 'dark', 또는 'system'
  Future<void> _changeMode(String mode) async {
    await ThemeManager.instance.setThemeMode(mode);
    setState(() {
      _mode = mode;
    });
  }

  /// 시스템의 현재 다크 모드 상태 확인
  ///
  /// OS 레벨에서 다크 모드가 활성화되어 있는지 확인합니다.
  /// 시스템 설정 프리뷰에 사용됩니다.
  ///
  /// 반환값: true(다크 모드), false(라이트 모드)
  bool _isSystemDarkMode() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
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
        child: Column(
          children: [
            // 디스플레이 모드 선택 라디오 버튼
            _rowOption(l10n.lightMode, 'light'),
            _rowOption(l10n.darkMode, 'dark'),
            _rowOption(l10n.systemSettings, 'system'),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // 미니 프리뷰: 각 모드의 시각적 표현
            Row(
              children: [
                _previewBox(dark: false, label: l10n.lightMode),
                const SizedBox(width: 8),
                _previewBox(dark: true, label: l10n.darkMode),
                const SizedBox(width: 8),
                _previewBox(
                  dark: _isSystemDarkMode(),
                  label: l10n.systemSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 라디오 버튼 옵션 행 위젯
  ///
  /// 각 디스플레이 모드 선택 옵션을 표시합니다.
  ///
  /// [label]: 표시할 레이블 텍스트
  /// [value]: 이 옵션의 값 ('light', 'dark', 'system')
  Widget _rowOption(String label, String value) {
    return ListTile(
      leading: RadioGroup<String>(
        groupValue: _mode,
        onChanged: (v) => _changeMode(v!),
        child: Column(children: <Widget>[Radio<String>(value: value)]),
      ),
      title: Text(label),
      onTap: () => _changeMode(value),
    );
  }

  /// 미니 프리뷰 박스 위젯
  ///
  /// 각 디스플레이 모드의 시각적 미리보기를 제공합니다.
  ///
  /// [dark]: true면 다크 모드 스타일, false면 라이트 모드 스타일
  /// [label]: 프리뷰 박스 내부에 표시할 레이블
  Widget _previewBox({bool dark = false, String? label}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 9 / 16, // 모바일 화면 비율
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2B2B2B) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(
            label ?? '',
            style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
