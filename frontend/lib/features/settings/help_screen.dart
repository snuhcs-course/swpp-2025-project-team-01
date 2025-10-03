import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

/// 도움말 화면 - 기본 안내 텍스트 제공
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Help')), // Keep as Help in both languages
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '문제가 생겼나요?\n\n'
          '1) 네트워크 연결을 확인하세요.\n'
          '2) 앱을 최신 버전으로 업데이트하세요.\n'
          '3) 계속될 경우, 문의하기에서 로그를 첨부해 주세요.\n\n'
          '튜토리얼 창 내용 추가 예정',
          style: TextStyle(height: 1.5),
        ),
      ),
    );
  }
}