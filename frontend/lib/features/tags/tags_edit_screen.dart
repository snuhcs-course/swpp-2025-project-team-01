import 'package:flutter/material.dart';
import '../../data/repository.dart';
import '../../data/models.dart';

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

  int _selected = 0;
  final _nameC = TextEditingController();
  final _hexC = TextEditingController(text: 'EFF0A4');
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _tags = List.of(repo.getTags());
    if (_tags.isNotEmpty) _syncForm(0);
  }

  void _syncForm(int i) {
    _selected = i;
    _nameC.text = _tags[i].name;
    _hexC.text = _tags[i].color.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase(); // ARGB→RGB
    _opacity = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('태그 수정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // 칩 그리드
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (int i = 0; i < _tags.length; i++)
                ChoiceChip(
                  label: Text('#${_tags[i].name}'),
                  selected: _selected == i,
                  onSelected: (_) => setState(() => _syncForm(i)),
                  selectedColor: Color(_tags[i].color).withOpacity(.9),
                ),
              ActionChip(
                label: const Text('+'),
                onPressed: () => setState(() {
                  _tags.add(const Tag(id: 'new', name: '새 태그', color: 0xFFEFF0A4));
                  _syncForm(_tags.length - 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 폼 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('태그 수정', style: TextStyle(fontWeight: FontWeight.w700)),
                const Divider(),
                TextField(controller: _nameC, decoration: const InputDecoration(labelText: '이름')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _hexC,
                      decoration: const InputDecoration(labelText: '색상 (HEX, 예: EFF0A4)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 56, height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _parseHex(_hexC.text, _opacity),
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('불투명도'),
                  Expanded(
                    child: Slider(
                      value: _opacity, min: 0, max: 1, divisions: 10,
                      onChanged: (v) => setState(() => _opacity = v),
                    ),
                  ),
                  Text('${(_opacity * 100).round()} %'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton(onPressed: _apply, child: const Text('적용'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: _cancel, child: const Text('취소'))),
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
        primaryLabel: '수정 완료',
        secondaryLabel: '취소',
        onPrimary: () {
          // TODO: repo 반영
          Navigator.pop(context);
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  void _apply() {
    setState(() {
      final rgb = _parseHex(_hexC.text, 1.0);
      _tags[_selected] = Tag(
        id: _tags[_selected].id,
        name: _nameC.text,
        color: (0xFF << 24) | (rgb.value & 0x00FFFFFF),
      );
    });
  }

  void _cancel() => _syncForm(_selected);

  void _deleteSelected() {
    if (_tags.isEmpty) return;
    setState(() {
      _tags.removeAt(_selected);
      if (_tags.isEmpty) return;
      _syncForm((_selected - 1).clamp(0, _tags.length - 1));
    });
  }

  Color _parseHex(String hex, double opacity) {
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    final a = (opacity * 255).round() & 0xFF;
    return Color((a << 24) | value);
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