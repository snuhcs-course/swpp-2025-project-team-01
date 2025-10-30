import 'package:flutter/material.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/shared/widgets.dart';

/// 태그 수정 화면 (Figma 2-3. Modifying Tags)
///
/// 태그의 생성, 수정, 삭제 및 색상 테마 관리 기능을 제공합니다.
///
/// 주요 기능:
/// - 색상 테마 선택 (5가지 테마 중 선택)
/// - 태그 추가/수정/삭제 (최대 15개)
/// - 태그 이름 변경
/// - 태그를 사용 중인 과목 확인 후 삭제
///
/// UI 구조:
/// - 색상 테마 선택 카드
/// - 태그 칩 그리드 (기존 태그 + 추가 버튼)
/// - 태그 이름 편집 폼 (이름 입력 + 적용/취소)
/// - 태그 삭제 버튼
class TagsEditScreen extends StatefulWidget {
  const TagsEditScreen({super.key});

  @override
  State<TagsEditScreen> createState() => _TagsEditScreenState();
}

class _TagsEditScreenState extends State<TagsEditScreen> {
  // 데이터 저장소
  final _manager = HiveManager.instance;

  // 태그 목록 (작업 중인 데이터)
  late List<Tag> _tags;

  // 선택된 태그 인덱스
  int _selected = 0;

  // 태그 이름 입력 컨트롤러
  final _nameC = TextEditingController();

  // 현재 선택된 색상 테마
  String _currentTheme = '봄';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  /// 초기 데이터 로드
  ///
  /// 저장소에서 태그 목록과 테마를 불러오고 색상을 할당합니다.
  void _loadData() {
    // HiveTag → Tag 변환
    _tags = _manager.getTags().map((ht) => ht.toTag()).toList();
    _currentTheme = _manager.settings.tagColorTheme;
    _assignColors();

    if (_tags.isNotEmpty) {
      _syncForm(0);
    }
  }

  /// 폼 데이터와 선택된 태그 동기화
  ///
  /// 태그를 선택하면 해당 태그의 이름을 입력 필드에 표시합니다.
  /// 한글 입력 문제 방지를 위해 setState 외부에서 TextEditingController를 업데이트합니다.
  void _syncForm(int index) {
    setState(() {
      _selected = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameC.text = _tags[index].name;
      }
    });
  }

  /// 선택된 테마에 따라 모든 태그에 색상 할당
  ///
  /// 각 태그는 테마의 색상 배열에서 순환하며 색상을 부여받습니다.
  /// 예: 15개 색상 테마에서 16번째 태그는 첫 번째 색상을 받습니다.
  void _assignColors() {
    final theme = getTagColorTheme(_currentTheme);
    final newTags = <Tag>[];

    for (int i = 0; i < _tags.length; i++) {
      final colorIndex = i % theme.colors.length;
      final expectedColor = theme.colors[colorIndex];

      // 이미 올바른 색상이면 객체 재사용
      if (_tags[i].color == expectedColor) {
        newTags.add(_tags[i]);
      } else {
        newTags.add(
          Tag(id: _tags[i].id, name: _tags[i].name, color: expectedColor),
        );
      }
    }

    _tags = newTags;
  }

  /// 선택된 테마를 모든 태그에 적용
  ///
  /// 테마 변경 시 즉시 저장하고 모든 태그의 색상을 재할당합니다.
  Future<void> _applyThemeToAllTags() async {
    await _manager.updateTagColorTheme(_currentTheme);
    setState(() {
      _assignColors();
    });
  }

  /// 뒤로가기 시 변경사항 저장
  Future<bool> _onWillPop() async {
    await _manager.updateTagColorTheme(_currentTheme);
    // Tag → HiveTag 변환
    final hiveTags = _tags.map((t) => t.toHiveTag()).toList();
    await _manager.saveTags(hiveTags);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).editingTags)),
        backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildThemeSelector(context),
            const SizedBox(height: 16),
            _buildTagChips(),
            const SizedBox(height: 16),
            _buildEditForm(context),
            const SizedBox(height: 24),
            _buildDeleteButton(context),
          ],
        ),
      ),
    );
  }

  /// 테마 선택 카드 빌드
  Widget _buildThemeSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).colorTheme,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tagColorThemes.map((TagColorTheme theme) {
                return ChoiceChip(
                  label: Text(
                    AppLocalizations.of(context).getThemeName(theme.name),
                    style: const TextStyle(color: Colors.black),
                  ),
                  selected: _currentTheme == theme.name,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentTheme = theme.name;
                      });
                      _applyThemeToAllTags();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 태그 칩 그리드 빌드
  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 기존 태그 칩들
        for (int i = 0; i < _tags.length; i++) _buildTagChip(i),
        // 새 태그 추가 버튼
        ActionChip(
          label: const Text('+', style: TextStyle(color: Colors.black)),
          onPressed: _addNewTag,
          elevation: 2,
          backgroundColor: Colors.white,
          side: BorderSide.none,
        ),
      ],
    );
  }

  /// 개별 태그 칩 빌드
  ///
  /// 각 태그를 칩 형태로 표시하며, 선택 시 체크마크와 그림자로 구분합니다.
  Widget _buildTagChip(int index) {
    final isSelected = _selected == index;

    return SelectableTagPill(
      tag: _tags[index],
      selected: isSelected,
      onSelected: (_) => _syncForm(index),
    );
  }

  /// 태그 이름 편집 폼 빌드
  Widget _buildEditForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameC,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).tagName,
              ),
              enableIMEPersonalizedLearning: false,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _applyNameChange,
                    child: Text(AppLocalizations.of(context).apply),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelNameChange,
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 태그 삭제 버튼 빌드
  Widget _buildDeleteButton(BuildContext context) {
    if (_tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _deleteSelectedTag,
          icon: const Icon(Icons.delete),
          label: Text(AppLocalizations.of(context).deleteTag),
        ),
      ),
    );
  }

  /// 새 태그 추가
  ///
  /// 중복되지 않는 이름으로 새 태그를 생성하고 현재 테마의 다음 색상을 할당합니다.
  /// 최대 15개까지만 생성 가능합니다.
  void _addNewTag() {
    // 최대 개수 제한 체크
    if (_tags.length >= 15) {
      _showSnackBar(AppLocalizations.of(context).maxTagsReached);
      return;
    }

    // 중복되지 않는 이름 생성
    String newName = '새 태그';
    int counter = 1;
    while (_tags.any((tag) => tag.name == newName)) {
      newName = '새 태그 ($counter)';
      counter++;
    }

    // 현재 테마에서 다음 색상 할당
    final theme = getTagColorTheme(_currentTheme);
    final colorIndex = _tags.length % theme.colors.length;

    setState(() {
      _tags.add(
        Tag(
          id: 'new_${DateTime.now().millisecondsSinceEpoch}',
          name: newName,
          color: theme.colors[colorIndex],
        ),
      );
      _selected = _tags.length - 1;
    });

    // 입력창 초기화 (한글 입력 문제 방지를 위해 프레임 이후 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameC.clear();
      }
    });
  }

  /// 태그 이름 변경 적용
  ///
  /// 입력된 이름의 유효성을 검사하고 중복이 없으면 태그를 업데이트합니다.
  void _applyNameChange() {
    final newName = _nameC.text.trim();

    // 빈 이름 검증
    if (newName.isEmpty) {
      _showSnackBar(AppLocalizations.of(context).pleaseEnterTagName);
      return;
    }

    // 중복 이름 검증 (현재 선택된 태그는 제외)
    if (_isDuplicateName(newName)) {
      _showSnackBar(AppLocalizations.of(context).duplicateTagName);
      return;
    }

    // 태그 이름 업데이트
    setState(() {
      _tags[_selected] = Tag(
        id: _tags[_selected].id,
        name: newName,
        color: _tags[_selected].color,
      );
    });
  }

  /// 태그 이름 중복 검사
  bool _isDuplicateName(String name) {
    for (int i = 0; i < _tags.length; i++) {
      if (i != _selected && _tags[i].name == name) {
        return true;
      }
    }
    return false;
  }

  /// 태그 이름 변경 취소
  ///
  /// 입력 필드를 현재 선택된 태그의 이름으로 되돌립니다.
  void _cancelNameChange() {
    if (_tags.isEmpty) {
      return;
    }

    // 한글 입력 문제 방지를 위해 프레임 이후 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameC.text = _tags[_selected].name;
      }
    });
  }

  /// 선택된 태그 삭제
  ///
  /// 태그가 과목에서 사용 중이면 경고 다이얼로그를 표시합니다.
  /// 삭제 후에는 색상을 재할당하고 이전 태그를 선택합니다.
  Future<void> _deleteSelectedTag() async {
    if (_tags.isEmpty) {
      return;
    }

    // 삭제하려는 태그를 사용 중인 과목 확인
    final tagToDelete = _tags[_selected];
    final subjects = _manager
        .getSubjects()
        .map((hs) => hs.toSubject())
        .toList();
    final usingSubjects = subjects
        .where((s) => s.tagIds.contains(tagToDelete.id))
        .toList();

    // 사용 중인 과목이 있으면 경고 다이얼로그 표시
    if (usingSubjects.isNotEmpty) {
      final shouldDelete = await _showDeleteWarningDialog(
        context,
        tagToDelete.name,
        usingSubjects,
      );
      if (shouldDelete != true) {
        return;
      }
    }

    // 태그 삭제 및 색상 재할당
    setState(() {
      _tags.removeAt(_selected);
      _assignColors();

      if (_tags.isEmpty) {
        return;
      }

      // 이전 태그 선택 (범위 내로 제한)
      final newIndex = (_selected - 1).clamp(0, _tags.length - 1);
      _selected = newIndex;
    });

    // 프레임 이후 폼 동기화
    if (_tags.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nameC.text = _tags[_selected].name;
        }
      });
    }
  }

  /// 스낵바 표시 헬퍼 메서드
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 태그 삭제 경고 다이얼로그
  ///
  /// 태그를 사용 중인 과목 목록을 표시하고 삭제 여부를 확인합니다.
  ///
  /// 반환값: true(삭제 확인), false(취소), null(다이얼로그 닫기)
  Future<bool?> _showDeleteWarningDialog(
    BuildContext context,
    String tagName,
    List<Subject> usingSubjects,
  ) {
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
              _buildDialogHeader(),
              _buildDialogBody(tagName, usingSubjects),
            ],
          ),
        ),
      ),
    );
  }

  /// 다이얼로그 헤더 빌드
  Widget _buildDialogHeader() {
    return Container(
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
    );
  }

  /// 다이얼로그 본문 빌드
  Widget _buildDialogBody(String tagName, List<Subject> usingSubjects) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8E8),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            '태그 "#$tagName"는\n다음 과목에서 사용 중입니다:\n\n${usingSubjects.map((s) => s.title).join('\n')}\n\n삭제하시겠습니까?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildConfirmButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildCancelButton()),
            ],
          ),
        ],
      ),
    );
  }

  /// 다이얼로그 확인 버튼
  Widget _buildConfirmButton() {
    return Container(
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
    );
  }

  /// 다이얼로그 취소 버튼
  Widget _buildCancelButton() {
    return Container(
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
    );
  }
}
