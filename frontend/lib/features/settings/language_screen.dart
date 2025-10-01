import 'package:flutter/material.dart';

/// Figma: 2-4-4. Language (라디오 2개)
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _lang = 'ko';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('언어 / Language')),
      body: Column(
        children: [
          RadioListTile(
            value: 'ko',
            groupValue: _lang,
            title: const Text('한국어 / Korean'),
            onChanged: (v) => setState(() => _lang = v as String),
          ),
          RadioListTile(
            value: 'en',
            groupValue: _lang,
            title: const Text('English'),
            onChanged: (v) => setState(() => _lang = v as String),
          ),
        ],
      ),
    );
  }
}