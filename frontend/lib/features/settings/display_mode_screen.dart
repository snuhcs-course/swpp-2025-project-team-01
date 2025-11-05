import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';

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
/// HiveManager를 통해 설정을 저장 및 관리합니다.
class DisplayModeScreen extends StatefulWidget {
  const DisplayModeScreen({super.key, this.hiveManager});

  final HiveManager? hiveManager;

  @override
  State<DisplayModeScreen> createState() => _DisplayModeScreenState();
}

class _DisplayModeScreenState extends State<DisplayModeScreen> {
  // 현재 선택된 모드 (system | light | dark)
  late final HiveManager _hive;
  String _mode = 'system';

  static const double _lightPreviewAspectRatio = 704 / 1494;

  @override
  void initState() {
    super.initState();
    _hive = widget.hiveManager ?? HiveManager.instance;
    _loadMode();
  }

  /// HiveManager에서 저장된 디스플레이 모드 불러오기
  void _loadMode() {
    setState(() {
      _mode = _hive.settings.theme;
    });
  }

  /// 디스플레이 모드 변경 및 저장
  ///
  /// HiveManager를 통해 선택한 모드를 저장하고 즉시 적용합니다.
  ///
  /// [mode]: 'light', 'dark', 또는 'system'
  Future<void> _changeMode(String mode) async {
    await _hive.updateTheme(mode);
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

      body: SingleChildScrollView(
        child: Padding(
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
                  _previewBox(
                    label: l10n.lightMode,
                    assetPath: 'assets/images/light_mode.png',
                  ),
                  const SizedBox(width: 8),
                  _previewBox(
                    label: l10n.darkMode,
                    assetPath: 'assets/images/dark_mode.png',
                  ),
                  const SizedBox(width: 8),
                  _previewBox(
                    label: l10n.systemSettings,
                    assetPath: _isSystemDarkMode()
                        ? 'assets/images/dark_mode.png'
                        : 'assets/images/light_mode.png',
                  ),
                ],
              ),
            ],
          ),
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
  /// 각 디스플레이 모드의 시각적 미리보기 이미지를 보여줍니다.
  ///
  /// [label]: 프리뷰 박스 하단에 표시할 레이블
  /// [assetPath]: 표시할 이미지 파일 경로
  Widget _previewBox({required String label, required String assetPath}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: _lightPreviewAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(assetPath, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
