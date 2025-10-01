import 'package:flutter/material.dart';

/// Figma: 2-4-5. Help (간단 안내 텍스트)
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '문제가 생겼나요?\n\n'
          '1) 네트워크 연결을 확인하세요.\n'
          '2) 앱을 최신 버전으로 업데이트하세요.\n'
          '3) 계속될 경우, 문의하기에서 로그를 첨부해 주세요.',
          style: TextStyle(height: 1.5),
        ),
      ),
    );
  }
}