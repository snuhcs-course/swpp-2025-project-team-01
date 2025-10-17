// 홈 메인: 상단 필터/즐겨찾기 pill + 태그칩 + 과목 패널 리스트
import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/home/home_widgets.dart';

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

  late final HiveManager _manager = HiveManager.instance;

  @override
  void initState() {
    super.initState();
    // Repository 변경 리스너 등록
    _manager.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    _manager.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tags = _manager.getTags().map((ht) => ht.toTag()).toList();
    final subjects = _manager
        .getSubjects(
          favoritesOnly: favoritesOnly,
          filterTagIds: selectedTagIds.toList(),
        )
        .map((hs) => hs.toSubject())
        .toList();
    final reduceMotion = _manager.settings.accessibilityReduceMotion;

    return Scaffold(
      appBar: AppBar(
        // Figma: 좌 햄버거, 중앙 타이틀, 우 검색
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (reduceMotion) {
                // 모션 줄이기: 즉시 나타나는 다이얼로그
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (ctx) => Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Theme.of(context).canvasColor,
                      elevation: 16,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: double.infinity,
                        child: SafeArea(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              DrawerHeader(
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    l10n.menu,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(l10n.addLecture),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(
                                    context,
                                    Routes.lectureForm,
                                  );
                                },
                              ),
                              ListTile(
                                title: Text(l10n.editSubjects),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(
                                    context,
                                    Routes.subjectsEdit,
                                  );
                                },
                              ),
                              ListTile(
                                title: Text(l10n.editTags),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(context, Routes.tagsEdit);
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: Text(l10n.settings),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(context, Routes.settings);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // 일반: Drawer 사용
                Scaffold.of(scaffoldContext).openDrawer();
              }
            },
          ),
        ),
        title: Text(l10n.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, Routes.search),
          ),
        ],
      ),
      drawer: reduceMotion
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        l10n.menu,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(l10n.addLecture),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.lectureForm);
                    },
                  ),
                  ListTile(
                    title: Text(l10n.editSubjects),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.subjectsEdit);
                    },
                  ),
                  ListTile(
                    title: Text(l10n.editTags),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.tagsEdit);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(l10n.settings),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.settings);
                    },
                  ),
                ],
              ),
            ),
      body: CustomScrollView(
        slivers: [
          // 상단 pill 두 개
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  FilterPill(
                    icon: Icons.tune,
                    label: l10n.filter,
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
                    label: l10n.favorites,
                  ),
                ],
              ),
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
          // 과목 패널 리스트 또는 빈 상태 메시지
          if (subjects.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: EmptyStateMessage(
                  message: favoritesOnly
                      ? l10n.noFavoriteSubjects
                      : selectedTagIds.isNotEmpty
                      ? l10n.noSubjectsWithSelectedTags
                      : '',
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                final Subject s = subjects[i];
                final List<Tag> subjectTags = s.tagIds
                    .map((tid) {
                      try {
                        return tags.firstWhere((t) => t.id == tid);
                      } catch (_) {
                        return null;
                      }
                    })
                    .whereType<Tag>()
                    .toList();
                // 태그 정렬: 숫자 > 한글 > 영어
                int _getNameType(String name) {
                  if (name.isEmpty) {
                    return 3;
                  }
                  final first = name[0];
                  if (RegExp(r'[0-9]').hasMatch(first)) {
                    return 0;
                  }
                  if (RegExp(r'[ㄱ-ㅎ가-힣]').hasMatch(first)) {
                    return 1;
                  }
                  if (RegExp(r'[a-zA-Z]').hasMatch(first)) {
                    return 2;
                  }
                  return 3;
                }

                int _compareTagNames(String a, String b) {
                  final aType = _getNameType(a);
                  final bType = _getNameType(b);
                  if (aType != bType) {
                    return aType.compareTo(bType);
                  }
                  return a.compareTo(b);
                }

                subjectTags.sort((a, b) => _compareTagNames(a.name, b.name));

                final lectures = _manager
                    .getLecturesBySubject(s.id)
                    .map((l) => l.toLecture())
                    .toList();
                return Padding(
                  padding: EdgeInsets.fromLTRB(16, i == 0 ? 6 : 12, 16, 0),
                  child: SubjectPanel(
                    subject: s,
                    tags: subjectTags,
                    lectures: lectures,
                    onToggleFavorite: () async {
                      await _manager.toggleSubjectFavorite(s.id);
                    },
                    onOpenLecture: (Lecture lec) {
                      Navigator.pushNamed(
                        context,
                        Routes.player,
                        arguments: {'lectureId': lec.id},
                      );
                    },
                    onLectureUpdated: () {
                      // Repository가 notifyListeners()를 호출하므로 setState 불필요
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
