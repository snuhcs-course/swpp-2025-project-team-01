import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Figma: 2-4-2. TTS
/// - TTS 음성 성별 (남성/여성)
/// - TTS 악센트 (Am/Br)
/// - 재생 속도 (슬라이더) x0.5 ~ x2.0
/// SharedPreference를 통한 정보 저장
class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key});
  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> {
  String _gender = '남성';
  String _accent = 'Am';
  double _speed = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gender = prefs.getString('tts_gender') ?? '남성';
      _accent = prefs.getString('tts_accent') ?? 'Am';
      _speed = prefs.getDouble('tts_speed') ?? 1.0;
      _isLoading = false;
    });
  }

  Future<void> _saveGender(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_gender', value);
    setState(() => _gender = value);
  }

  Future<void> _saveAccent(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_accent', value);
    setState(() => _accent = value);
  }

  Future<void> _saveSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speed', value);
    setState(() => _speed = value);
  }

  // 슬라이더 값(0.0~1.0)을 실제 속도(0.5~2.0)로 변환
  // 0.0 -> 0.5x, 0.5 -> 1.0x, 1.0 -> 2.0x
  double _sliderToSpeed(double slider) {
    // 0.5 근처(±0.05)는 1.0x로 스냅
    if ((slider - 0.5).abs() < 0.05) {
      return 1.0;
    }

    if (slider < 0.5) {
      // 왼쪽 절반: 0.5x ~ 1.0x (선형)
      return 0.5 + slider;
    } else {
      // 오른쪽 절반: 1.0x ~ 2.0x (선형)
      return 1.0 + (slider - 0.5) * 2;
    }
  }

  // 실제 속도(0.5~2.0)를 슬라이더 값(0.0~1.0)으로 변환
  double _speedToSlider(double speed) {
    if (speed < 1.0) {
      // 0.5x ~ 1.0x -> 0.0 ~ 0.5
      return speed - 0.5;
    } else if (speed == 1.0) {
      return 0.5;
    } else {
      // 1.0x ~ 2.0x -> 0.5 ~ 1.0
      return 0.5 + (speed - 1.0) / 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            // TTS 음성 성별
            const Text(
              'TTS 음성 성별',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _genderButton('남성', _gender == '남성'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _genderButton('여성', _gender == '여성'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // TTS 악센트
            const Text(
              'TTS 악센트',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _accentButton('Am', _accent == 'Am'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _accentButton('Br', _accent == 'Br'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 재생 속도
            const Text(
              '재생 속도',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),

            // 슬라이더와 속도 표시
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 중앙 마커 (1.0x 위치)
                      Positioned(
                        left: 0,
                        right: 0,
                        child: FractionallySizedBox(
                          widthFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 2,
                                height: 20,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 슬라이더
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF424242),
                          inactiveTrackColor: const Color(0xFFE0E0E0),
                          thumbColor: const Color(0xFF424242),
                          overlayColor: const Color(0xFF424242).withValues(alpha: 0.1),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _speedToSlider(_speed),
                          min: 0.0,
                          max: 1.0,
                          onChanged: (sliderValue) {
                            final speed = _sliderToSpeed(sliderValue);
                            _saveSpeed(speed);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: Text(
                    'x${_speed.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // 슬라이더 하단 라벨
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 72, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'x${0.5.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                  Text(
                    'x${2.0.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _saveGender(label),
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

  Widget _accentButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _saveAccent(label),
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