// 홈 메인: 상단 필터/즐겨찾기 pill + 태그칩 + 과목 패널 리스트
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/home/home_widgets.dart';
import 'package:re_view/features/home/custom_drawer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 메인 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool favoritesOnly = false;
  bool showTagFilter = false;
  bool editModeEnabled = false;
  final Set<String> selectedTagIds = {};
  List<HiveSubject> _editingSubjects = [];

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

  void _refreshSubjects(List<HiveSubject> currentSubjects) {
    _editingSubjects = List<HiveSubject>.from(currentSubjects);
  }

  Future<void> _onReorderSubject(int oldIndex, int newIndex) async {
    setState(() {
      final item = _editingSubjects.removeAt(oldIndex);
      if (newIndex < 0) {
        newIndex = 0;
      }
      if (newIndex > _editingSubjects.length) {
        newIndex = _editingSubjects.length;
      }
      _editingSubjects.insert(newIndex, item);
    });

    // persist the new subject order in Hive
    await _manager.updateSubjectOrder(
      _editingSubjects.map((s) => s.id).toList(),
    );
  }

  /// 태그 이름의 타입을 반환 (정렬 우선순위: 숫자 > 한글 > 영어)
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

  /// 태그 이름 비교 함수 (숫자 > 한글 > 영어 순서)
  int _compareTagNames(String a, String b) {
    final aType = _getNameType(a);
    final bType = _getNameType(b);
    if (aType != bType) {
      return aType.compareTo(bType);
    }
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // HiveManager가 초기화되지 않았으면 로딩 표시
    if (!_manager.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tags = _manager.getTags();
    final subjects = _manager
        .getSubjects(
          favoritesOnly: favoritesOnly,
          filterTagIds: selectedTagIds.toList(),
        )
        .where((subject) {
          // 미분류 과목은 강의가 있을 때만 표시
          if (subject.isUncategorized) {
            return subject.lectureIds.isNotEmpty;
          }
          return true;
        })
        .toList();
    if (editModeEnabled) {
      if (_editingSubjects.length != subjects.length) {
        _refreshSubjects(subjects);
      }
    }

    final reduceMotion = _manager.settings.accessibilityReduceMotion;

    return Scaffold(
      appBar: AppBar(
        // 좌 햄버거, 중앙 타이틀, 우 검색
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (reduceMotion) {
                // 모션 줄이기: 즉시 나타나는 다이얼로그
                CustomDrawer.showAsDialog(context);
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
      drawer: reduceMotion ? null : const CustomDrawer(),
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
                  const Spacer(),
                  EditPill(
                    active: editModeEnabled,
                    icon: Icons.edit,
                    label: l10n.editMode,
                    onTap: () => setState(() {
                      // Show all subjects on edit mode entrance
                      favoritesOnly = false;
                      showTagFilter = false;
                      selectedTagIds.clear();
                      editModeEnabled = !editModeEnabled;
                    }),
                  ),
                  const SizedBox(width: 6),
                  AddPill(
                    icon: Icons.add,
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.lectureForm),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: editModeEnabled
                  ? SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cols =
                              MediaQuery.of(context).size.width >
                                  MediaQuery.of(context).size.height
                              ? 2
                              : 1;
                          final totalWidth = constraints.maxWidth;
                          final spacing = 12.0;
                          final tileWidth =
                              (totalWidth - (cols - 1) * spacing) / cols;

                          return ReorderableWrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            needsLongPressDraggable: false,
                            onReorder: _onReorderSubject,
                            buildDraggableFeedback:
                                (context, constraints, child) => Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(16),
                                  child: child,
                                ),
                            children: [
                              for (int i = 0; i < _editingSubjects.length; i++)
                                SizedBox(
                                  key: ValueKey(_editingSubjects[i].id),
                                  width: tileWidth,
                                  child: SubjectPanel(
                                    subject: _editingSubjects[i],
                                    tags: _editingSubjects[i].tagIds
                                        .map((tid) {
                                          try {
                                            return tags.firstWhere(
                                              (t) => t.id == tid,
                                            );
                                          } catch (_) {
                                            return null;
                                          }
                                        })
                                        .whereType<HiveTag>()
                                        .toList(),
                                    lectures: _manager.getLecturesBySubject(
                                      _editingSubjects[i].id,
                                    ),
                                    onToggleFavorite: () async =>
                                        _manager.toggleSubjectFavorite(
                                          _editingSubjects[i].id,
                                        ),
                                    onOpenLecture: (_) {},
                                    onLectureUpdated: () {},
                                    showEdit: true,
                                    reorderIndex: i, // drag handle index
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    )
                  : SliverMasonryGrid.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width >
                              MediaQuery.of(context).size.height
                          ? 2
                          : 1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childCount: subjects.length,
                      itemBuilder: (context, i) {
                        final HiveSubject s = subjects[i];
                        final List<HiveTag> subjectTags = s.tagIds
                            .map((tid) {
                              try {
                                return tags.firstWhere((t) => t.id == tid);
                              } catch (_) {
                                return null;
                              }
                            })
                            .whereType<HiveTag>()
                            .toList();
                        // 태그 정렬: 숫자 > 한글 > 영어
                        subjectTags.sort(
                          (a, b) => _compareTagNames(a.name, b.name),
                        );

                        final lectures = _manager.getLecturesBySubject(s.id);
                        return SubjectPanel(
                          key: ValueKey(s.id),
                          subject: s,
                          tags: subjectTags,
                          lectures: lectures,
                          onToggleFavorite: () async {
                            await _manager.toggleSubjectFavorite(s.id);
                          },
                          onOpenLecture: (HiveLecture lec) {
                            Navigator.pushNamed(
                              context,
                              Routes.player,
                              arguments: {'lectureId': lec.id},
                            );
                          },
                          onLectureUpdated: () {
                            // Repository가 notifyListeners()를 호출하므로 setState 불필요
                          },
                          showEdit: editModeEnabled,
                        );
                      },
                    ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
