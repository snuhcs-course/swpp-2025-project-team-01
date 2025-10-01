import 'package:flutter/material.dart';

/// Figma: 2-4-1. Display Mode
/// - 라디오(라이트/다크/시스템) + 옆에 미니 프리뷰 목업(회색 박스) 느낌
class DisplayModeScreen extends StatefulWidget {
  const DisplayModeScreen({super.key});
  @override
  State<DisplayModeScreen> createState() => _DisplayModeScreenState();
}

class _DisplayModeScreenState extends State<DisplayModeScreen> {
  String _mode = 'System'; // System | Light | Dark

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('디스플레이 모드')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _rowOption('라이트 모드', 'Light'),
          _rowOption('다크 모드', 'Dark'),
          _rowOption('시스템 설정', 'System'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // 미니 프리뷰(단순 자리 표시자)
          Row(
            children: [
              _previewBox(label: '라이트'),
              const SizedBox(width: 12),
              _previewBox(dark: true, label: '다크'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _rowOption(String label, String value) {
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _mode,
        onChanged: (v) => setState(() => _mode = v!),
      ),
      title: Text(label),
      onTap: () => setState(() => _mode = value),
    );
  }

  Widget _previewBox({bool dark = false, String? label}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2B2B2B) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(label ?? '', style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
        ),
      ),
    );
  }
}