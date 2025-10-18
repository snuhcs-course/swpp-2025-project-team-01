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

/// 과목 편집 화면 (Figma 2-2. Modifying Subjects)
///
/// 이 화면은 과목 목록을 관리하고 편집할 수 있는 기능을 제공합니다.
///
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
  const SubjectsEditScreen({super.key});

  @override
  State<SubjectsEditScreen> createState() => _SubjectsEditScreenState();
}

class _SubjectsEditScreenState extends State<SubjectsEditScreen> {
  // 데이터 저장소 인스턴스
  final hive = HiveManager.instance;

  // 작업 중인 데이터 (원본 데이터를 복사하여 수정)
  final Map<String, List<String>> _workingLectureIds = {};
  final Map<String, List<String>> _workingTagIds = {};
  final Map<String, String> _workingTitles = {};

  // 삭제된 과목 ID 목록
  final Set<String> _deletedSubjectIds = {};

  @override
  void initState() {
    super.initState();
    _initializeWorkingData();
  }

  /// 초기화: 편집용 작업 복사본 생성
  ///
  /// 원본 데이터를 보존하면서 사용자가 편집할 수 있도록
  /// 모든 과목의 강의 ID와 태그 ID를 복사합니다.
  void _initializeWorkingData() {
    for (final subject in hive.getSubjects()) {
      _workingLectureIds[subject.id] = List.from(subject.lectureIds);
      _workingTagIds[subject.id] = List.from(subject.tagIds);
      _workingTitles[subject.id] = subject.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 삭제되지 않은 과목 목록만 표시
    final subjects = hive
        .getSubjects()
        .map((s) => s.toSubject())
        .where((s) => !_deletedSubjectIds.contains(s.id))
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

      // 과목 목록 (스크롤 가능)
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final subject = subjects[index];
          return _buildSubjectPanel(subject);
        },
      ),

      // 하단 고정 버튼 ([수정 완료] [취소])
      bottomNavigationBar: _BottomBar(
        primaryLabel: AppLocalizations.of(context).editComplete,
        secondaryLabel: AppLocalizations.of(context).cancel,
        onPrimary: _saveChanges,
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  /// 과목 패널 빌더
  ///
  /// 각 과목의 강의 목록을 표시하고 드래그 앤 드롭으로 순서를 재정렬할 수 있습니다.
  Widget _buildSubjectPanel(Subject subject) {
    final lectureIds = _workingLectureIds[subject.id]!;

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
            durationSec: 0,
          );
    }).toList();

    return _SubjectEditPanel(
      key: ValueKey(subject.id),
      subject: subject,
      displayTitle: _workingTitles[subject.id],
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
    );
  }

  /// 변경사항 저장
  ///
  /// 모든 편집 내용(삭제, 순서 변경, 태그 변경, 제목 변경)을 저장하고
  /// 홈 화면을 새로고침한 후 이전 화면으로 돌아갑니다.
  Future<void> _saveChanges() async {
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

    // 3. 이전 화면으로 돌아가기
    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// 과목 편집 다이얼로그 표시
  ///
  /// 과목명 수정, 태그 선택, 과목 삭제 기능을 제공합니다.
  Future<void> _showSubjectEditDialog(Subject subject) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SubjectEditDialog(
        subject: subject,
        initialTagIds: _workingTagIds[subject.id] ?? [],
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
  /// 과목 삭제 시 해당 과목의 모든 강의도 함께 삭제됨을 경고합니다.
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
    final titleController = TextEditingController();
    final allTags = hive.getTags();
    final selectedTagIds = <String>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).addSubject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 과목명 입력
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '과목명',
                  hintText: '예) 소프트웨어 개발의 원리와 실습',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // 태그 선택
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
                  children: allTags.map((tag) {
                    final isSelected = selectedTagIds.contains(tag.id);
                    return ChoiceChip(
                      label: Text(
                        '#${tag.name}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setDialogState(() {
                          if (isSelected) {
                            selectedTagIds.remove(tag.id);
                          } else {
                            selectedTagIds.add(tag.id);
                          }
                        });
                      },
                      backgroundColor: Color(tag.color),
                      selectedColor: Color(tag.color),
                      elevation: isSelected ? 4 : 2,
                      side: BorderSide.none,
                      showCheckmark: true,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).pleaseEnterSubjectName,
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(AppLocalizations.of(context).add),
            ),
          ],
        ),
      ),
    );

    // 다이얼로그 결과 처리
    if (mounted && result == true) {
      await hive.createSubject(
        titleController.text.trim(),
        selectedTagIds.toList(),
      );

      // 새로 생성된 과목의 작업 복사본 초기화
      final newSubject = hive.getSubjects().firstWhere(
        (s) => s.title == titleController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _workingLectureIds[newSubject.id] = [];
          _workingTagIds[newSubject.id] = List.from(selectedTagIds);
          _workingTitles[newSubject.id] = newSubject.title;
        });
      }
    }

    // 컨트롤러 해제
    titleController.dispose();
  }
}

/// 과목 편집 다이얼로그 위젯
class _SubjectEditDialog extends StatefulWidget {
  const _SubjectEditDialog({
    required this.subject,
    required this.initialTagIds,
  });

  final Subject subject;
  final List<String> initialTagIds;

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
    final allTags = HiveManager.instance.getTags();

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

            // ========== 태그 수정 ==========
            const Text(
              '태그 수정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final isSelected = _selectedTagIds.contains(tag.id);
                return ChoiceChip(
                  label: Text(
                    '#${tag.name}',
                    style: const TextStyle(color: Colors.black),
                  ),
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
                  backgroundColor: Color(tag.color),
                  selectedColor: Color(tag.color),
                  elevation: isSelected ? 4 : 2,
                  side: BorderSide.none,
                  showCheckmark: true,
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
                    backgroundColor: Colors.red,
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
/// 과목의 강의 목록을 표시하고 드래그 앤 드롭으로 순서를 변경할 수 있습니다.
///
/// 기능:
/// - 패널 펼침/접기 (상태 저장됨)
/// - 강의 순서 재정렬 (드래그 앤 드롭)
/// - 롱프레스로 과목 편집 다이얼로그 열기
class _SubjectEditPanel extends StatefulWidget {
  const _SubjectEditPanel({
    super.key,
    required this.subject,
    this.displayTitle,
    required this.lectures,
    required this.onReorder,
    required this.onLongPress,
  });

  final Subject subject;
  final String? displayTitle;
  final List<Lecture> lectures;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onLongPress;

  @override
  State<_SubjectEditPanel> createState() => _SubjectEditPanelState();
}

class _SubjectEditPanelState extends State<_SubjectEditPanel> {
  // 패널 펼침 상태 (기본값: true)
  bool expanded = true;

  @override
  void initState() {
    super.initState();
    _loadExpandedState();
  }

  /// 저장된 펼침 상태 불러오기
  Future<void> _loadExpandedState() async {
    setState(() {
      expanded = HiveManager.instance.getSubjectExpandedState(
        widget.subject.id,
      );
    });
  }

  /// 펼침 상태 저장
  Future<void> _saveExpandedState(bool value) async {
    await HiveManager.instance.setSubjectExpandedState(
      widget.subject.id,
      value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: expanded ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(_editPanelRadius),
        boxShadow: expanded ? const [_editPanelShadow] : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========== 검은 헤더 (과목 이름 + 펼침 버튼) ==========
          SubjectPanelHeader(
            title: widget.displayTitle ?? widget.subject.title,
            tags: const [], // 과목 수정 화면에서는 태그 표시 안 함
            expanded: expanded,
            onToggleExpanded: () {
              final newState = !expanded;
              setState(() => expanded = newState);
              _saveExpandedState(newState);
            },
            panelRadius: _editPanelRadius,
            collapsedRadius: BorderRadius.circular(_editPanelRadius),
            onLongPress: widget.onLongPress,
            titleEndPadding: 8,
          ),

          // ========== 강의 리스트 (펼쳤을 때만 표시) ==========
          if (expanded)
            Padding(
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
                      title: Text('${lecture.weekLabel}  •  ${lecture.title}'),
                    ),
                  );
                },
              ),
            ),
        ],
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        color: const Color(0xFFEDEDED),
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
