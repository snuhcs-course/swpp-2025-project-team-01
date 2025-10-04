import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

/// Figma 2-2. Modifying Subjects
/// - 과목별 패널(검은 헤더) 안에 강의 리스트
/// - 강의: 좌측 드래그 핸들, 썸네일 자리, 제목/주차, 우측 삭제(빨간 원)
/// - 하단 고정 버튼: [수정 완료] [취소]
class SubjectsEditScreen extends StatefulWidget {
  const SubjectsEditScreen({super.key});
  @override
  State<SubjectsEditScreen> createState() => _SubjectsEditScreenState();
}

class _SubjectsEditScreenState extends State<SubjectsEditScreen> {
  final repo = Repo.instance;
  Map<String, List<String>> _workingLectureIds = {};
  Map<String, List<String>> _workingTagIds = {};
  Set<String> _deletedSubjectIds = {};

  @override
  void initState() {
    super.initState();
    // 편집용 작업 복사본
    for (final s in repo.getSubjects()) {
      _workingLectureIds[s.id] = List.from(s.lectureIds);
      _workingTagIds[s.id] = List.from(s.tagIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = repo.getSubjects().where((s) => !_deletedSubjectIds.contains(s.id)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = subjects[i];
          final lectureIds = _workingLectureIds[s.id]!;
          final lectures = lectureIds.map((id) => repo.lecturesBySubject(s.id).firstWhere((l) => l.id == id, orElse: () => Lecture(id: id, subjectId: s.id, weekLabel: 'Week ?', title: 'Untitled', durationSec: 0))).toList();
          return _SubjectEditPanel(
            subject: s,
            lectures: lectures,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = lectureIds.removeAt(oldIndex);
                lectureIds.insert(newIndex, item);
              });
            },
            onDeleteLecture: (lec) {
              setState(() => lectureIds.remove(lec.id));
            },
            onDeleteSubject: () async {
              final ok = await _confirmDeleteSubject(context);
              if (ok == true && mounted) {
                setState(() {
                  _deletedSubjectIds.add(s.id);
                });
              }
            },
            onEditTags: () async {
              final selectedTags = await _showTagSelector(context, _workingTagIds[s.id] ?? []);
              if (selectedTags != null && mounted) {
                setState(() {
                  _workingTagIds[s.id] = selectedTags;
                });
              }
            },
          );
        },
      ),
      bottomNavigationBar: _BottomBar(
        primaryLabel: AppLocalizations.of(context).editComplete,
        secondaryLabel: AppLocalizations.of(context).cancel,
        onPrimary: () async {
          // 삭제된 과목 처리
          for (final subjectId in _deletedSubjectIds) {
            await repo.deleteSubject(subjectId);
          }
          // 수업 순서 및 태그 업데이트
          for (final s in repo.getSubjects()) {
            if (!_deletedSubjectIds.contains(s.id)) {
              await repo.updateSubjectLectures(s.id, _workingLectureIds[s.id]!);
              await repo.updateSubjectTags(s.id, _workingTagIds[s.id]!);
            }
          }
          // 홈 화면 강제 새로고침
          repo.refresh();
          if (mounted) {
            Navigator.pop(context);
          }
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  Future<bool?> _confirmDeleteSubject(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
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
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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

  Future<List<String>?> _showTagSelector(BuildContext context, List<String> currentTagIds) {
    final allTags = repo.getTags();
    final selectedTagIds = Set<String>.from(currentTagIds);

    return showDialog<List<String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).selectTags),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final isSelected = selectedTagIds.contains(tag.id);
                return FilterChip(
                  label: Text('#${tag.name}'),
                  selected: isSelected,
                  backgroundColor: Color(tag.color),
                  selectedColor: Color(tag.color),
                  checkmarkColor: Colors.black,
                  onSelected: (selected) {
                    setDialogState(() {
                      if (selected) {
                        selectedTagIds.add(tag.id);
                      } else {
                        selectedTagIds.remove(tag.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedTagIds.toList()),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateSubjectDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final allTags = repo.getTags();
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
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '과목명',
                  hintText: '예) 소프트웨어 개발의 원리와 실제',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).selectTagsOptional, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allTags.map((tag) {
                    final isSelected = selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text('#${tag.name}'),
                      selected: isSelected,
                      backgroundColor: Color(tag.color),
                      selectedColor: Color(tag.color),
                      checkmarkColor: Colors.black,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedTagIds.add(tag.id);
                          } else {
                            selectedTagIds.remove(tag.id);
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
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).pleaseEnterSubjectName)),
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

    if (result == true && mounted) {
      await repo.createSubject(titleController.text.trim(), selectedTagIds.toList());
      // 새로 생성된 과목의 작업 복사본 초기화
      final newSubject = repo.getSubjects().firstWhere((s) => s.title == titleController.text.trim());
      setState(() {
        _workingLectureIds[newSubject.id] = [];
        _workingTagIds[newSubject.id] = List.from(selectedTagIds);
      });
    }
    titleController.dispose();
  }
}

/// 개별 과목 편집 패널 위젯 - 강의 정렬 및 삭제 기능
class _SubjectEditPanel extends StatefulWidget {
  final Subject subject;
  final List<Lecture> lectures;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Lecture lec) onDeleteLecture;
  final VoidCallback onDeleteSubject;
  final VoidCallback onEditTags;

  const _SubjectEditPanel({
    required this.subject,
    required this.lectures,
    required this.onReorder,
    required this.onDeleteLecture,
    required this.onDeleteSubject,
    required this.onEditTags,
  });

  @override
  State<_SubjectEditPanel> createState() => _SubjectEditPanelState();
}

class _SubjectEditPanelState extends State<_SubjectEditPanel> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          // 검은 헤더 느낌 (간략화)
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Expanded(child: Text(widget.subject.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onEditTags,
                child: Text(AppLocalizations.of(context).editTags2, style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent.shade200, foregroundColor: Colors.white),
                onPressed: widget.onDeleteSubject,
                child: Text(AppLocalizations.of(context).deleteSubject),
              ),
              IconButton(
                color: Colors.white,
                icon: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                onPressed: () => setState(() => expanded = !expanded),
              ),
            ]),
          ),
          if (!expanded) const SizedBox.shrink() else ...[
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.lectures.length,
              onReorder: widget.onReorder,
              itemBuilder: (_, idx) {
                final lec = widget.lectures[idx];
                return Container(
                  key: ValueKey(lec.id),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: idx,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text('${lec.weekLabel}  •  ${lec.title}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => widget.onDeleteLecture(lec),
                    ),
                  ),
                );
              },
            ),
          ],
        ]),
      ),
    );
  }
}

/// 하단 고정 버튼 바 위젯 (주 버튼과 부 버튼)
class _BottomBar extends StatelessWidget {
  final String primaryLabel, secondaryLabel;
  final VoidCallback onPrimary, onSecondary;
  const _BottomBar({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        color: const Color(0xFFEDEDED),
        child: Row(children: [
          Expanded(child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel))),
        ]),
      ),
    );
  }
}
