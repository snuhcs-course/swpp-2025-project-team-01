import 'package:flutter/material.dart';
import '../../core/language_service.dart';

/// Figma: 2-4-4. Language (라디오 2개)
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final _service = LanguageService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveLanguage(String value) async {
    await _service.setLanguage(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = _service.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('언어 / Language')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            RadioListTile<String>(
              value: 'ko',
              groupValue: currentLang,
              title: const Text(
                '한국어 / Korean',
                style: TextStyle(fontSize: 18),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onChanged: (v) => _saveLanguage(v!),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: currentLang,
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