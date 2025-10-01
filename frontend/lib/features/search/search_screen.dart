// 검색 화면: 입력 → 결과(홈 카드와 동일 패턴으로 확장 가능)
import 'package:flutter/material.dart';
import '../../data/repository.dart';
import '../../app_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _c, decoration: const InputDecoration(hintText: '검색어 입력'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => setState(() {}), child: const Text('검색')),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: Repo.instance
                  .getSubjects()
                  .where((s) => s.title.contains(_c.text))
                  .map((s) => ListTile(
                        title: Text(s.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, Routes.home),
                      ))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }
}