import 'dart:async';

import 'package:flutter/material.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/shared/widgets.dart';

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
      titlePadding: EdgeInsets.zero,
      title: DialogHeaderTitle(title: AppLocalizations.of(context).addSubject),
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
  late TextEditingController _tagNameController;
  late TextEditingController _nameController;
  late Set<String> _selectedTagIds;
  Completer<String?>? _tagCompleter;
  bool _isCreatingTag = false;

  @override
  void initState() {
    super.initState();
    _tagNameController = TextEditingController();
    _nameController = TextEditingController(text: widget.subject.title);
    _selectedTagIds = Set<String>.from(widget.initialTagIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> showDeleteConfirmationDialog(HiveSubject subject) {
    final l10n = AppLocalizations.of(context);
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
                child: Center(
                  child: Text(
                    l10n.warning,
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
                    Text(
                      l10n.deleteSubjectWarning,
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
                              onPressed: () async {
                                final manager = HiveManager.instance;
                                manager.deleteSubject(widget.subject.id);
                                Navigator.pop(context, true);
                              },
                              child: Text(
                                l10n.yes,
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
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: Text(
                                l10n.no,
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

  Future<void> _addNewTag() async {
    final l10n = AppLocalizations.of(context);
    final manager = HiveManager.instance;
    final existingTags = manager.getTags();

    // Avoid reentry
    if (_isCreatingTag) {
      return;
    }
    setState(() {
      _isCreatingTag = true;
    });

    // 최대 개수 제한 체크
    if (existingTags.length >= 15) {
      _showSnackBar(l10n.maxTagsReached);
      return;
    }

    // Create a completer to wait until user presses OK
    _tagCompleter = Completer<String?>();

    final newName = await _tagCompleter!.future;
    // User canceled
    if (newName == null) {
      setState(() {
        _isCreatingTag = false;
      });
      return;
    }

    // 현재 테마에서 다음 색상 할당
    final theme = getTagColorTheme(manager.settings.tagColorTheme);
    final colorIndex = existingTags.length % theme.colors.length;

    setState(() {
      existingTags.add(
        HiveTag(
          id: 'new_${DateTime.now().millisecondsSinceEpoch}',
          name: newName,
          color: theme.colors[colorIndex],
        ),
      );
      manager.saveTags(existingTags);
    });

    setState(() {
      _isCreatingTag = false;
    });

    // 입력창 초기화 (한글 입력 문제 방지를 위해 프레임 이후 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tagNameController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: DialogHeaderTitle(title: l10n.editSubjects),
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
            ActionChip(
              label: const Text('+', style: TextStyle(color: Colors.black)),
              onPressed: _addNewTag,
              elevation: 2,
              backgroundColor: Colors.white,
              side: BorderSide.none,
            ),
            const SizedBox(height: 10),
            if (_isCreatingTag)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagNameController,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: l10n.tagName,
                        hintText: l10n.newTag,
                        border: const OutlineInputBorder(),
                      ),
                      enableIMEPersonalizedLearning: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      final manager = HiveManager.instance;
                      final newTitle = _tagNameController.text.trim();
                      String newName = newTitle.isEmpty
                          ? l10n.newTag
                          : newTitle;
                      if (newName == l10n.newTag) {
                        int counter = 1;
                        while (manager.getTags().any(
                          (tag) => tag.name == newName,
                        )) {
                          newName = '${l10n.newTag} ($counter)';
                          counter++;
                        }
                      }
                      // Avoid duplicates
                      if (manager
                          .getTags()
                          .map((t) => t.name)
                          .contains(newName)) {
                        _showSnackBar(l10n.duplicateTagName);
                        _tagCompleter?.complete(null);
                      }
                      // Complete the future that _addNewTag() is awaiting
                      _tagCompleter?.complete(newName);
                    },
                    child: Text(l10n.nameApply),
                  ),
                ],
              ),
            const SizedBox(height: 10),

            // ========== 과목 삭제 버튼 ==========
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 231, 76, 60),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final result = await showDeleteConfirmationDialog(
                      widget.subject,
                    );
                    if (result == true && context.mounted) {
                      Navigator.pop(context);
                    }
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
              _showSnackBar(l10n.pleaseEnterSubjectName);
              return;
            }
            final manager = HiveManager.instance;
            manager.updateSubject(
              widget.subject.id,
              title: newTitle,
              tagIds: _selectedTagIds.toList(),
            );
            Navigator.pop(context, null);
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
