// 수업 추가 폼 (파일 선택 로직은 추후 연결)
import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

/// 수업 추가 화면
class LectureFormScreen extends StatelessWidget {
  const LectureFormScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수업 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const TextField(decoration: InputDecoration(labelText: '과목 선택(임시 입력)')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: '주차 (예: Week 1-1)')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: '수업 제목')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf), label: const Text('슬라이드 PDF'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.audiotrack), label: const Text('녹음 m4a'))),
          ]),
          const Spacer(),
          PrimaryButton(label: '생성 완료', onPressed: () => Navigator.pop(context)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ]),
      ),
    );
  }
}