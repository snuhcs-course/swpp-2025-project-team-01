import 'package:flutter/material.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/shared/widgets.dart';

const _editPanelRadius = 22.0;
const _editPanelShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 10,
  offset: Offset(0, 3),
);

/// 과목 추가 다이얼로그 위젯
class CreateSubjectDialog extends StatefulWidget {
  const CreateSubjectDialog({super.key, required this.allTags});

  final List<HiveTag> allTags;

  @override
  State<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<CreateSubjectDialog> {
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(AppLocalizations.of(context).addSubject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.subjectName,
              hintText: l10n.isKorean
                  ? '예) 소프트웨어 개발의 원리와 실습'
                  : 'ex) Software Development Principles and Practice',
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
class SubjectEditDialog extends StatefulWidget {
  const SubjectEditDialog({
    super.key,
    required this.subject,
    required this.initialTagIds,
    required this.allTags,
  });

  final HiveSubject subject;
  final List<String> initialTagIds;
  final List<HiveTag> allTags;

  @override
  State<SubjectEditDialog> createState() => _SubjectEditDialogState();
}

class _SubjectEditDialogState extends State<SubjectEditDialog> {
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editSubjects),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== 과목 이름 입력 ==========
            Text(
              l10n.subjectName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l10n.isKorean
                    ? '예) 소프트웨어 개발의 원리와 실습'
                    : 'ex) Software Development Principles and Practice',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.editTags2,
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final newTitle = _nameController.text.trim();
            if (newTitle.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.pleaseEnterSubjectName)),
              );
              return;
            }
            Navigator.pop(context, {
              'action': 'save',
              'title': newTitle,
              'tagIds': _selectedTagIds.toList(),
            });
          },
          child: Text(l10n.ok),
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
class SubjectEditPanel extends StatefulWidget {
  const SubjectEditPanel({
    super.key,
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
  final HiveSubject subject;
  final String? displayTitle;
  final bool isInitiallyExpanded;
  final List<HiveLecture> lectures;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onExpansionChanged;

  @override
  State<SubjectEditPanel> createState() => _SubjectEditPanelState();
}

class _SubjectEditPanelState extends State<SubjectEditPanel>
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
