// 자주 쓰는 작은 위젯들
import 'package:flutter/material.dart';
import 'package:re_view/data/models.dart';

/// 전체 너비를 차지하는 주요 버튼 위젯
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// 빈 상태를 표시하는 위젯
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

/// 로딩 중임을 표시하는 오버레이 위젯
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message = 'Processing...'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// 태그를 칩 형태로 표시하는 공통 위젯 (비선택형)
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.tag,
    this.labelPrefix = '#',
    this.label,
  });

  final Tag tag;
  final String? label;
  final String labelPrefix;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(tag.color);
    return Chip(
      label: Text(
        label ?? '$labelPrefix${tag.name}',
        style: const TextStyle(color: Colors.black),
      ),
      backgroundColor: color,
      elevation: 2,
      side: const BorderSide(color: Color(0x1F000000), width: 0.5),
    );
  }
}

/// 태그 선택에 사용되는 공통 칩 위젯 (ChoiceChip 기반)
class SelectableTagPill extends StatelessWidget {
  const SelectableTagPill({
    super.key,
    required this.tag,
    required this.selected,
    required this.onSelected,
    this.showCheckmark = true,
    this.labelPrefix = '#',
    this.label,
  });

  final Tag tag;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool showCheckmark;
  final String? label;
  final String labelPrefix;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(tag.color);
    return ChoiceChip(
      label: Text(
        label ?? '$labelPrefix${tag.name}',
        style: const TextStyle(color: Colors.black),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: color,
      selectedColor: color,
      elevation: selected ? 4 : 2,
      side: const BorderSide(color: Color(0x1F000000), width: 0.5),
      showCheckmark: showCheckmark,
    );
  }
}

/// 과목 패널 헤더 위젯 (홈 화면 & 과목 수정 화면 공통)
///
/// 검은 배경의 헤더로 과목 제목, 태그, 펼침/접기 버튼을 표시합니다.
class SubjectPanelHeader extends StatelessWidget {
  const SubjectPanelHeader({
    super.key,
    required this.title,
    required this.tags,
    required this.expanded,
    required this.onToggleExpanded,
    this.panelRadius = 22.0,
    this.collapsedRadius,
    this.expandedRadius,
    this.favoriteIcon,
    this.onToggleFavorite,
    this.favoriteIconColor,
    this.onLongPress,
    this.titleEndPadding = 0,
  });

  final String title;
  final List<Tag> tags;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final double panelRadius;
  final BorderRadius? collapsedRadius;
  final BorderRadius? expandedRadius;
  final IconData? favoriteIcon;
  final VoidCallback? onToggleFavorite;
  final Color? favoriteIconColor;
  final VoidCallback? onLongPress;
  final double titleEndPadding;

  @override
  Widget build(BuildContext context) {
    const Color headerColor = Color(0xFF1D1D1D);
    final BorderRadius resolvedCollapsedRadius =
        collapsedRadius ?? BorderRadius.circular(panelRadius);
    final BorderRadius resolvedExpandedRadius =
        expandedRadius ??
        BorderRadius.only(
          topLeft: Radius.circular(panelRadius),
          topRight: Radius.circular(panelRadius),
        );
    final BorderRadius resolvedRadius = expanded
        ? resolvedExpandedRadius
        : resolvedCollapsedRadius;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: resolvedRadius,
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 라인
            Row(
              children: [
                // 즐겨찾기 아이콘 (선택사항)
                if (favoriteIcon != null)
                  IconButton(
                    icon: Icon(
                      favoriteIcon,
                      color: favoriteIconColor ?? Colors.white,
                      size: 22,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: '즐겨찾기',
                  ),
                if (favoriteIcon != null) const SizedBox(width: 2),
                // 제목
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: titleEndPadding),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // 펼침/접기 버튼
                IconButton(
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Colors.white,
                  ),
                  onPressed: onToggleExpanded,
                ),
              ],
            ),
            // 태그 라인
            if (tags.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: favoriteIcon != null ? 40 : 0,
                ),
                child: Wrap(
                  spacing: 8,
                  children: tags.map((tag) {
                    return TagPill(tag: tag);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
