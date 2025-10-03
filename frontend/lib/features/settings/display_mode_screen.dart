import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Figma: 2-4-1. Display Mode
/// - 라디오(라이트/다크/시스템) + 옆에 미니 프리뷰 목업(회색 박스) 느낌
/// SharedPreference를 통한 정보 관리
class DisplayModeScreen extends StatefulWidget {
  const DisplayModeScreen({super.key});
  @override
  State<DisplayModeScreen> createState() => _DisplayModeScreenState();
}

class _DisplayModeScreenState extends State<DisplayModeScreen> {
  static const String _key = 'display_mode';
  String _mode = 'system'; // system | light | dark

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  /// 저장된 디스플레이 모드 불러오기
  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mode = prefs.getString(_key) ?? 'system';
    });
  }

  /// 디스플레이 모드 변경 및 저장
  Future<void> _changeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
    setState(() {
      _mode = mode;
    });
  }

  /// 시스템의 현재 라이트/다크 모드 확인
  bool _isSystemDarkMode() {
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('디스플레이 모드')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _rowOption('라이트 모드', 'light'),
          _rowOption('다크 모드', 'dark'),
          _rowOption('시스템 설정', 'system'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // 미니 프리뷰(단순 자리 표시자)
          Row(
            children: [
              _previewBox(dark: false, label: '라이트 모드'),
              const SizedBox(width: 8),
              _previewBox(dark: true, label: '다크 모드'),
              const SizedBox(width: 8),
              _previewBox(dark: _isSystemDarkMode(), label: '시스템 설정'),
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
        onChanged: (v) => _changeMode(v!),
      ),
      title: Text(label),
      onTap: () => _changeMode(value),
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