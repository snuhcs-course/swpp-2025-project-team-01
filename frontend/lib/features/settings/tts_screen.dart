import 'package:flutter/material.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// TTS(Text-to-Speech) 설정 화면 (Figma 2-4-2. TTS)
///
/// 이 화면은 텍스트 음성 변환 기능의 다양한 설정을 제공합니다.
///
/// 제공 옵션:
/// - 음성 성별: 남성/여성 (선택 시 "Hello, World!" 예시 음성 재생)
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
  String _gender = '남성'; // 음성 성별

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
        _gender = _hiveManager.settings.ttsGender;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKorean = AppLocalizations.of(context).isKorean;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(isKorean ? 'TTS 음성 성별' : 'TTS Voice Gender'),
            const SizedBox(height: 12),
            _buildGenderButtons(isKorean),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
    );
  }

  Widget _buildGenderButtons(bool isKorean) {
    return Row(
      children: [
        Expanded(
          child: _genderButton(isKorean ? '남성' : 'Male', _gender == '남성'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _genderButton(isKorean ? '여성' : 'Female', _gender == '여성'),
        ),
      ],
    );
  }

  Widget _genderButton(String label, bool isSelected) {
    final actualValue = label == 'Male'
        ? '남성'
        : label == 'Female'
        ? '여성'
        : label;

    return GestureDetector(
      onTap: () => _saveGender(actualValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF424242), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.black : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
