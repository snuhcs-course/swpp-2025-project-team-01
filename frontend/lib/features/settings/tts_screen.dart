import 'package:flutter/material.dart';

/// Figma: 2-4-2. TTS
/// - TTS ON/OFF 토글
/// - 목소리(라디오 또는 드롭다운), 속도(슬라이더) 0.8x~1.6x
class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key});
  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> {
  bool _ttsOn = true;
  String _voice = '기본';
  double _speed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('TTS 사용'),
            value: _ttsOn,
            onChanged: (v) => setState(() => _ttsOn = v),
          ),
          ListTile(
            title: const Text('목소리'),
            trailing: DropdownButton<String>(
              value: _voice,
              items: const [
                DropdownMenuItem(value: '기본', child: Text('기본')),
                DropdownMenuItem(value: '여성 A', child: Text('여성 A')),
                DropdownMenuItem(value: '남성 B', child: Text('남성 B')),
              ],
              onChanged: (v) => setState(() => _voice = v ?? _voice),
            ),
          ),
          const SizedBox(height: 12),
          const Text('속도'),
          Row(
            children: [
              const Text('0.8x'),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _speed = v),
                ),
              ),
              const Text('1.6x'),
            ],
          ),
        ],
      ),
    );
  }
}