// 홈 메인: 상단 필터/즐겨찾기 pill + 태그칩 + 과목 패널 리스트
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/device_orientation_helper.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/home/add_pill.dart';
import 'package:re_view/features/home/home_widgets.dart';
import 'package:re_view/features/home/custom_drawer.dart';
import 'package:re_view/features/home/home_subject_widgets.dart';

/// 메인 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool favoritesOnly = false;
  bool showTagFilter = false;
  bool editModeEnabled = false;
  bool isAddMenuOpen = false;

  int? _draggingIndex;
  int? _hoverIndex;

  final Set<String> selectedTagIds = {};
  List<HiveSubject> _editingSubjects = [];

  late final HiveManager _manager = HiveManager.instance;
  final GlobalKey _addPillKey = GlobalKey();
  final LayerLink _addLink = LayerLink();

  @override
  void initState() {
    super.initState();

    // WidgetsBindingObserver 등록
    WidgetsBinding.instance.addObserver(this);

    // 초기 orientation 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        lockToCurrentOrientation(context);
      }
    });

    _manager.addListener(_onDataChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 foreground로 돌아올 때 orientation 재설정
    if (state == AppLifecycleState.resumed && mounted) {
      lockToCurrentOrientation(context);
    }
  }

  @override
  void dispose() {
    // 리스너 제거
    WidgetsBinding.instance.removeObserver(this);
    _manager.removeListener(_onDataChanged);
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Player로 이동하고 돌아올 때 orientation 재설정
  Future<void> _navigateToPlayer(String lectureId) async {
    // PlayerScreen 활성화 중에는 HomeScreen의 orientation 관찰 중단
    WidgetsBinding.instance.removeObserver(this);

    await Navigator.pushNamed(
      context,
      Routes.player,
      arguments: {'lectureId': lectureId},
    );

    // Player에서 돌아온 후 observer 재등록 및 orientation 재설정
    WidgetsBinding.instance.addObserver(this);
    if (mounted) {
      lockToCurrentOrientation(context);
    }
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
      // 미분류가 아닌 과목들만 재정렬
      final categorizedSubjects = _editingSubjects
          .where((s) => !s.isUncategorized)
          .toList();
      final uncategorizedSubjects = _editingSubjects
          .where((s) => s.isUncategorized)
          .toList();

      // categorizedSubjects 내에서 재정렬
      final item = categorizedSubjects.removeAt(oldIndex);

      // newIndex 범위 체크
      if (newIndex < 0) {
        newIndex = 0;
      }
      if (newIndex > categorizedSubjects.length) {
        newIndex = categorizedSubjects.length;
      }

      categorizedSubjects.insert(newIndex, item);

      // _editingSubjects 재구성 (일반 과목 + 미분류)
      _editingSubjects = [...categorizedSubjects, ...uncategorizedSubjects];
    });

    // persist the new subject order in Hive
    await _manager.updateSubjectOrder(
      _editingSubjects.map((s) => s.id).toList(),
    );
  }

  Future<void> _showSubjectEditDialog(HiveSubject subject) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => SubjectEditDialog(
        subject: subject,
        initialTagIds: subject.tagIds,
        allTags: _manager.getTags(),
      ),
    );

    if (!mounted) {
      return;
    }

    // 수정 모드에서 과목 목록을 항상 새로고침하여 태그 변경사항 반영
    if (editModeEnabled) {
      _refreshSubjects(_manager.getSubjects());
    }
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
          } else if (subject.isArchived) {
            return false;
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
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              CustomDrawer.open(scaffoldContext, reduceMotion);
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
      drawer: reduceMotion ? null : CustomDrawer(reduceMotion: reduceMotion),
      body: CustomScrollView(
        slivers: [
          // 상단 pill 네 개
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
                      if (editModeEnabled) {
                        _showSnackBar(l10n.notSupportedInEdit);
                      } else {
                        showTagFilter = !showTagFilter;
                        // 필터 버튼을 비활성화할 때 모든 태그 선택 해제
                        if (!showTagFilter) {
                          selectedTagIds.clear();
                        }
                      }
                    }),
                  ),
                  const SizedBox(width: 6),
                  FavoritePill(
                    active: favoritesOnly,
                    onTap: () => setState(() {
                      if (editModeEnabled) {
                        _showSnackBar(l10n.notSupportedInEdit);
                      } else {
                        favoritesOnly = !favoritesOnly;
                      }
                    }),
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
                  CompositedTransformTarget(
                    link: _addLink,
                    child: AddPill(
                      key: _addPillKey,
                      icon: Icons.add,
                      link: _addLink,
                    ),
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
                      : l10n.noLectures,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverMasonryGrid.count(
                crossAxisCount:
                    MediaQuery.of(context).size.width >
                        MediaQuery.of(context).size.height
                    ? 2
                    : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: subjects.length,
                itemBuilder: (context, i) {
                  // 드래그 중일 때 재정렬된 리스트 생성
                  final displaySubjects = List<HiveSubject>.from(subjects);
                  if (_draggingIndex != null && _hoverIndex != null && editModeEnabled) {
                    // 미분류가 아닌 과목들만 재정렬
                    final categorized = subjects.where((s) => !s.isUncategorized).toList();
                    final uncategorized = subjects.where((s) => s.isUncategorized).toList();

                    if (_draggingIndex! < categorized.length && _hoverIndex! < categorized.length) {
                      final item = categorized.removeAt(_draggingIndex!);
                      categorized.insert(_hoverIndex!, item);
                      displaySubjects.clear();
                      displaySubjects.addAll([...categorized, ...uncategorized]);
                    }
                  }

                  final HiveSubject s = displaySubjects[i];
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
                  subjectTags.sort((a, b) => _compareTagNames(a.name, b.name));

                  final lectures = _manager.getLecturesBySubject(s.id);

                  // Placeholder 표시 여부
                  // 드래그한 아이템이 이동한 자리(_hoverIndex)에 placeholder 표시
                  final bool isPlaceholder = _hoverIndex == i && _draggingIndex != null;

                  Widget panel = SubjectPanel(
                    key: ValueKey(s.id),
                    subject: s,
                    tags: subjectTags,
                    lectures: lectures,
                    onToggleFavorite: () async {
                      await _manager.toggleSubjectFavorite(s.id);
                    },
                    onOpenLecture: (HiveLecture lec) {
                      _navigateToPlayer(lec.id);
                    },
                    onLectureUpdated: () {},
                    showEdit: editModeEnabled,
                    onEditSubject: editModeEnabled && !s.isUncategorized
                        ? () async => _showSubjectEditDialog(s)
                        : null,
                    reorderIndex: editModeEnabled && !s.isUncategorized
                        ? i
                        : null,
                  );

                  // Placeholder 스타일
                  if (isPlaceholder) {
                    panel = Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Opacity(opacity: 0.5, child: panel),
                    );
                  }

                  // Edit 모드이고 미분류가 아닐 때만 드래그 가능하게
                  if (editModeEnabled && !s.isUncategorized) {
                    final itemWidth =
                        (MediaQuery.of(context).size.width - 44) /
                        (MediaQuery.of(context).size.width >
                                MediaQuery.of(context).size.height
                            ? 2
                            : 1);

                    return Draggable<int>(
                      data: i,
                      feedback: Material(
                        elevation: 8,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: Opacity(
                          opacity: 0.9,
                          child: SizedBox(
                            width: itemWidth,
                            child: SubjectPanel(
                              key: ValueKey('feedback_${s.id}'),
                              subject: s,
                              tags: subjectTags,
                              lectures: lectures,
                              onToggleFavorite: () async {},
                              onOpenLecture: (_) {},
                              onLectureUpdated: () {},
                              showEdit: true,
                              reorderIndex: null,
                            ),
                          ),
                        ),
                      ),
                      onDragStarted: () {
                        setState(() {
                          _draggingIndex = i;
                          _hoverIndex = i;
                        });
                      },
                      onDragEnd: (details) {
                        setState(() {
                          if (_hoverIndex != null &&
                              _draggingIndex != _hoverIndex) {
                            _onReorderSubject(_draggingIndex!, _hoverIndex!);
                          }
                          _draggingIndex = null;
                          _hoverIndex = null;
                        });
                      },
                      onDraggableCanceled: (velocity, offset) {
                        setState(() {
                          _draggingIndex = null;
                          _hoverIndex = null;
                        });
                      },
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (fromIndex) {
                          return fromIndex != null && fromIndex != i;
                        },
                        onAccept: (fromIndex) {
                          // onDragEnd에서 처리하므로 여기서는 비워둠
                        },
                        onMove: (details) {
                          if (_hoverIndex != i) {
                            setState(() {
                              _hoverIndex = i;
                            });
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return panel;
                        },
                      ),
                    );
                  }

                  return panel;
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
