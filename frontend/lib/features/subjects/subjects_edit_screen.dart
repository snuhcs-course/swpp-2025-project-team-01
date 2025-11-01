import 'package:flutter/material.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/shared/widgets.dart';

const _editPanelRadius = 22.0;
const _editPanelShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 10,
  offset: Offset(0, 3),
);

/// 주요 기능:
/// - 과목별 패널에 속한 강의 목록 표시
/// - 강의 순서 재정렬 (드래그 앤 드롭)
/// - 과목 추가/수정/삭제
/// - 과목에 태그 할당
/// - 패널 펼침/접기 상태 저장
///
/// UI 구조:
/// - 상단: 앱바 (제목 + 과목 추가 버튼)
/// - 본문: 과목별 펼침 패널 (검은 헤더 + 강의 리스트)
/// - 하단: 고정 버튼 ([수정 완료] [취소])
class SubjectsEditScreen extends StatefulWidget {
  const SubjectsEditScreen({super.key, this.hiveManager});

  final HiveManager? hiveManager;

  @override
  State<SubjectsEditScreen> createState() => _SubjectsEditScreenState();
}

class _SubjectsEditScreenState extends State<SubjectsEditScreen> {
  // 데이터 저장소 인스턴스
  late final HiveManager hive;

  // 작업 중인 데이터 (원본 데이터를 복사하여 수정)
  final Map<String, List<String>> _workingLectureIds = {};
  final Map<String, List<String>> _workingTagIds = {};
  final Map<String, String> _workingTitles = {};

  // 작업 중인 과목 순서 (드래그앤드롭으로 변경 가능)
  List<String> _workingSubjectOrder = [];

  // 삭제된 과목 ID 목록
  final Set<String> _deletedSubjectIds = {};

  // 스크롤 컨트롤러 (자동 스크롤을 위해)
  final ScrollController _scrollController = ScrollController();

  // 저장 중 플래그 (저장 중에는 Hive 변경 리스너를 무시)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    hive = widget.hiveManager ?? HiveManager.instance;
    _initializeWorkingData();
    // 과목 추가/삭제 시 UI를 다시 그리기 위해 리스너 등록
    hive.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 리스너 해제
    hive.removeListener(_onDataChanged);
    super.dispose();
  }

  /// 초기화: 편집용 작업 복사본 생성
  ///
  /// 원본 데이터를 보존하면서 사용자가 편집할 수 있도록
  /// 모든 과목의 강의 ID와 태그 ID를 복사합니다.
  void _initializeWorkingData() {
    final subjects = hive.getSubjects();

    for (final subject in subjects) {
      _workingLectureIds[subject.id] = List.from(subject.lectureIds);
      _workingTagIds[subject.id] = List.from(subject.tagIds);
      _workingTitles[subject.id] = subject.title;
    }

    // 과목 순서 초기화 (현재 getSubjects()가 반환하는 순서)
    // 이미 _workingSubjectOrder가 존재하면 보존 (드래그앤드롭으로 변경된 순서 유지)
    if (_workingSubjectOrder.isEmpty) {
      _workingSubjectOrder = subjects.map((s) => s.id).toList();
    } else {
      // 기존 순서를 유지하되, 새로 추가된 과목이 있으면 추가
      final currentIds = subjects.map((s) => s.id).toSet();
      _workingSubjectOrder.removeWhere((id) => !currentIds.contains(id));
      for (final subject in subjects) {
        if (!_workingSubjectOrder.contains(subject.id)) {
          _workingSubjectOrder.add(subject.id);
        }
      }
    }
  }

  /// Hive 데이터 변경 시 호출되어 화면을 다시 빌드
  void _onDataChanged() {
    // 저장 중일 때는 리스너를 무시 (저장 과정에서 발생하는 변경사항은 무시)
    if (_isSaving) {
      return;
    }

    if (mounted) {
      // 데이터가 변경되었으므로, 작업용 데이터도 다시 초기화
      setState(() {
        _initializeWorkingData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 삭제되지 않은 과목 목록을 _workingSubjectOrder 순서대로 정렬
    final subjectMap = {
      for (var s in hive.getSubjects().map((s) => s.toSubject())) s.id: s,
    };

    final subjects = _workingSubjectOrder
        .where(
          (id) =>
              !_deletedSubjectIds.contains(id) && subjectMap.containsKey(id),
        )
        .map((id) => subjectMap[id]!)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 상단 앱바 - 제목 + 과목 추가 버튼
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).editingSubjects),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSubjectDialog(context),
            tooltip: '과목 추가',
          ),
        ],
      ),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),

      // 과목 목록 (드래그앤드롭 가능)
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        scrollController: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: subjects.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            // 미분류 과목은 드래그 불가 (항상 마지막 위치 유지)
            if (subjects[oldIndex].isUncategorized) {
              return;
            }

            // 미분류 과목의 인덱스 찾기
            final uncategorizedIndex = subjects.indexWhere(
              (s) => s.isUncategorized,
            );

            // 미분류 과목이 있고, 그 위치나 그 뒤로 드래그하려는 경우 차단
            if (uncategorizedIndex != -1 && newIndex >= uncategorizedIndex) {
              return;
            }

            // 드래그앤드롭 인덱스 조정
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }

            // subjects 리스트 기반으로 재정렬
            final reorderedSubjects = List<Subject>.from(subjects);
            final movedSubject = reorderedSubjects.removeAt(oldIndex);
            reorderedSubjects.insert(newIndex, movedSubject);

            // _workingSubjectOrder를 새 순서로 업데이트
            _workingSubjectOrder = reorderedSubjects.map((s) => s.id).toList();
          });
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                elevation: 8,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_editPanelRadius),
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (_, index) {
          final subject = subjects[index];
          return Padding(
            key: ValueKey(subject.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSubjectPanel(subject, index),
          );
        },
      ),

      // 하단 고정 버튼 ([수정 완료] [취소])
      bottomNavigationBar: SafeArea(
        child: _BottomBar(
          primaryLabel: AppLocalizations.of(context).editComplete,
          secondaryLabel: AppLocalizations.of(context).cancel,
          onPrimary: _saveChanges,
          onSecondary: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// 과목 패널 빌더
  ///
  /// 각 과목의 강의 목록을 표시하고 드래그 앤 드롭으로 순서를 재정렬할 수 있습니다.
  Widget _buildSubjectPanel(Subject subject, int index) {
    final lectureIds = _workingLectureIds[subject.id]!;
    final isExpanded = hive.getSubjectExpandedState(subject.id);

    // 강의 리스트를 한 번만 가져와서 Map으로 변환
    final allLectures = hive
        .getLecturesBySubject(subject.id)
        .map((l) => l.toLecture())
        .toList();
    final lectureMap = {for (var lec in allLectures) lec.id: lec};

    // Map에서 O(1)로 조회
    final lectures = lectureIds.map((id) {
      return lectureMap[id] ??
          Lecture(
            id: id,
            subjectId: subject.id,
            weekLabel: 'Week ?',
            title: 'Untitled',
            duration: 0,
          );
    }).toList();

    // 미분류 과목은 다국어 처리된 제목 사용 (왼쪽 여백 추가)
    final displayTitle = subject.isUncategorized
        ? '  ${AppLocalizations.of(context).uncategorized}'
        : _workingTitles[subject.id];

    return _SubjectEditPanel(
      index: index,
      subject: subject,
      displayTitle: displayTitle,
      isInitiallyExpanded: isExpanded,
      lectures: lectures,
      // 강의 순서 재정렬 콜백
      onReorder: (oldIndex, newIndex) {
        setState(() {
          // 드래그 앤 드롭 인덱스 조정
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }

          final item = lectureIds.removeAt(oldIndex);
          lectureIds.insert(newIndex, item);
        });
      },
      // 패널 롱프레스 시 과목 편집 다이얼로그 표시
      onLongPress: () async {
        await _showSubjectEditDialog(subject);
      },
      // 패널 펼침/접기 상태 저장 콜백
      onExpansionChanged: (isExpanded) {
        hive.setSubjectExpandedState(subject.id, isExpanded);
      },
    );
  }

  /// 변경사항 저장
  ///
  /// 모든 편집 내용(삭제, 순서 변경, 태그 변경, 제목 변경)을 저장하고
  /// 홈 화면을 새로고침한 후 이전 화면으로 돌아갑니다.
  Future<void> _saveChanges() async {
    // 저장 시작 - 리스너 무시 플래그 설정
    _isSaving = true;

    try {
      // 1. 삭제된 과목 처리
      for (final subjectId in _deletedSubjectIds) {
        await hive.deleteSubject(subjectId);
      }

      // 2. 과목 제목, 강의 순서 및 태그 업데이트
      for (final subject in hive.getSubjects()) {
        if (!_deletedSubjectIds.contains(subject.id)) {
          // 제목 업데이트
          final newTitle = _workingTitles[subject.id];
          if (newTitle != null && newTitle != subject.title) {
            await hive.updateSubjectTitle(subject.id, newTitle);
          }

          await hive.updateSubjectLectures(
            subject.id,
            _workingLectureIds[subject.id]!,
          );
          await hive.updateSubjectTags(subject.id, _workingTagIds[subject.id]!);
        }
      }

      // 3. 과목 순서 저장
      await hive.updateSubjectOrder(_workingSubjectOrder);

      // 4. 이전 화면으로 돌아가기
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      // 저장 완료 - 플래그 해제
      _isSaving = false;
    }
  }

  /// 과목 편집 다이얼로그 표시
  ///
  /// 과목명 수정, 태그 선택, 과목 삭제 기능을 제공
  Future<void> _showSubjectEditDialog(Subject subject) async {
    // 미분류 과목은 편집 불가
    if (subject.isUncategorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).isKorean
                ? '미분류 과목은 편집할 수 없습니다'
                : 'Uncategorized subject cannot be edited',
          ),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SubjectEditDialog(
        subject: subject,
        initialTagIds: _workingTagIds[subject.id] ?? [],
        allTags: hive.getTags().map((t) => t.toTag()).toList(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    // ========== 다이얼로그 결과 처리 ==========

    if (result['action'] == 'delete') {
      // 삭제 확인 다이얼로그 표시
      final confirmDelete = await _showDeleteConfirmationDialog(subject);

      if (confirmDelete == true && mounted) {
        setState(() {
          _deletedSubjectIds.add(subject.id);
        });
      }
    } else if (result['action'] == 'save') {
      // result는 새로운 과목명과 태그
      setState(() {
        _workingTitles[subject.id] = result['title'] as String;
        _workingTagIds[subject.id] = List<String>.from(
          result['tagIds'] as List,
        );
      });
    }
  }

  /// 과목 삭제 확인 다이얼로그
  ///
  /// 과목 삭제 시 해당 과목의 모든 강의도 함께 삭제됨을 경고
  Future<bool?> _showDeleteConfirmationDialog(Subject subject) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 검은 헤더
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(
                  child: Text(
                    '경고',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // 회색 바디
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '과목 삭제 시\n해당 과목의 강의들까지 전부\n삭제됩니다.\n\n삭제하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // "예" 버튼
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A5A5A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '예',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // "아니오" 버튼
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0C0C0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                '아니오',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 과목 추가 다이얼로그 표시
  ///
  /// 새로운 과목을 생성하고 태그를 할당할 수 있습니다.
  Future<void> _showCreateSubjectDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateSubjectDialog(
        allTags: hive.getTags().map((t) => t.toTag()).toList(),
      ),
    );

    if (!mounted || result == null || result['action'] != 'create') {
      return;
    }

    final titleText = result['title'] as String;
    final selectedTagIds = result['tagIds'] as List<String>;

    await hive.createSubject(titleText, selectedTagIds);

    if (mounted) {
      final newSubject = hive.getSubjects().firstWhere(
        (s) => s.title == titleText,
      );

      setState(() {
        _workingLectureIds[newSubject.id] = [];
        _workingTagIds[newSubject.id] = List.from(selectedTagIds);
        _workingTitles[newSubject.id] = newSubject.title;

        // 새 과목을 _workingSubjectOrder의 맨 앞에 추가
        if (!_workingSubjectOrder.contains(newSubject.id)) {
          _workingSubjectOrder.insert(0, newSubject.id);
        }
      });
    }
  }
}

/// 과목 추가 다이얼로그 위젯
class _CreateSubjectDialog extends StatefulWidget {
  const _CreateSubjectDialog({required this.allTags});

  final List<Tag> allTags;

  @override
  State<_CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<_CreateSubjectDialog> {
  late TextEditingController _titleController;
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).addSubject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '과목명',
              hintText: '예) 소프트웨어 개발의 원리와 실습',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).selectTagsOptional,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.allTags.map((tag) {
                final isSelected = _selectedTagIds.contains(tag.id);
                return SelectableTagPill(
                  tag: tag,
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedTagIds.remove(tag.id);
                      } else {
                        _selectedTagIds.add(tag.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _titleController.text.trim();
            if (text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context).pleaseEnterSubjectName,
                  ),
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'action': 'create',
              'title': text,
              'tagIds': _selectedTagIds.toList(),
            });
          },
          child: Text(AppLocalizations.of(context).add),
        ),
      ],
    );
  }
}

/// 과목 편집 다이얼로그 위젯
class _SubjectEditDialog extends StatefulWidget {
  const _SubjectEditDialog({
    required this.subject,
    required this.initialTagIds,
    required this.allTags,
  });

  final Subject subject;
  final List<String> initialTagIds;
  final List<Tag> allTags;

  @override
  State<_SubjectEditDialog> createState() => _SubjectEditDialogState();
}

class _SubjectEditDialogState extends State<_SubjectEditDialog> {
  late TextEditingController _nameController;
  late Set<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.title);
    _selectedTagIds = Set<String>.from(widget.initialTagIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('과목 수정'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== 과목 이름 입력 ==========
            const Text(
              '과목 이름',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '예) 소프트웨어 개발의 원리와 실습',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '태그 수정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.allTags.map((tag) {
                final isSelected = _selectedTagIds.contains(tag.id);
                return SelectableTagPill(
                  tag: tag,
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedTagIds.remove(tag.id);
                      } else {
                        _selectedTagIds.add(tag.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ========== 과목 삭제 버튼 ==========
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 231, 76, 60),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {'action': 'delete'});
                  },
                  icon: const Icon(Icons.delete),
                  label: Text(AppLocalizations.of(context).deleteSubject),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final newTitle = _nameController.text.trim();
            if (newTitle.isEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('과목명을 입력해주세요')));
              return;
            }
            Navigator.pop(context, {
              'action': 'save',
              'title': newTitle,
              'tagIds': _selectedTagIds.toList(),
            });
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// 개별 과목 편집 패널 위젯
///
/// 과목의 강의 목록을 표시하고 드래그 앤 드롭으로 순서 변경
///
/// 기능:
/// - 패널 펼침/접기 (상태 저장됨)
/// - 강의 순서 재정렬 (드래그 앤 드롭)
/// - 롱프레스로 과목 편집 다이얼로그 열기
class _SubjectEditPanel extends StatefulWidget {
  const _SubjectEditPanel({
    required this.index,
    required this.subject,
    this.displayTitle,
    required this.isInitiallyExpanded,
    required this.lectures,
    required this.onReorder,
    required this.onLongPress,
    required this.onExpansionChanged,
  });

  final int index;
  final Subject subject;
  final String? displayTitle;
  final bool isInitiallyExpanded;
  final List<Lecture> lectures;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onExpansionChanged;

  @override
  State<_SubjectEditPanel> createState() => _SubjectEditPanelState();
}

class _SubjectEditPanelState extends State<_SubjectEditPanel>
    with SingleTickerProviderStateMixin {
  // 패널 펼침 상태 (기본값: true)
  bool expanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // 저장된 펼침 상태 로드
    expanded = widget.isInitiallyExpanded;
    // reduce motion 설정 확인
    final reduceMotion =
        HiveManager.instance.settings.accessibilityReduceMotion;
    final Duration duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    // AnimationController 생성
    _animationController = AnimationController(duration: duration, vsync: this);
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: reduceMotion ? Curves.linear : Curves.easeInOut,
    );
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white,
    ).animate(_animationController);

    // 초기 상태 설정
    _animationController.value = expanded ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 펼침/접기 토글
  void _toggleExpanded() {
    setState(() {
      expanded = !expanded;
    });

    // 변경된 상태를 부모 위젯에 알림
    widget.onExpansionChanged(expanded);

    final bool reduceMotion =
        HiveManager.instance.settings.accessibilityReduceMotion;
    if (reduceMotion) {
      // 모션 줄이기가 활성화되면 즉시 전환
      _animationController.value = expanded ? 1.0 : 0.0;
    } else {
      // 일반 애니메이션
      if (expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  /// 드래그 가능한 헤더 빌드 (드래그 핸들 포함)
  Widget _buildDraggableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color headerColor = isDark
        ? const Color(0xFF2D2D2D) // 다크모드: 어두운 회색
        : const Color(0xFF1D1D1D); // 라이트모드: 검은색
    final Color textColor = Colors.white;
    final Color iconColor = Colors.white;

    final BorderRadius resolvedRadius = expanded
        ? BorderRadius.only(
            topLeft: Radius.circular(_editPanelRadius),
            topRight: Radius.circular(_editPanelRadius),
          )
        : BorderRadius.circular(_editPanelRadius);

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: resolvedRadius,
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            // 드래그 핸들 (좌측) - 미분류 과목은 숨김
            if (!widget.subject.isUncategorized) ...[
              ReorderableDragStartListener(
                index: widget.index,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.drag_indicator,
                    color: iconColor.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              // 미분류 과목은 드래그 핸들 대신 여백
              const SizedBox(width: 40),
            ],
            // 제목
            Expanded(
              child: Text(
                widget.displayTitle ?? widget.subject.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 펼침/접기 버튼 (우측)
            IconButton(
              icon: Icon(
                expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                color: iconColor,
              ),
              onPressed: _toggleExpanded,
              tooltip: expanded ? '접기' : '펼치기',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_editPanelRadius),
        boxShadow: expanded ? const [_editPanelShadow] : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_editPanelRadius),
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(color: _colorAnimation.value, child: child);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== 검은 헤더 (과목 이름 + 펼침 버튼 + 드래그 핸들) ==========
              _buildDraggableHeader(),

              // ========== 강의 리스트 (펼쳤을 때만 표시) ==========
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: widget.lectures.length,
                    onReorder: widget.onReorder,
                    itemBuilder: (_, idx) {
                      final lecture = widget.lectures[idx];
                      return Container(
                        key: ValueKey(lecture.id),
                        child: ListTile(
                          // 드래그 핸들
                          leading: ReorderableDragStartListener(
                            index: idx,
                            child: const Icon(Icons.drag_handle),
                          ),
                          // 강의 정보 (주차 • 제목)
                          title: Text(
                            '${lecture.weekLabel}  •  ${lecture.title}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 고정 버튼 바 위젯
///
/// 주 버튼(왼쪽)과 부 버튼(오른쪽)을 표시합니다.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? null // 다크모드: Scaffold 기본 배경색 사용
        : const Color(0xFFF5F5F5); // 라이트모드: Scaffold와 동일한 배경색

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        color: backgroundColor,
        child: Row(
          children: [
            // 주 버튼 (수정 완료)
            Expanded(
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            const SizedBox(width: 12),
            // 부 버튼 (취소)
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
