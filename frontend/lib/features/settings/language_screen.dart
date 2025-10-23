import 'package:flutter/material.dart';
import 'package:re_view/data/hive_manager.dart';

/// 언어 설정 화면 (Figma 2-4-4. Language)
///
/// 이 화면은 앱의 언어를 한국어 또는 영어로 설정할 수 있습니다.
///
/// 지원 언어:
/// - 한국어 (Korean)
/// - English
///
/// 언어 변경은 즉시 적용되며 LanguageService를 통해 관리됩니다.
///
/// UI 구조:
/// - 상단: 앱바 (제목: "언어 / Language")
/// - 본문: 라디오 버튼 2개 (한국어, English)
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.hiveManager});

  final HiveManager? hiveManager;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // 언어 서비스 인스턴스
  late final HiveManager _manager;

  @override
  void initState() {
    super.initState();
    // 언어 변경 리스너 등록 (언어 변경 시 자동 UI 업데이트)
    _manager = widget.hiveManager ?? HiveManager.instance;
    _manager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 리스너 제거
    _manager.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// 언어 변경 시 호출되는 콜백
  ///
  /// UI를 다시 빌드하여 변경된 언어를 반영합니다.
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 선택한 언어 저장
  ///
  /// [value]: 언어 코드 ('ko' 또는 'en')
  Future<void> _saveLanguage(String value) async {
    await _manager.updateLanguage(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = _manager.settings.language;

    return Scaffold(
      // 상단 앱바 (한영 모두 표시)
      appBar: AppBar(title: const Text('언어 / Language')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),

      // 언어 선택 라디오 버튼 목록
      body: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            // 1. 한국어 선택
            // 앱의 모든 텍스트를 한국어로 표시
            RadioGroup<String>(
              groupValue: currentLang,
              onChanged: (v) => _saveLanguage(v!),
              child: Column(
                children: <Widget>[
                  RadioListTile<String>(
                    value: 'ko',
                    title: const Text(
                      '한국어 / Korean',
                      style: TextStyle(fontSize: 18),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                ],
              ),
            ),

            // 2. English 선택
            // 앱의 모든 텍스트를 영어로 표시
            RadioGroup<String>(
              groupValue: currentLang,
              onChanged: (v) => _saveLanguage(v!),
              child: Column(
                children: <Widget>[
                  RadioListTile<String>(
                    value: 'en',
                    title: const Text(
                      'English',
                      style: TextStyle(fontSize: 18),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
