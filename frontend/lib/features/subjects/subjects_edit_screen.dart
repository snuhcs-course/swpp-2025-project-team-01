import 'package:flutter/material.dart';
import '../../data/repository.dart';
import '../../data/models.dart';

/// 과목 편집 화면 - 과목별 강의 목록을 편집하고 정렬/삭제 가능
class SubjectsEditScreen extends StatefulWidget {
  const SubjectsEditScreen({super.key});
  @override
  State<SubjectsEditScreen> createState() => _SubjectsEditScreenState();
}

class _SubjectsEditScreenState extends State<SubjectsEditScreen> {
  final repo = Repo.instance;
  final Map<String, List<Lecture>> _working = {};

  @override
  void initState() {
    super.initState();
    // 편집용 작업 복사본
    for (final s in repo.getSubjects()) {
      _working[s.id] = List.of(repo.lecturesBySubject(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = repo.getSubjects();

    return Scaffold(
      appBar: AppBar(title: const Text('과목 수정')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = subjects[i];
          final lectures = _working[s.id]!;
          return _SubjectEditPanel(
            subject: s,
            lectures: lectures,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = lectures.removeAt(oldIndex);
                lectures.insert(newIndex, item);
              });
            },
            onDeleteLecture: (lec) {
              setState(() => lectures.removeWhere((e) => e.id == lec.id));
            },
            onDeleteSubject: () async {
              final ok = await _confirmDeleteSubject(context);
              if (ok == true) {
                setState(() {
                  _working.remove(s.id);
                });
              }
            },
          );
        },
      ),
      bottomNavigationBar: _BottomBar(
        primaryLabel: '수정 완료',
        secondaryLabel: '취소',
        onPrimary: () {
          // TODO: repo에 반영(정렬/삭제 결과 저장)
          Navigator.pop(context);
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  Future<bool?> _confirmDeleteSubject(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('경고'),
        content: const Text('과목 삭제 시\n해당 과목의 강의들까지 전부\n'
            '영구히 삭제됩니다.\n\n삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('아니요')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('예')),
        ],
      ),
    );
  }
}

/// 개별 과목 편집 패널 위젯 - 강의 정렬 및 삭제 기능
class _SubjectEditPanel extends StatefulWidget {
  final Subject subject;
  final List<Lecture> lectures;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Lecture lec) onDeleteLecture;
  final VoidCallback onDeleteSubject;

  const _SubjectEditPanel({
    required this.subject,
    required this.lectures,
    required this.onReorder,
    required this.onDeleteLecture,
    required this.onDeleteSubject,
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
                onPressed: () {}, // TODO: 태그 수정 화면으로 이동할지 여부
                child: const Text('태그 수정', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent.shade200, foregroundColor: Colors.white),
                onPressed: widget.onDeleteSubject,
                child: const Text('과목 삭제'),
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
                return Dismissible(
                  key: ValueKey(lec.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red.shade100,
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  onDismissed: (_) => widget.onDeleteLecture(lec),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: Text('${lec.weekLabel}  •  ${lec.title}'),
                    subtitle: const Text('썸네일 자리'),
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