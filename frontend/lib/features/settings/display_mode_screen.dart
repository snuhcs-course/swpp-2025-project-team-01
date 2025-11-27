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
/// - 본문: 프리뷰 이미지와 라디오 버튼 3개 (각 모드 선택)
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

  static const double _lightPreviewAspectRatio = 1080 / 1212;

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

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    // 레이아웃 계산 변수
    final double padding = 16.0;
    final double spacing = 18.0; // 아이템 간 가로 간격

    // 최대 너비 제한
    final double contentWidth = screenWidth > 1000 ? 1000 : screenWidth;
    final double availableWidth = contentWidth - (padding * 2);

    // 모바일에서 최대 폭 제한
    double calculatedMobileWidth = (availableWidth - spacing) / 2;
    if (calculatedMobileWidth > 160.0) {
      calculatedMobileWidth = 160.0;
    }

    final double itemWidth = isTablet
        ? (availableWidth - (spacing * 2)) / 3
        : calculatedMobileWidth;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.displayMode)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Center(
              // 최대 너비를 제한하여 이미지가 너무 길어지는 것 방지 (태블릿 조정)
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: RadioGroup<String>(
                  groupValue: _mode,
                  onChanged: (v) => _changeMode(v!),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing,
                    runSpacing: 24.0,
                    children: [
                      _buildDisplayOption(
                        label: l10n.lightMode,
                        value: 'light',
                        assetPath: 'assets/images/light_mode.png',
                        width: itemWidth,
                      ),
                      _buildDisplayOption(
                        label: l10n.darkMode,
                        value: 'dark',
                        assetPath: 'assets/images/dark_mode.png',
                        width: itemWidth,
                      ),
                      _buildDisplayOption(
                        label: l10n.systemSettings,
                        value: 'system',
                        assetPath: _isSystemDarkMode()
                            ? 'assets/images/dark_mode.png'
                            : 'assets/images/light_mode.png',
                        width: itemWidth,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 프리뷰 이미지와 라디오 버튼을 하나로 묶은 위젯
  Widget _buildDisplayOption({
    required String label,
    required String value,
    required String assetPath,
    required double width,
  }) {
    final isSelected = _mode == value;
    final isAppInDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor = isAppInDarkMode
        ? Colors.lightBlueAccent
        : Theme.of(context).primaryColor;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프리뷰 이미지
          GestureDetector(
            onTap: () => _changeMode(value),
            child: AspectRatio(
              aspectRatio: _lightPreviewAspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? selectedColor : Colors.black12,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.5),
                  child: Image.asset(assetPath, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 라디오 버튼 + 텍스트 정렬
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: value,
                activeColor: selectedColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? selectedColor : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 텍스트를 중앙에 두기 위한 여백
              IgnorePointer(
                child: Opacity(
                  opacity: 0.0,
                  child: Radio<String>(
                    value: '',
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
