// 메인 리스트 + 상단 액션(필터/즐겨찾기/검색) + 드로어

import 'package:flutter/material.dart';
import '../../data/repository.dart';
import '../../data/models.dart';
import '../../app_router.dart';
import 'home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool favoritesOnly = false;
  final Set<String> selectedTagIds = {};

  @override
  Widget build(BuildContext context) {
    final tags = Repo.instance.getTags();
    final subjects = Repo.instance.getSubjects(
      favoritesOnly: favoritesOnly,
      filterTagIds: selectedTagIds.toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Re:View'),
        //leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, Routes.search)),
        ],
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(child: Text('메뉴')),
          ListTile(
            title: const Text('수업 추가'),
            onTap: () => Navigator.pushNamed(context, Routes.lectureForm),
          ),
          ListTile(
            title: const Text('과목 수정'),
            onTap: () => Navigator.pushNamed(context, Routes.subjectsEdit),
          ),
          ListTile(
            title: const Text('태그 수정'),
            onTap: () => Navigator.pushNamed(context, Routes.tagsEdit),
          ),
          const Divider(),
          ListTile(
            title: const Text('설정'),
            onTap: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ]),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FilterBar(
              tags: tags,
              selected: selectedTagIds,
              favoritesOnly: favoritesOnly,
              onToggleFavOnly: (v) => setState(() => favoritesOnly = v),
              onToggleTag: (id) => setState(() {
                if (!selectedTagIds.add(id)) selectedTagIds.remove(id);
              }),
            ),
          ),
          SliverList.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final s = subjects[index];
              return SubjectPanel(
                subject: s,
                lectures: Repo.instance.lecturesBySubject(s.id),
                onToggleFavorite: () {
                  setState(() => Repo.instance.toggleSubjectFavorite(s.id));
                },
                onOpenLecture: (Lecture lec) {
                  Navigator.pushNamed(context, Routes.player, arguments: {'lectureId': lec.id});
                },
              );
            },
          ),
        ],
      ),
    );
  }
}