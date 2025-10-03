// 홈 메인: 상단 필터/즐겨찾기 pill + 태그칩 + 과목 패널 리스트
import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'home_widgets.dart';

/// 메인 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool favoritesOnly = false;
  bool showTagFilter = false;
  final Set<String> selectedTagIds = {};

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final tags = repo.getTags();
    final subjects = repo.getSubjects(
      favoritesOnly: favoritesOnly,
      filterTagIds: selectedTagIds.toList(),
    );

    return Scaffold(
      appBar: AppBar(
        // Figma: 좌 햄버거, 중앙 타이틀, 우 검색
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Re:View'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, Routes.search),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text('메뉴', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(title: const Text('수업 추가'), onTap: () => Navigator.pushNamed(context, Routes.lectureForm)),
          ListTile(title: const Text('과목 수정'), onTap: () => Navigator.pushNamed(context, Routes.subjectsEdit)),
          ListTile(title: const Text('태그 수정'), onTap: () => Navigator.pushNamed(context, Routes.tagsEdit)),
          const Divider(),
          ListTile(title: const Text('설정'), onTap: () => Navigator.pushNamed(context, Routes.settings)),
        ]),
      ),
      body: CustomScrollView(
        slivers: [
          // 상단 pill 두 개
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(children: [
                FilterPill(
                  icon: Icons.tune,
                  label: '필터',
                  active: showTagFilter,
                  onTap: () => setState(() {
                    showTagFilter = !showTagFilter;
                    // 필터 버튼을 비활성화할 때 모든 태그 선택 해제
                    if (!showTagFilter) {
                      selectedTagIds.clear();
                    }
                  }),
                ),
                const SizedBox(width: 12),
                FavoritePill(
                  active: favoritesOnly,
                  onTap: () => setState(() => favoritesOnly = !favoritesOnly),
                ),
              ]),
            ),
          ),
          // 태그 칩 그리드 (필터 버튼 클릭 시만 표시)
          if (showTagFilter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TagChips(
                  tags: tags,
                  selected: selectedTagIds,
                  onToggle: (id) => setState(() {
                    if (!selectedTagIds.add(id)) {
                      selectedTagIds.remove(id);
                    }
                  }),
                ),
              ),
            ),
          // 과목 패널 리스트
          SliverList.builder(
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final s = subjects[i];
              final subjectTags = s.tagIds
                  .map((tid) => tags.cast<Tag?>().firstWhere((t) => t?.id == tid, orElse: () => null))
                  .whereType<Tag>()
                  .toList();
              final lectures = repo.lecturesBySubject(s.id);
              return Padding(
                padding: EdgeInsets.fromLTRB(16, i == 0 ? 6 : 12, 16, 0),
                child: SubjectPanel(
                  subject: s,
                  tags: subjectTags,
                  lectures: lectures,
                  onToggleFavorite: () async {
                    await Repo.instance.toggleSubjectFavorite(s.id);
                    setState(() {});
                  },
                  onOpenLecture: (Lecture lec) {
                    Navigator.pushNamed(context, Routes.player, arguments: {'lectureId': lec.id});
                  },
                  onLectureUpdated: () {
                    setState(() {});
                  },
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}