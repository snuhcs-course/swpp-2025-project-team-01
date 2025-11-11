// 자주 쓰는 작은 위젯들
import 'package:flutter/material.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/core/theme/color_scheme.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/main.dart' show navigatorKey;

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
    this.textColor,
  });

  final HiveTag tag;
  final String? label;
  final String labelPrefix;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(tag.color);
    final Color resolvedTextColor =
        textColor ??
        getTagThemeTextColor(HiveManager.instance.settings.tagColorTheme);
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        chipTheme: const ChipThemeData(
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'NanumSquare',
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: Color(0x33000000), width: 1),
          shape: StadiumBorder(),
        ),
      ),
      child: Chip(
        label: Text(
          label ?? '$labelPrefix${tag.name}',
          style: TextStyle(color: resolvedTextColor, fontFamily: 'NanumSquare'),
        ),
        backgroundColor: color,
        elevation: 2,
        side: const BorderSide(color: Color(0x1F000000), width: 0.5),
      ),
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
    this.textColor,
  });

  final HiveTag tag;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool showCheckmark;
  final String? label;
  final String labelPrefix;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(tag.color);
    final Color resolvedTextColor =
        textColor ??
        getTagThemeTextColor(HiveManager.instance.settings.tagColorTheme);
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        chipTheme: const ChipThemeData(
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'NanumSquare',
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: Color(0x33000000), width: 1),
          shape: StadiumBorder(),
        ),
      ),
      child: ChoiceChip(
        label: Text(
          label ?? '$labelPrefix${tag.name}',
          style: TextStyle(color: resolvedTextColor, fontFamily: 'NanumSquare'),
        ),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: color,
        selectedColor: color,
        elevation: selected ? 4 : 2,
        side: const BorderSide(color: Color(0x1F000000), width: 0.5),
        showCheckmark: showCheckmark,
        checkmarkColor: resolvedTextColor,
      ),
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
      builder: (buildContext, _) {
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
            context: buildContext,
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
  const _ExpandedLoadingOverlay({
    super.key,
    required this.service,
    required this.context,
  });

  final LectureLoadingService service;
  final BuildContext context;

  @override
  Widget build(BuildContext widgetContext) {
    final isCompleted = service.isCompleted;
    final hasError = service.hasError;

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
              child: hasError
                  ? _ErrorView(
                      key: const ValueKey('error'),
                      errorTitle: service.errorTitle,
                      errorMessage: service.errorMessage,
                    )
                  : isCompleted
                  ? _CompletedView(
                      key: const ValueKey('completed'),
                      context: context,
                    )
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

class _CollapsedBubbleOverlay extends StatefulWidget {
  const _CollapsedBubbleOverlay({super.key, required this.service});

  final LectureLoadingService service;

  @override
  State<_CollapsedBubbleOverlay> createState() =>
      _CollapsedBubbleOverlayState();
}

class _CollapsedBubbleOverlayState extends State<_CollapsedBubbleOverlay> {
  late double _dragX;
  late double _dragY;

  @override
  void initState() {
    super.initState();
    _dragX = widget.service.bubbleX;
    _dragY = widget.service.bubbleY;
  }

  @override
  Widget build(BuildContext context) {
    const double bubbleSize = 88;
    final progress = widget.service.progress.clamp(0.0, 1.0);
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Stack(
      children: [
        Positioned(
          left: _dragX,
          bottom: _dragY,
          child: SafeArea(
            top: false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                // Prevent tap from triggering during drag
              },
              onPanUpdate: (details) {
                setState(() {
                  // Update position during drag
                  _dragX = (_dragX + details.delta.dx).clamp(
                    0.0,
                    screenSize.width - bubbleSize - safeArea.right,
                  );
                  _dragY = (_dragY - details.delta.dy).clamp(
                    0.0,
                    screenSize.height - bubbleSize - safeArea.top,
                  );
                });
              },
              onPanEnd: (details) {
                // Save final position when drag ends
                widget.service.updateBubblePosition(_dragX, _dragY);
              },
              onTap: () {
                // Tap to expand
                widget.service.expandFromBubble();
              },
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
    final language = HiveManager.instance.settings.language;
    final isKorean = language == 'ko';

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
                        isKorean ? '강의 생성 중…' : 'Creating Lecture…',
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
                      child: Text(isKorean ? '취소' : 'Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 수업명 라벨 + 값
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isKorean ? '강의명: ' : 'Lecture: ',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: title.isEmpty
                            ? (isKorean ? '제목 없음' : 'Untitled')
                            : title,
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
  const _CompletedView({super.key, required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext widgetContext) {
    final textTheme = Theme.of(context).textTheme;
    final service = LectureLoadingService.instance;
    final language = HiveManager.instance.settings.language;
    final isKorean = language == 'ko';

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
          _CharacterBlock(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isKorean ? '강의 생성 완료!' : 'Lecture Created!',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF7FAB0),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: service.hideLoading,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Icon(Icons.close, color: Colors.grey, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isKorean
                      ? '강의 생성이 완료되었습니다.\n결과를 확인해보세요.'
                      : 'Lecture creation completed.\nCheck out the result.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade300,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (service.lectureId != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('🔘 Button pressed!');
                      final lectureId = service.getLectureIdAndHide();
                      debugPrint('🔘 lectureId: $lectureId');
                      debugPrint('🔘 navigatorKey: $navigatorKey');
                      debugPrint(
                        '🔘 navigatorKey.currentState: ${navigatorKey.currentState}',
                      );

                      if (lectureId != null) {
                        navigatorKey.currentState?.pushNamed(
                          '/player',
                          arguments: {'lectureId': lectureId},
                        );
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: Text(isKorean ? '강의 바로가기' : 'Go to Lecture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7FAB0),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 에러 화면
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.errorTitle,
    required this.errorMessage,
  });

  final String errorTitle;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final service = LectureLoadingService.instance;

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
          _CharacterBlock(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        errorTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF6B6B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: service.hideLoading,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Icon(Icons.close, color: Colors.grey, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade300,
                  ),
                  maxLines: 3,
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

/// 다이얼로그 헤더 위젯 (공통 스타일)
///
/// 검은 배경의 다이얼로그 헤더로 제목과 닫기 버튼을 표시합니다.
class DialogHeaderTitle extends StatelessWidget {
  const DialogHeaderTitle({super.key, required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1D1D1D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose ?? () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
    this.favoriteOrDrag,
    this.onToggleFavorite,
    this.favoriteIconColor,
    this.onLongPress,
    this.titleEndPadding = 0,
    this.showEdit = false,
    this.onEditSubject,
    this.reorderIndex,
  });

  final String title;
  final List<HiveTag> tags;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final double panelRadius;
  final BorderRadius? collapsedRadius;
  final BorderRadius? expandedRadius;
  final IconData? favoriteOrDrag;
  final VoidCallback? onToggleFavorite;
  final Color? favoriteIconColor;
  final VoidCallback? onLongPress;
  final double titleEndPadding;
  final bool showEdit;
  final VoidCallback? onEditSubject;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color headerColor = isDark
        ? const Color.fromARGB(255, 88, 88, 86) // 다크모드: 밝은 회청색
        : const Color(0xFF1D1D1D); // 라이트모드: 검은색

    // 여기 아래 두 줄 redundant한 조건문 맞는데, 헤더 색 또 바뀔때 커스텀하기 쉽게 이대로 유지합시다
    final Color textColor = isDark ? Colors.white : Colors.white;
    final Color iconColor = isDark ? Colors.white : Colors.white;

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
      onTap: onToggleExpanded,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 즐겨찾기 또는 드래그 아이콘
                if (favoriteOrDrag != null)
                  favoriteOrDrag == Icons.drag_indicator
                      ? (reorderIndex != null
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ReorderableDelayedDragStartListener(
                                  index: reorderIndex!, // ← required
                                  child: Icon(
                                    Icons.drag_indicator,
                                    size: 22,
                                    color: iconColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink())
                      : IconButton(
                          icon: Icon(
                            favoriteOrDrag,
                            color: favoriteIconColor ?? iconColor,
                            size: 24,
                          ),
                          onPressed: onToggleFavorite,
                          tooltip: '즐겨찾기',
                        ),
                if (favoriteOrDrag != null)
                  SizedBox(
                    width: favoriteOrDrag == Icons.drag_indicator ? 18 : 2,
                  ),
                // 제목
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: titleEndPadding),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // 수정 버튼 (수정 모드일 때)
                Visibility(
                  visible: showEdit,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: IconButton(
                    icon: Icon(Icons.edit, size: 20, color: iconColor),
                    onPressed: () async => onEditSubject?.call(),
                  ),
                ),
                // 펼침/접기 버튼
                IconButton(
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: iconColor,
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
                  left: favoriteOrDrag != null ? 40 : 0,
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
