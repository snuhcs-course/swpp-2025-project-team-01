// 자주 쓰는 작은 위젯들
import 'package:flutter/material.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/core/localization/app_localizations.dart';
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

    // Use theme's chip settings for high contrast mode
    final chipTheme = Theme.of(context).chipTheme;
    final textTheme = Theme.of(context).textTheme;

    return Chip(
      label: Text(
        label ?? '$labelPrefix${tag.name}',
        style: TextStyle(
          color: resolvedTextColor,
          fontFamily: 'NanumSquare',
          fontWeight: textTheme.bodyMedium?.fontWeight ?? FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      elevation: chipTheme.elevation ?? 2,
      side: chipTheme.side,
      shape: chipTheme.shape ?? const StadiumBorder(),
      padding:
          chipTheme.padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

    // Use theme's chip settings for high contrast mode
    final chipTheme = Theme.of(context).chipTheme;
    final textTheme = Theme.of(context).textTheme;

    return ChoiceChip(
      label: Text(
        label ?? '$labelPrefix${tag.name}',
        style: TextStyle(
          color: resolvedTextColor,
          fontFamily: 'NanumSquare',
          fontWeight: textTheme.bodyMedium?.fontWeight ?? FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: color,
      selectedColor: color,
      elevation: selected
          ? (chipTheme.elevation ?? 4)
          : (chipTheme.elevation ?? 2),
      side: chipTheme.side,
      shape: chipTheme.shape ?? const StadiumBorder(),
      padding:
          chipTheme.padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      showCheckmark: showCheckmark,
      checkmarkColor: resolvedTextColor,
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
          child = CollapsedBubbleOverlay(
            key: const ValueKey('collapsed-bubble'),
            service: service,
          );
        } else {
          child = ExpandedLoadingOverlay(
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
class ExpandedLoadingOverlay extends StatelessWidget {
  const ExpandedLoadingOverlay({
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
          child: RoundedCard(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: hasError
                  ? ErrorView(
                      key: const ValueKey('error'),
                      errorTitle: service.errorTitle,
                      errorMessage: service.errorMessage,
                    )
                  : isCompleted
                  ? CompletedView(
                      key: const ValueKey('completed'),
                      context: context,
                    )
                  : LoadingView(
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

class CollapsedBubbleOverlay extends StatefulWidget {
  const CollapsedBubbleOverlay({super.key, required this.service});

  final LectureLoadingService service;

  @override
  State<CollapsedBubbleOverlay> createState() => _CollapsedBubbleOverlayState();
}

class _CollapsedBubbleOverlayState extends State<CollapsedBubbleOverlay> {
  late double _dragX;
  late double _dragY;
  bool _isDragging = false;

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
        AnimatedPositioned(
          duration: _isDragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          left: _dragX,
          bottom: _dragY,
          child: SafeArea(
            top: false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  // Update position during drag (allow free movement temporarily)
                  _dragX = (_dragX + details.delta.dx).clamp(
                    -(bubbleSize * 0.1),
                    screenSize.width - bubbleSize * 0.9 - safeArea.right,
                  );
                  _dragY = (_dragY - details.delta.dy).clamp(
                    0.0,
                    screenSize.height - bubbleSize - safeArea.top,
                  );
                });
              },
              onPanEnd: (details) {
                // Snap to left or right side with 10% clipping
                final screenCenter = screenSize.width / 2;
                final isOnLeftSide = _dragX < screenCenter - bubbleSize / 2;

                setState(() {
                  _isDragging = false;
                  if (isOnLeftSide) {
                    // Snap to left with 10% clipped
                    _dragX = -(bubbleSize * 0.1);
                  } else {
                    // Snap to right with 10% clipped
                    _dragX =
                        screenSize.width - bubbleSize * 0.9 - safeArea.right;
                  }
                });

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

class RoundedCard extends StatelessWidget {
  const RoundedCard({super.key, required this.child});

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
class LoadingView extends StatelessWidget {
  const LoadingView({
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
    final l10n = AppLocalizations.of(context);

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
                        l10n.lectureCreating,
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
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 수업명 라벨 + 값
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.lectureName,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: title.isEmpty ? (l10n.untitled) : title,
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
class CompletedView extends StatelessWidget {
  const CompletedView({super.key, required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext widgetContext) {
    final textTheme = Theme.of(context).textTheme;
    final service = LectureLoadingService.instance;
    final l10n = AppLocalizations.of(context);

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
                        l10n.lectureCreationComplete,
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
                  l10n.lectureCreationCompleted,
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
                    label: Text(l10n.goToLecture),
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
class ErrorView extends StatelessWidget {
  const ErrorView({
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color headerColor = isDark
        ? const Color.fromARGB(255, 88, 88, 86) // 다크모드: 밝은 회청색
        : const Color(0xFF1D1D1D); // 라이트모드: 검은색
    final Color textColor = isDark ? Colors.white : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: onClose ?? () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// 수정 다이얼로그 공통 위젯
///
/// DialogHeaderTitle, 스크롤 가능한 content, 삭제/완료 버튼을 포함하는 표준 수정 다이얼로그입니다.
/// 내부 콘텐츠는 [content] 파라미터로 커스터마이즈.
class EditDialog extends StatelessWidget {
  const EditDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onDelete,
    required this.onComplete,
    required this.deleteLabel,
    required this.completeLabel,
    this.onArchive,
    this.archiveLabel,
  });

  final String title;
  final Widget content;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final VoidCallback? onArchive;
  final String deleteLabel;
  final String completeLabel;
  final String? archiveLabel;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.dialogTheme.backgroundColor,
      titlePadding: EdgeInsets.zero,
      title: DialogHeaderTitle(title: title),
      content: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.7 - keyboardHeight,
          ),
          child: SingleChildScrollView(child: content),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (archiveLabel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // 삭제 버튼 (왼쪽)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: Text(deleteLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 완료 버튼 (오른쪽)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: onArchive,
                      icon: const Icon(Icons.archive, size: 20),
                      label: Text(archiveLabel!),
                    ),
                  ),
                ],
              ),
              // 보관 버튼
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onComplete,
                  child: Text(completeLabel),
                ),
              ),
            ],
          ),
        if (archiveLabel == null)
          Row(
            children: [
              // 삭제 버튼 (왼쪽)
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(deleteLabel),
                ),
              ),
              const SizedBox(width: 12),
              // 완료 버튼 (오른쪽)
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onComplete,
                  child: Text(completeLabel),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 삭제 경고 다이얼로그 위젯
///
/// 검은색 헤더와 회색 본문을 가진 표준 경고 다이얼로그입니다.
/// 내부 텍스트는 [body] 파라미터로 커스터마이즈.
class DeleteWarningDialog extends StatelessWidget {
  const DeleteWarningDialog({
    super.key,
    required this.body,
    required this.onConfirm,
    required this.yesText,
    required this.noText,
    required this.warningText,
  });

  final Widget body;
  final VoidCallback onConfirm;
  final String yesText;
  final String noText;
  final String warningText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1D1D1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  warningText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Body
            Container(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8E8E8),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  body,
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      // "예" 버튼
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A5A5A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                              onConfirm();
                            },
                            child: Text(
                              yesText,
                              style: const TextStyle(
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
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC0C0C0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              noText,
                              style: const TextStyle(
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
    required this.id,
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
    this.isArchivedSubject = false,
    this.onEditSubject,
    this.onUnarchiveSubject,
    this.onDeleteSubject,
    this.reorderIndex,
  });

  final String title;
  final List<HiveTag> tags;
  final String id;
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
  final bool isArchivedSubject;
  final VoidCallback? onEditSubject;
  final VoidCallback? onUnarchiveSubject;
  final VoidCallback? onDeleteSubject;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                                child: ReorderableDragStartListener(
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
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
                // 보관함에 있는 과목일 경우
                if (isArchivedSubject)
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: iconColor),
                    onPressed: () async => onDeleteSubject?.call(),
                  ),
                if (isArchivedSubject)
                  IconButton(
                    icon: Icon(Icons.reply, size: 20, color: iconColor),
                    onPressed: () async => onUnarchiveSubject?.call(),
                  ),
                // 펼침/접기 버튼
                IconButton(
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
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
