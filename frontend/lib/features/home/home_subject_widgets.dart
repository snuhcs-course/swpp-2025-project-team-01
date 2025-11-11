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
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AlertDialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      titlePadding: EdgeInsets.zero,
      title: DialogHeaderTitle(title: AppLocalizations.of(context).addSubject),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.7 - keyboardHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
        ),
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
    _tagNameController.dispose();
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
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Center(
            child: Text(
              l10n.warning,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ),
        content: Text(
          l10n.deleteSubjectWarning,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        contentPadding: const EdgeInsets.all(32),
        actionsPadding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        actions: [
          Row(
            children: [
              // "예" 버튼
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final manager = HiveManager.instance;
                    manager.deleteSubject(widget.subject.id);
                    Navigator.pop(context, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.yes, style: theme.textTheme.titleMedium),
                ),
              ),
              const SizedBox(width: 12),
              // "아니오" 버튼
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.no, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
        ],
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
      setState(() {
        _isCreatingTag = false;
      });
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
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AlertDialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      titlePadding: EdgeInsets.zero,
      title: DialogHeaderTitle(title: l10n.editSubjects),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.7 - keyboardHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== 과목 이름 입력 ==========
              Text(
                l10n.subjectName,
                style: Theme.of(context).textTheme.titleMedium,
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...widget.allTags.map((tag) {
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
                  }),
                  // 태그 추가 버튼
                  ActionChip(
                    label: Text(
                      '+',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                    onPressed: _addNewTag,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    elevation: Theme.of(context).chipTheme.elevation ?? 2,
                    side: Theme.of(context).chipTheme.side,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isCreatingTag)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.isKorean ? '태그 추가' : 'Add Tag',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagNameController,
                              decoration: InputDecoration(
                                hintText: l10n.newTag,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  12,
                                  10,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                              enableIMEPersonalizedLearning: false,
                              autofocus: true,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                              } else {
                                // Complete the future that _addNewTag() is awaiting
                                _tagCompleter?.complete(newName);
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            child: Text(l10n.isKorean ? '적용' : 'Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_isCreatingTag) const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // 하단 버튼: 삭제 / 완료
        Row(
          children: [
            // 삭제 버튼 (왼쪽)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final result = await showDeleteConfirmationDialog(
                    widget.subject,
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: Text(l10n.isKorean ? '삭제' : 'Delete'),
              ),
            ),
            const SizedBox(width: 12),
            // 완료 버튼 (오른쪽)
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                  Navigator.pop(context, true);
                },
                child: Text(l10n.complete),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
