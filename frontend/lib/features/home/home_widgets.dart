// 홈 전용 위젯: 필터/즐겨찾기 pill, 태그 칩, 과목 패널, 강의 카드
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../data/models.dart';
import '../../core/theme/color_scheme.dart';

const _black = Color(0xFF1D1D1D); // 패널 헤더 색(피그마)
const _panelRadius = 22.0;
const _panelShadow = BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3));

/// 필터 pill 버튼 위젯
class FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const FilterPill({super.key, required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.black87 : Colors.white;
    final fg = active ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 즐겨찾기 pill 버튼 위젯
class FavoritePill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const FavoritePill({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = context.highlights;
    final bg = active ? Colors.black87 : Colors.white;
    final fg = active ? Colors.white : Colors.black87;
    final starColor = active ? h.important : Colors.black87;
    final starIcon = active ? Icons.star : Icons.star_border;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(starIcon, size: 18, color: starColor),
                const SizedBox(width: 6),
                Text('즐겨찾기', style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 태그 칩 그리드 위젯
class TagChips extends StatelessWidget {
  final List<Tag> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const TagChips({super.key, required this.tags, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final presets = context.highlights.tagHighlights;
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(tags.length, (i) {
        final t = tags[i];
        final p = presets[i % presets.length];
        final isSel = selected.contains(t.id);
        return Material(
          shape: const StadiumBorder(),
          elevation: 1,
          child: FilterChip(
            showCheckmark: false,
            label: Text('#${t.name}'),
            selected: isSel,
            onSelected: (_) => onToggle(t.id),
            backgroundColor: const Color(0xFFE0E0E0),
            selectedColor: p.background,
            labelStyle: TextStyle(
              color: isSel ? p.foreground : Colors.black54,
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            labelPadding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }),
    );
  }
}

/// 과목 패널 위젯 (접고 펼칠 수 있는 강의 목록 포함)
class SubjectPanel extends StatefulWidget {
  final Subject subject;
  final List<Tag> tags;
  final List<Lecture> lectures;
  final VoidCallback onToggleFavorite;
  final ValueChanged<Lecture> onOpenLecture;

  const SubjectPanel({
    super.key,
    required this.subject,
    required this.tags,
    required this.lectures,
    required this.onToggleFavorite,
    required this.onOpenLecture,
  });

  @override
  State<SubjectPanel> createState() => _SubjectPanelState();
}

class _SubjectPanelState extends State<SubjectPanel> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final h = context.highlights;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_panelRadius),
        boxShadow: const [_panelShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // 검정 헤더 (태그 + ★ + 제목 + 화살표)
        Container(
          decoration: BoxDecoration(
            color: _black,
            borderRadius: expanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(_panelRadius),
                    topRight: Radius.circular(_panelRadius),
                  )
                : BorderRadius.circular(_panelRadius),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 라인
              Row(children: [
                IconButton(
                  icon: Icon(widget.subject.favorite ? Icons.star : Icons.star_border, color: h.important, size: 22),
                  onPressed: widget.onToggleFavorite,
                  tooltip: '즐겨찾기',
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    widget.subject.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white),
                  onPressed: () => setState(() => expanded = !expanded),
                ),
              ]),
              // 태그 라인
              if (widget.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 40),
                  child: Wrap(
                    spacing: 8,
                    children: _subjectTagChips(context, widget.tags),
                  ),
                ),
            ],
          ),
        ),

        // 강의 그리드 (2열)
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.lectures.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35,
              ),
              itemBuilder: (_, i) => LectureCard(lec: widget.lectures[i], onTap: widget.onOpenLecture),
            ),
          ),
      ]),
    );
  }

  List<Widget> _subjectTagChips(BuildContext context, List<Tag> tags) {
    final presets = context.highlights.tagHighlights;
    return List.generate(tags.length, (i) {
      final t = tags[i];
      final p = presets[i % presets.length];
      return Material(
        shape: const StadiumBorder(),
        elevation: 1,
        child: Chip(
          label: Text('#${t.name}'),
          backgroundColor: p.background,
          labelStyle: TextStyle(color: p.foreground, fontWeight: FontWeight.normal, fontSize: 14),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          labelPadding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    });
  }
}

/// 강의 카드 위젯 (PDF 썸네일 포함)
class LectureCard extends StatefulWidget {
  final Lecture lec;
  final ValueChanged<Lecture> onTap;
  const LectureCard({super.key, required this.lec, required this.onTap});

  @override
  State<LectureCard> createState() => _LectureCardState();
}

class _LectureCardState extends State<LectureCard> {
  PdfDocument? _pdfDocument;
  PdfPage? _pdfPage;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (widget.lec.slidesPath == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final document = await PdfDocument.openAsset(widget.lec.slidesPath!);
      final page = await document.getPage(1);
      if (mounted) {
        setState(() {
          _pdfDocument = document;
          _pdfPage = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfPage?.close();
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onTap(widget.lec),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(height: 10),
            Text(widget.lec.weekLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(widget.lec.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('오류: $_error', style: const TextStyle(color: Colors.red, fontSize: 10)));
    }

    if (_pdfPage != null) {
      return FutureBuilder<PdfPageImage?>(
        future: _pdfPage!.render(
          width: _pdfPage!.width * 2,
          height: _pdfPage!.height * 2,
          format: PdfPageImageFormat.png,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!.bytes,
              fit: BoxFit.contain,
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('렌더링 실패', style: const TextStyle(color: Colors.red, fontSize: 10)));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return const Center(child: Text('thumbnail', style: TextStyle(color: Colors.black38)));
  }
}