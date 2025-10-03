import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Figma: 2-4-3. Accessibility
/// - 예시: 고대비/모션 줄이기/자막 강조 등 토글 + 가이드 텍스트
/// SharedPreference를 통해 각 요소 정보 저장
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});
  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _emphasizeCaptions = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highContrast = prefs.getBool('accessibility_high_contrast') ?? false;
      _reduceMotion = prefs.getBool('accessibility_reduce_motion') ?? false;
      _emphasizeCaptions = prefs.getBool('accessibility_emphasize_captions') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_high_contrast', value);
    setState(() => _highContrast = value);
  }

  Future<void> _saveReduceMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_reduce_motion', value);
    setState(() => _reduceMotion = value);
  }

  Future<void> _saveEmphasizeCaptions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_emphasize_captions', value);
    setState(() => _emphasizeCaptions = value);
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
      appBar: AppBar(title: const Text('접근성')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ListView(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: const Text('고대비'),
              subtitle: const Text('텍스트와 UI 요소의 대비를 높입니다.'),
              value: _highContrast,
              onChanged: _saveHighContrast,
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: const Text('모션 줄이기'),
              subtitle: const Text('애니메이션 효과를 최소화합니다.'),
              value: _reduceMotion,
              onChanged: _saveReduceMotion,
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: const Text('자막 강조'),
              subtitle: const Text('플레이어 자막을 굵게/큰 크기로 표시합니다.'),
              value: _emphasizeCaptions,
              onChanged: _saveEmphasizeCaptions,
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('설정은 재생 화면에 즉시 적용됩니다.', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}