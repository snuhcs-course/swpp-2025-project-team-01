import 'package:flutter/material.dart';
import '../../core/language_service.dart';

/// Figma: 2-4-4. Language (라디오 2개)
/// await LanguageService.getLanguage()를 통해 현재 설정 언어 확인
/// 모든 파일에서 텍스트 표현 부분은 언어 확인 후 적용 필요
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _lang = 'ko';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lang = await LanguageService.getLanguage();
    setState(() {
      _lang = lang;
      _isLoading = false;
    });
  }

  Future<void> _saveLanguage(String value) async {
    await LanguageService.setLanguage(value);
    setState(() => _lang = value);
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
      appBar: AppBar(title: const Text('언어 / Language')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            RadioListTile<String>(
              value: 'ko',
              groupValue: _lang,
              title: const Text(
                '한국어 / Korean',
                style: TextStyle(fontSize: 18),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onChanged: (v) => _saveLanguage(v!),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: _lang,
              title: const Text(
                'English',
                style: TextStyle(fontSize: 18),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onChanged: (v) => _saveLanguage(v!),
            ),
          ],
        ),
      ),
    );
  }
}