// 수업 추가 폼 (파일 선택 로직은 추후 연결)
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/widgets.dart';

/// 수업 추가 화면
class LectureFormScreen extends StatelessWidget {
  const LectureFormScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addLecture)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(decoration: InputDecoration(labelText: l10n.isKorean ? '과목 선택(임시 입력)' : 'Select Subject (temp)')),
          const SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: l10n.isKorean ? '주차 (예: Week 1-1)' : 'Week (e.g. Week 1-1)')),
          const SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: l10n.lectureTitle)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf), label: Text(l10n.isKorean ? '슬라이드 PDF' : 'Slides PDF'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.audiotrack), label: Text(l10n.isKorean ? '녹음 m4a' : 'Audio m4a'))),
          ]),
          const Spacer(),
          PrimaryButton(label: l10n.isKorean ? '생성 완료' : 'Create', onPressed: () => Navigator.pop(context)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ]),
      ),
    );
  }
}