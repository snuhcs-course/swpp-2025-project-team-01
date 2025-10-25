import 'package:flutter/material.dart';

/// 도움말 화면 (Figma 2-4-5. Help)
///
/// 이 화면은 사용자가 앱 사용 중 문제를 해결할 수 있도록
/// 기본적인 안내 정보와 튜토리얼을 제공합니다.
///
/// 제공되는 정보:
/// - 네트워크 연결 확인 안내
/// - 앱 업데이트 안내
/// - 문의하기 안내 (로그 첨부)
/// - 튜토리얼 (향후 추가 예정)
///
/// UI 구조:
/// - 상단: 앱바 (제목: "Help")
/// - 본문: 도움말 텍스트
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 상단 앱바 (한영 모두 "Help"로 표시)
      appBar: AppBar(title: const Text('Help')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),

      // 도움말 텍스트
      // 사용자가 문제 해결을 위해 확인할 수 있는 기본 안내사항 제공
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
