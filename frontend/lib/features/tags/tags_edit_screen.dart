import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

// 태그 색상 테마 세트
class TagColorTheme {
  final String name;
  final List<int> colors;

  const TagColorTheme(this.name, this.colors);

  static const List<TagColorTheme> themes = [
    TagColorTheme('파스텔', [
      0xFFFFDADA, 0xFFFFE4C4, 0xFFFFF4B3, 0xFFE8F5E9, 0xFFB3E5FC,
      0xFFE1BEE7, 0xFFF8BBD0, 0xFFFFCCBC, 0xFFD1C4E9, 0xFFC5E1A5,
      0xFFFFE082, 0xFFFFAB91, 0xFFCE93D8, 0xFFA5D6A7, 0xFFB39DDB,
    ]),
    TagColorTheme('비비드', [
      0xFFFF6B6B, 0xFFFFAA33, 0xFFFFEB3B, 0xFF66BB6A, 0xFF42A5F5,
      0xFF9C27B0, 0xFFEC407A, 0xFFFF7043, 0xFF7E57C2, 0xFF9CCC65,
      0xFFFDD835, 0xFFFF8A65, 0xFFAB47BC, 0xFF81C784, 0xFF8E24AA,
    ]),
    TagColorTheme('네온', [
      0xFFFF1744, 0xFFFF9100, 0xFFFFEA00, 0xFF00E676, 0xFF00B0FF,
      0xFFD500F9, 0xFFFF4081, 0xFFFF6E40, 0xFF651FFF, 0xFF76FF03,
      0xFFC6FF00, 0xFFFF3D00, 0xFFE040FB, 0xFF00E5FF, 0xFFAA00FF,
    ]),
    TagColorTheme('소프트', [
      0xFFEFDBD5, 0xFFF3E5DC, 0xFFFFF8DC, 0xFFE8F4EA, 0xFFE0F2F7,
      0xFFF3E5F5, 0xFFFCE4EC, 0xFFFBE9E7, 0xFFEDE7F6, 0xFFE7EED3,
      0xFFFFF9C4, 0xFFFFE0B2, 0xFFF1E1F5, 0xFFDCEDC8, 0xFFE1BEE7,
    ]),
    TagColorTheme('어스톤', [
      0xFFBCAAA4, 0xFFD7CCC8, 0xFFE6D7C3, 0xFFC5E1A5, 0xFFB0BEC5,
      0xFFCE93D8, 0xFFF48FB1, 0xFFFFAB91, 0xFFB39DDB, 0xFFA5D6A7,
      0xFFDCE775, 0xFFFFCC80, 0xFFBA68C8, 0xFF90CAF9, 0xFF9FA8DA,
    ]),
  ];

  static TagColorTheme getTheme(String name) {
    return themes.firstWhere((t) => t.name == name, orElse: () => themes[0]);
  }
}

/// Figma 2-3. Modifying Tags
/// - 상단: 태그 칩 그리드(+ 추가)
/// - 하단: 폼(이름, 색상 HEX, 불투명도) + 적용/취소
/// - 맨 아래: 휴지통 버튼
/// - 하단 고정 버튼: [수정 완료] [취소]
class TagsEditScreen extends StatefulWidget {
  const TagsEditScreen({super.key});
  @override
  State<TagsEditScreen> createState() => _TagsEditScreenState();
}

class _TagsEditScreenState extends State<TagsEditScreen> {
  final repo = Repo.instance;
  late List<Tag> _tags;
  late List<Tag> _originalTags;

  int _selected = 0;
  final _nameC = TextEditingController();
  String _currentTheme = '파스텔'; // 기본 테마
  late String _originalTheme; // 원본 테마 저장
  bool _isNewTag = false; // 새로 생성된 태그인지 추적

  @override
  void initState() {
    super.initState();
    _tags = List.of(repo.getTags());
    _originalTags = List.of(_tags); // 원본 저장
    _currentTheme = repo.getTagTheme(); // 저장된 테마 불러오기
    _originalTheme = _currentTheme; // 원본 테마 저장
    _assignColors(); // 초기 색상 할당
    if (_tags.isNotEmpty) _syncForm(0);
  }

  void _syncForm(int i) {
    setState(() {
      _selected = i;
      _isNewTag = false;
    });
    // setState 밖에서 TextEditingController 업데이트 (한글 입력 문제 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameC.text = _tags[i].name;
      }
    });
  }

  // 태그에 순서대로 고정 색상 할당
  void _assignColors() {
    final theme = TagColorTheme.getTheme(_currentTheme);
    for (int i = 0; i < _tags.length; i++) {
      final colorIndex = i % theme.colors.length;
      _tags[i] = Tag(
        id: _tags[i].id,
        name: _tags[i].name,
        color: theme.colors[colorIndex],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).editingTags)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // 테마 선택 섹션
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).colorTheme, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TagColorTheme.themes.map((theme) {
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
                              _applyThemeToAllTags();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 칩 그리드
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (int i = 0; i < _tags.length; i++)
                _buildTagChip(i),
              ActionChip(
                label: const Text('+', style: TextStyle(color: Colors.black)),
                onPressed: _addNewTag,
                elevation: 2,
                backgroundColor: Colors.white,
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 폼 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _nameC,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).tagName),
                  enableIMEPersonalizedLearning: false,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton(onPressed: _apply, child: Text(AppLocalizations.of(context).apply))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: _cancel, child: Text(AppLocalizations.of(context).cancel))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: IconButton(
              iconSize: 40,
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelected,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        primaryLabel: AppLocalizations.of(context).editComplete,
        secondaryLabel: AppLocalizations.of(context).cancel,
        onPrimary: () async {
          await repo.saveTagTheme(_currentTheme); // 테마 저장
          await repo.saveTags(_tags); // 태그 저장
          if (context.mounted) {
            // 홈으로 완전 복귀 (홈 화면 재생성으로 태그 업데이트 반영)
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
        onSecondary: () async {
          // 취소: 원본 테마로 복구 (변경사항 저장 안 함)
          await repo.saveTagTheme(_originalTheme);
          if (context.mounted) {
            // 홈으로 완전 복귀 (변경사항 없이)
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
      ),
    );
  }

  // 태그 칩 빌더 (모든 태그 색상 표시, 선택 시 체크 표시와 그림자로 구분)
  Widget _buildTagChip(int i) {
    final isSelected = _selected == i;
    final tagColor = Color(_tags[i].color);

    return ChoiceChip(
      label: Text(
        '#${_tags[i].name}',
        style: const TextStyle(color: Colors.black),
      ),
      selected: isSelected,
      onSelected: (_) => _syncForm(i),
      backgroundColor: tagColor,
      selectedColor: tagColor,
      elevation: isSelected ? 4 : 2,
      side: BorderSide.none,
      showCheckmark: true,
    );
  }

  // 테마를 모든 태그에 적용 (순서대로 고정 색상)
  void _applyThemeToAllTags() async {
    await repo.saveTagTheme(_currentTheme); // 테마 저장
    setState(() {
      _assignColors();
    });
  }

  // 새 태그 추가 (이름 중복 방지, 테마의 다음 색상 할당)
  void _addNewTag() {
    // 15개 제한 체크
    if (_tags.length >= 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('태그는 최대 15개까지 생성할 수 있습니다.')),
      );
      return;
    }

    String newName = '새 태그';
    int counter = 1;

    while (_tags.any((tag) => tag.name == newName)) {
      newName = '새 태그 ($counter)';
      counter++;
    }

    final theme = TagColorTheme.getTheme(_currentTheme);
    final colorIndex = _tags.length % theme.colors.length;

    setState(() {
      _tags.add(Tag(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        name: newName,
        color: theme.colors[colorIndex],
      ));
      _selected = _tags.length - 1;
      _isNewTag = true;
    });

    // setState 밖에서 TextEditingController 업데이트 (한글 입력 문제 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameC.clear(); // 새 태그 생성 직후에만 입력창 비우기
      }
    });
  }

  // 적용: 이름 중복 체크 후 태그 수정
  void _apply() {
    final newName = _nameC.text.trim();

    // 빈 이름 체크
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('태그 이름을 입력해주세요.')),
      );
      return;
    }

    // 이름 중복 체크 (현재 선택된 태그 제외)
    for (int i = 0; i < _tags.length; i++) {
      if (i != _selected && _tags[i].name == newName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 사용 중인 이름입니다. 다른 이름을 입력해주세요.')),
        );
        return;
      }
    }

    setState(() {
      _tags[_selected] = Tag(
        id: _tags[_selected].id,
        name: newName,
        color: _tags[_selected].color,
      );
      _isNewTag = false;
    });
  }

  // 취소: 입력 필드 초기화
  void _cancel() {
    setState(() {
      _nameC.clear();
    });
  }

  void _deleteSelected() async {
    if (_tags.isEmpty) return;

    // 삭제하려는 태그를 사용 중인 과목이 있는지 확인
    final tagToDelete = _tags[_selected];
    final subjects = repo.getSubjects();
    final usingSubjects = subjects.where((s) => s.tagIds.contains(tagToDelete.id)).toList();

    if (usingSubjects.isNotEmpty) {
      // 경고 다이얼로그 표시
      final shouldDelete = await _showDeleteWarning(context, tagToDelete.name, usingSubjects);
      if (shouldDelete != true) return;
    }

    setState(() {
      _tags.removeAt(_selected);
      _assignColors(); // 삭제 후 색상 재할당
      _isNewTag = false;
      if (_tags.isEmpty) return;
      _syncForm((_selected - 1).clamp(0, _tags.length - 1));
    });
  }

  Future<bool?> _showDeleteWarning(BuildContext context, String tagName, List<Subject> usingSubjects) {
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
}

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