import 'package:flutter/material.dart';

/// 접근성 설정 화면 - 고대비, 모션 줄이기, 자막 강조 등
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});
  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _emphasizeCaptions = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('접근성')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('고대비'),
            subtitle: const Text('텍스트와 UI 요소의 대비를 높입니다.'),
            value: _highContrast,
            onChanged: (v) => setState(() => _highContrast = v),
          ),
          SwitchListTile(
            title: const Text('모션 줄이기'),
            subtitle: const Text('애니메이션 효과를 최소화합니다.'),
            value: _reduceMotion,
            onChanged: (v) => setState(() => _reduceMotion = v),
          ),
          SwitchListTile(
            title: const Text('자막 강조'),
            subtitle: const Text('플레이어 자막을 굵게/큰 크기로 표시합니다.'),
            value: _emphasizeCaptions,
            onChanged: (v) => setState(() => _emphasizeCaptions = v),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('설정은 재생 화면에 즉시 적용됩니다.', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}