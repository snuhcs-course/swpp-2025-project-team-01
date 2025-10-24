// 자주 쓰는 작은 위젯들
import 'package:flutter/material.dart';
import 'package:re_view/core/lecture_loading_service.dart';
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

/// 렉처 생성 로딩을 화면 하단에 표시하는 위젯 (둥근 카드 스타일)
class LectureLoadingBar extends StatelessWidget {
  const LectureLoadingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LectureLoadingService.instance,
      builder: (context, _) {
        final service = LectureLoadingService.instance;
        if (!service.isLoading) {
          return const SizedBox.shrink();
        }

        final Widget child;
        if (service.isCollapsed) {
          child = _CollapsedBubbleOverlay(
            key: const ValueKey('collapsed-bubble'),
            service: service,
          );
        } else {
          child = _ExpandedLoadingOverlay(
            key: const ValueKey('expanded-bar'),
            service: service,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          child: child,
        );
      },
    );
  }
}

/// 둥근모서리 + 그림자 카드 컨테이너
class _ExpandedLoadingOverlay extends StatelessWidget {
  const _ExpandedLoadingOverlay({super.key, required this.service});

  final LectureLoadingService service;

  @override
  Widget build(BuildContext context) {
    final isCompleted = service.progress >= 1.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond.dx;
            if (velocity.abs() < 200) {
              return;
            }
            service.collapseToBubble(alignRight: velocity > 0);
          },
          child: _RoundedCard(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isCompleted
                  ? const _CompletedView(key: ValueKey('completed'))
                  : _LoadingView(
                      key: const ValueKey('loading'),
                      title: service.lectureTitle,
                      message: service.message,
                      progress: service.progress.clamp(0.0, 1.0),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedBubbleOverlay extends StatelessWidget {
  const _CollapsedBubbleOverlay({super.key, required this.service});

  final LectureLoadingService service;

  @override
  Widget build(BuildContext context) {
    const double bubbleSize = 88;
    const double bottomInset = 24;
    final progress = service.progress.clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned(
          bottom: bottomInset,
          left: service.bubbleOnRight ? null : 24,
          right: service.bubbleOnRight ? 24 : null,
          child: SafeArea(
            top: false,
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: service.expandFromBubble,
                child: SizedBox(
                  width: bubbleSize,
                  height: bubbleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: bubbleSize,
                        height: bubbleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: bubbleSize,
                        height: bubbleSize,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFF7FAB0),
                          ),
                        ),
                      ),
                      ClipOval(
                        child: Container(
                          width: bubbleSize - 18,
                          height: bubbleSize - 18,
                          color: Colors.black.withValues(alpha: 0.2),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              'assets/images/loading_character.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundedCard extends StatelessWidget {
  const _RoundedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // 불투명한 어두운 배경
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// 로딩 중 화면
class _LoadingView extends StatelessWidget {
  const _LoadingView({
    super.key,
    required this.title,
    required this.message,
    required this.progress,
  });

  final String title;
  final String message;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/loading_background.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽 캐릭터 일러스트
          _CharacterBlock(),
          const SizedBox(width: 16),

          // 오른쪽 텍스트/프로그레스
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 줄: 제목 + 취소 버튼
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '강의 생성 중…',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF7FAB0),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        LectureLoadingService.instance.cancelLoading();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade200,
                        backgroundColor: Colors.grey.shade800.withValues(
                          alpha: 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 수업명 라벨 + 값
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '강의명: ',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: title.isEmpty ? '제목 없음' : title,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // 진행도 바 (알약형 + 안쪽에 퍼센트)
                _FancyProgressBar(value: progress, height: 36),

                const SizedBox(height: 4),

                // 하단 진행 메시지
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 완료 화면 (요청: 배경이미지 위주, 카드 라운드 유지)
class _CompletedView extends StatelessWidget {
  const _CompletedView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/loading_complete.png'),
          fit: BoxFit.cover,
          opacity: 0.35,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 44, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            '생성이 완료되었습니다!',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              LectureLoadingService.instance.hideLoading();
            },
            style: TextButton.styleFrom(
              foregroundColor: scheme.onPrimary,
              backgroundColor: scheme.primary.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

/// 왼쪽 캐릭터 영역 (정사각 + 라운드)
class _CharacterBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Image.asset(
                'assets/images/loading_character.png',
                height: constraints.maxHeight,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 알약형 커스텀 프로그레스 바 (안쪽에 퍼센트 텍스트)
class _FancyProgressBar extends StatelessWidget {
  const _FancyProgressBar({required this.value, this.height = 44});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final fillW = w * clamped;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 트랙
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),

            // 채워진 부분
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: fillW,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF7FAB0), // 밝은 노란색
                    Color(0xFFE8D77A), // 약간 어두운 노란색
                  ],
                ),
              ),
            ),

            // 퍼센트 텍스트 (가운데)
            Positioned.fill(
              child: Center(
                child: Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
