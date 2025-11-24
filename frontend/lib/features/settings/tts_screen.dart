import 'package:flutter/material.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// TTS(Text-to-Speech) 설정 화면 (Figma 2-4-2. TTS)
///
/// 이 화면은 텍스트 음성 변환 기능의 다양한 설정을 제공합니다.
///
/// 제공 옵션:
/// - 음성 성별: 현재는 여성 음성만 지원 (선택 시 "Hello, World!" 예시 음성 재생)
/// - TTS 음성 속도: 빠르게/보통/느리게 (선택 시 "Hello, World!" 예시 음성 재생)
///
/// UI 구조:
/// - 상단: 앱바 (제목: "TTS", 닫기 버튼)
/// - 본문: 성별 선택, TTS 음성 속도 선택
///
/// SharedPreferences를 통해 설정을 저장 및 관리합니다.
class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key, this.hiveManager});

  final HiveManager? hiveManager;

  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> {
  late final HiveManager _hiveManager;

  // TTS 설정 상태
  String _gender = '여성'; // 기본값은 여성

  @override
  void initState() {
    super.initState();
    _hiveManager = widget.hiveManager ?? HiveManager.instance;
    _loadSettings();
  }

  /// HiveManager에서 저장된 TTS 설정 불러오기
  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        final ttsGender = _hiveManager.settings.ttsGender;
        _gender = ttsGender == '남성' ? '여성' : ttsGender;
      });
    }
  }

  /// 음성 성별 저장 및 예시 음성 재생
  Future<void> _saveGender(String value) async {
    await _hiveManager.updateTts(gender: value);
    setState(() => _gender = value);
    _playPreviewTTS();
  }

  /// 예시 TTS 음성 재생
  ///
  /// 현재 설정된 성별과 속도로 "Hello, World!" 음성을 재생합니다.
  /// TODO: 실제 TTS 엔진 연동 필요
  void _playPreviewTTS() {
    // TODO: TTS 엔진 연동
    // 예시 코드:
    // final ttsEngine = TTSEngine.instance;
    // ttsEngine.speak(
    //   text: "Hello, World!",
    //   gender: _gender,
    //   speed: _speedToRate(_speed),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tts)),
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              l10n.isKorean ? 'TTS 음성 성별' : 'TTS Voice Gender',
            ),
            const SizedBox(height: 12),
            _buildGenderButtons(l10n.isKorean),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Text(title, style: textStyle);
  }

  Widget _buildGenderButtons(bool isKorean) {
    return Row(
      children: [
        Expanded(
          child: _genderButton(
            context,
            isKorean ? '남성' : 'Male',
            _gender == '남성',
            true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _genderButton(
            context,
            isKorean ? '여성' : 'Female',
            _gender == '여성',
            true,
          ),
        ),
      ],
    );
  }

  Widget _genderButton(
    BuildContext context,
    String label,
    bool isSelected,
    bool isEnabled,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final backgroundColor = isDark
        ? (isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest)
        : (isSelected
              ? Colors.white
              : isEnabled
              ? const Color(0xFFE0E0E0)
              : const Color(0xFFE0E0E0).withValues(alpha: 0.6));
    final borderColor = isDark
        ? (isSelected ? colorScheme.primary : Colors.transparent)
        : (isSelected ? const Color(0xFF424242) : Colors.transparent);
    final textColor = isDark
        ? (isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant)
        : (isSelected
              ? Colors.black
              : isEnabled
              ? const Color(0xFF666666)
              : const Color(0xFF999999));

    final actualValue = label == 'Male'
        ? '남성'
        : label == 'Female'
        ? '여성'
        : label;

    return GestureDetector(
      onTap: isEnabled ? () => _saveGender(actualValue) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isDark
              ? Border.all(color: borderColor, width: isSelected ? 2 : 1)
              : (isSelected ? Border.all(color: borderColor, width: 2) : null),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
