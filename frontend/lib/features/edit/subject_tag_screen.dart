// 과목/태그 관리 통합 (간단 리스트 + 삭제 버튼 예시)
import 'package:flutter/material.dart';
import '../../data/repository.dart';

class SubjectTagScreen extends StatelessWidget {
  const SubjectTagScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final subjects = repo.getSubjects();
    final tags = repo.getTags();

    return Scaffold(
      appBar: AppBar(title: const Text('과목/태그 관리')),
      body: ListView(
        children: [
          const ListTile(title: Text('과목')),
          ...subjects.map((s) => ListTile(
                title: Text(s.title),
                leading: const Icon(Icons.drag_indicator),
                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
              )),
          const Divider(),
          const ListTile(title: Text('태그')),
          ...tags.map((t) => ListTile(
                title: Text('#${t.name}'),
                leading: CircleAvatar(backgroundColor: Color(t.color), radius: 10),
                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
              )),
        ],
      ),
    );
  }
}