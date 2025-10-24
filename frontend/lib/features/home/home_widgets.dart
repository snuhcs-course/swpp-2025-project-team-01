// 홈 전용 위젯: 필터/즐겨찾기 pill, 태그 칩, 과목 패널, 강의 카드
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/models.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/shared/widgets.dart';

const _panelRadius = 22.0;
const _panelShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 10,
  offset: Offset(0, 3),
);
const _pillShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// 빈 상태 메시지 위젯
class EmptyStateMessage extends StatelessWidget {
  const EmptyStateMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 공통 Pill 버튼 위젯 (FilterPill, FavoritePill의 베이스)
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.onTap,
    required this.active,
    required this.child,
  });

  final VoidCallback onTap;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color bg = active ? Colors.black87 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: const [_pillShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 필터 pill 버튼 위젯
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? Colors.white : Colors.black87;

    return _PillButton(
      onTap: onTap,
      active: active,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

/// 즐겨찾기 pill 버튼 위젯
class FavoritePill extends StatelessWidget {
  const FavoritePill({
    super.key,
    required this.active,
    required this.onTap,
    required this.label,
  });

  final bool active;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppHighlights h = context.highlights;
    final Color fg = active ? Colors.white : Colors.black87;
    final Color starColor = active ? h.important : Colors.black87;
    final IconData starIcon = active ? Icons.star : Icons.star_border;

    return _PillButton(
      onTap: onTap,
      active: active,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(starIcon, size: 18, color: starColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

/// 태그 칩 그리드 위젯
class TagChips extends StatelessWidget {
  const TagChips({
    super.key,
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final List<Tag> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(tags.length, (i) {
        final Tag t = tags[i];
        final bool isSel = selected.contains(t.id);
        return SelectableTagPill(
          tag: t,
          selected: isSel,
          onSelected: (_) => onToggle(t.id),
        );
      }),
    );
  }
}

/// 과목 패널 위젯 (접고 펼칠 수 있는 강의 목록 포함)
class SubjectPanel extends StatefulWidget {
  const SubjectPanel({
    super.key,
    required this.subject,
    required this.tags,
    required this.lectures,
    required this.onToggleFavorite,
    required this.onOpenLecture,
    this.onLectureUpdated,
  });

  final Subject subject;
  final List<Tag> tags;
  final List<HiveLecture> lectures;
  final VoidCallback onToggleFavorite;
  final ValueChanged<HiveLecture> onOpenLecture;
  final VoidCallback? onLectureUpdated;

  @override
  State<SubjectPanel> createState() => _SubjectPanelState();
}

class _SubjectPanelState extends State<SubjectPanel>
    with SingleTickerProviderStateMixin {
  late bool expanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // Repository에서 저장된 상태 로드
    expanded = HiveManager.instance.getSubjectExpandedState(widget.subject.id);

    final reduceMotion =
        HiveManager.instance.settings.accessibilityReduceMotion;
    final Duration duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

    _animationController = AnimationController(duration: duration, vsync: this);
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: reduceMotion ? Curves.linear : Curves.easeInOut,
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(_animationController);
    _animationController.value = expanded ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final bool reduceMotion =
        HiveManager.instance.settings.accessibilityReduceMotion;

    setState(() {
      expanded = !expanded;
    });

    // Hive에 상태 저장
    HiveManager.instance.setSubjectExpandedState(widget.subject.id, expanded);

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

  @override
  Widget build(BuildContext context) {
    final AppHighlights h = context.highlights;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        // 애니메이션 진행 중이거나 완전히 열린 상태일 때만 배경 표시
        final bool showBackground = _expandAnimation.value > 0;

        return Container(
          decoration: BoxDecoration(
            color: showBackground ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(_panelRadius),
            boxShadow: showBackground ? const [_panelShadow] : const [],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 검정 헤더 (태그 + ★ + 제목 + 화살표)
          SubjectPanelHeader(
            title: widget.subject.title,
            tags: widget.tags,
            expanded: expanded,
            onToggleExpanded: _toggleExpanded,
            favoriteIcon: widget.subject.favorite
                ? Icons.star
                : Icons.star_border,
            onToggleFavorite: widget.onToggleFavorite,
            favoriteIconColor: h.important,
          ),

          // 강의 그리드 (2열) - 애니메이션 적용
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.lectures
                      .map(
                        (lec) => SizedBox(
                          width:
                              (MediaQuery.of(context).size.width -
                                  32 -
                                  28 -
                                  12) /
                              2, // (화면 - 좌우패딩 - 카드패딩 - 간격) / 2
                          child: LectureCard(
                            lec: lec,
                            onTap: widget.onOpenLecture,
                            onUpdated: widget.onLectureUpdated,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 강의 카드 위젯 (PDF 썸네일 포함)
class LectureCard extends StatefulWidget {
  const LectureCard({
    super.key,
    required this.lec,
    required this.onTap,
    this.onUpdated,
  });

  final HiveLecture lec;
  final ValueChanged<HiveLecture> onTap;
  final VoidCallback? onUpdated;

  @override
  State<LectureCard> createState() => _LectureCardState();
}

class _LectureCardState extends State<LectureCard> {
  PdfDocument? _pdfDocument;
  PdfPage? _pdfPage;
  PdfPageImage? _cachedImage; // 렌더링된 이미지 캐싱
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void didUpdateWidget(LectureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 강의 내용이 변경되면 PDF 다시 로드
    if (oldWidget.lec.slidePath != widget.lec.slidePath) {
      _pdfPage?.close();
      _pdfDocument?.close();
      _pdfDocument = null;
      _pdfPage = null;
      _cachedImage = null;
      _isLoading = true;
      _error = null;
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    if (widget.lec.slidePath == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // assets 경로인지 파일 시스템 경로인지 확인
      final bool isAsset = widget.lec.slidePath!.startsWith('assets/');
      final PdfDocument document = isAsset
          ? await PdfDocument.openAsset(widget.lec.slidePath!)
          : await PdfDocument.openFile(widget.lec.slidePath!);
      final PdfPage page = await document.getPage(1);
      // 즉시 렌더링하여 캐싱
      final PdfPageImage? image = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      if (mounted) {
        setState(() {
          _pdfDocument = document;
          _pdfPage = page;
          _cachedImage = image;
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
      onLongPress: () => _showLectureDetailDialog(context),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.transparent,

          boxShadow: const [
            BoxShadow(
              color: Colors.transparent,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildThumbnail(),
              ),
              const SizedBox(height: 10),
              Text(
                widget.lec.weekLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                widget.lec.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(color: Colors.white, child: _buildThumbnailContent()),
    );
  }

  Widget _buildThumbnailContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          '오류: $_error',
          style: const TextStyle(color: Colors.red, fontSize: 10),
        ),
      );
    }

    if (_cachedImage != null) {
      // PDF의 비율 계산
      final double pdfAspectRatio = _pdfPage!.width / _pdfPage!.height;
      const double targetAspectRatio = 16 / 9;

      // 4:3 비율인 경우 (또는 16:9보다 세로로 긴 경우) contain으로 중앙 정렬
      // 16:9 비율인 경우 cover로 꽉 채우기
      final BoxFit fit = pdfAspectRatio < targetAspectRatio
          ? BoxFit
                .contain // 4:3 등 세로로 긴 경우 - 좌우 여백
          : BoxFit.cover; // 16:9 등 가로로 긴 경우 - 꽉 채우기

      return Image.memory(
        _cachedImage!.bytes,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return const Center(
      child: Text('thumbnail', style: TextStyle(color: Colors.black38)),
    );
  }

  Future<void> _showLectureDetailDialog(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => _LectureDetailDialog(lecture: widget.lec),
    );

    // 다이얼로그에서 변경사항이 있으면 부모에게 알림
    if (result == true) {
      widget.onUpdated?.call();
    }
  }
}

/// 강의 상세정보 편집 다이얼로그
class _LectureDetailDialog extends StatefulWidget {
  const _LectureDetailDialog({required this.lecture});
  final HiveLecture lecture;

  @override
  State<_LectureDetailDialog> createState() => _LectureDetailDialogState();
}

class _LectureDetailDialogState extends State<_LectureDetailDialog> {
  late TextEditingController _weekController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _weekController = TextEditingController(text: widget.lecture.weekLabel);
    _titleController = TextEditingController(text: widget.lecture.title);
  }

  @override
  void dispose() {
    _weekController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1D1D1D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Text(
          l10n.lectureDetails,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _weekController,
              decoration: InputDecoration(
                labelText: l10n.week,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.lectureTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.lectureLength,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDuration(widget.lecture.durationSec),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteLecture),
                      content: Text(
                        l10n.isKorean
                            ? '이 강의를 삭제하시겠습니까? 삭제한 강의는 복구할 수 없습니다.'
                            : 'Are you sure you want to delete this lecture? This action is irreversible.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.isKorean ? '삭제' : 'Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await HiveManager.instance.deleteLecture(widget.lecture.id);
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                icon: const Icon(Icons.delete),
                label: Text(l10n.deleteLecture),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final weekText = _weekController.text.trim();
            final titleText = _titleController.text.trim();

            if (weekText.isNotEmpty && titleText.isNotEmpty) {
              await HiveManager.instance.updateLectureMetadata(
                widget.lecture.id,
                weekLabel: weekText,
                title: titleText,
              );
            }

            if (context.mounted) {
              Navigator.pop(context, true); // true를 반환하여 새로고침 필요함을 알림
            }
          },
          child: Text(l10n.complete),
        ),
      ],
    );
  }
}
