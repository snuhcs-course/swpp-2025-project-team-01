import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:re_view/features/player/player_widgets.dart';
import 'package:re_view/features/player/player_controller.dart';
import 'package:re_view/data/hive_manager.dart';

// ========== Layout Widgets ==========

class VerticalPlayerLayout extends StatelessWidget {
  const VerticalPlayerLayout({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final PlayerController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isPagesExpanded,
      builder: (context, isPagesExpanded, _) {
        return Column(
          children: [
            PdfArea(isVertical: true, controller: controller, onBack: onBack),

            VerticalToggleBar(
              isPagesExpanded: isPagesExpanded,
              onToggle: controller.togglePages,
            ),

            if (isPagesExpanded)
              PagesListWidget(isVertical: true, controller: controller),

            Expanded(
              child: TranscriptArea(
                key: controller.transcriptAreaKey,
                controller: controller,
              ),
            ),
          ],
        );
      },
    );
  }
}

class HorizontalPlayerLayout extends StatelessWidget {
  const HorizontalPlayerLayout({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final PlayerController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final transcriptPanelWidth = screenWidth * 0.3;

    return ValueListenableBuilder<bool>(
      valueListenable: controller.showTranscriptPanel,
      builder: (context, showTranscriptPanel, _) {
        return Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: controller.isPagesExpanded,
                    builder: (context, isPagesExpanded, _) {
                      return Stack(
                        children: [
                          PdfArea(
                            isVertical: false,
                            controller: controller,
                            onBack: onBack,
                          ),

                          if (isPagesExpanded)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: HorizontalToggleBar(
                                onToggle: controller.togglePages,
                                pagesList: PagesListWidget(
                                  isVertical: false,
                                  controller: controller,
                                ),
                              ),
                            ),

                          if (isPagesExpanded)
                            Positioned(
                              top: 12,
                              right: 16,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: controller.isSynced,
                                builder: (context, isSynced, _) {
                                  return SyncButton(
                                    isSynced: isSynced,
                                    onPressed: controller.toggleSync,
                                    pageDifference: controller.pageDifference,
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                if (showTranscriptPanel)
                  Container(
                    width: transcriptPanelWidth,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : const Color(0xFFFAFAFA),
                    child: TranscriptArea(
                      key: controller.transcriptAreaKey,
                      controller: controller,
                    ),
                  ),
              ],
            ),

            Positioned(
              right: showTranscriptPanel ? transcriptPanelWidth : 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: controller.toggleTranscriptPanel,
                  child: Container(
                    width: 30,
                    height: 80,
                    decoration: BoxDecoration(
                      color: showTranscriptPanel
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        topRight: Radius.zero,
                        bottomRight: Radius.zero,
                      ),
                    ),
                    child: Icon(
                      showTranscriptPanel
                          ? Icons.chevron_right
                          : Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
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

// ========== PDF Area ==========

class PdfArea extends StatelessWidget {
  const PdfArea({
    super.key,
    required this.isVertical,
    required this.controller,
    required this.onBack,
  });

  final bool isVertical;
  final PlayerController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.currentPage,
      builder: (context, currentPage, _) {
        final content = GestureDetector(
          onVerticalDragUpdate: isVertical
              ? null
              : (details) {
                  controller.handleVerticalDrag(details);
                },
          onTap: () => controller.handlePdfTap(isVertical),
          child: Stack(
            children: [
              // PDF 내용
              if (controller.pdfController != null)
                PdfView(
                  key: controller.pdfViewKey,
                  controller: controller.pdfController!,
                  onPageChanged: controller.onPdfPageChanged,
                )
              else
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

              // 자막 오버레이 (가로 모드 + 자막 활성화)
              if (!isVertical)
                ValueListenableBuilder<bool>(
                  valueListenable: controller.isCaptionEnabled,
                  builder: (context, isCaptionEnabled, _) {
                    if (!isCaptionEnabled) {
                      return const SizedBox.shrink();
                    }
                    return CaptionOverlay(controller: controller);
                  },
                ),

              // 비디오 컨트롤 오버레이
              ValueListenableBuilder<bool>(
                valueListenable: controller.showControls,
                builder: (context, showControls, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: controller.isPagesExpanded,
                    builder: (context, isPagesExpanded, _) {
                      if (!showControls || (isPagesExpanded && !isVertical)) {
                        return const SizedBox.shrink();
                      }
                      return VideoControlsOverlay(
                        isVertical: isVertical,
                        controller: controller,
                        onBack: onBack,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );

        if (isVertical) {
          final screenWidth = MediaQuery.of(context).size.width;
          // thumbnail 캐시에서 가져온 aspect ratio 사용 (width/height)
          // 기본값: 16:9 = 1.778
          final aspectRatio = controller.pdfAspectRatio ?? (16 / 9);
          final pdfHeight = screenWidth / aspectRatio;
          return SizedBox(
            width: screenWidth,
            height: pdfHeight,
            child: content,
          );
        } else {
          return content;
        }
      },
    );
  }
}

// ========== Video Controls Overlay ==========

class VideoControlsOverlay extends StatelessWidget {
  const VideoControlsOverlay({
    super.key,
    required this.isVertical,
    required this.controller,
    required this.onBack,
  });

  final bool isVertical;
  final PlayerController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0x4D1D1D1D),
        child: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: controller.isOriginalAudio,
              builder: (context, isOriginalAudio, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: controller.isCaptionEnabled,
                  builder: (context, isCaptionEnabled, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: controller.isSynced,
                      builder: (context, isSynced, _) {
                        return TopControlBar(
                          isVertical: isVertical,
                          onBack: onBack,
                          isOriginalAudio: isOriginalAudio,
                          onAudioToggle: controller.toggleAudioSource,
                          isCaptionEnabled: isCaptionEnabled,
                          onCaptionToggle: controller.toggleCaption,
                          onSpeedChanged: controller.setPlaybackSpeed,
                          isSynced: isSynced,
                          onSyncToggle: controller.toggleSync,
                          pageDifference: controller.pageDifference,
                        );
                      },
                    );
                  },
                );
              },
            ),

            const Spacer(),

            ValueListenableBuilder<bool>(
              valueListenable: controller.isPlaying,
              builder: (context, isPlaying, _) {
                return CenterPlayControls(
                  isPlaying: isPlaying,
                  onPlayPause: controller.playPause,
                  onSkipBackward: controller.skipBackward,
                  onSkipForward: controller.skipForward,
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ValueListenableBuilder<double>(
                valueListenable: controller.currentTime,
                builder: (context, currentTime, _) {
                  return VideoTimelineSlider(
                    currentTime: currentTime,
                    totalTime: controller.totalTime,
                    onChanged: controller.seek,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Toggle Bars ==========

class VerticalToggleBar extends StatelessWidget {
  const VerticalToggleBar({
    super.key,
    required this.isPagesExpanded,
    required this.onToggle,
  });

  final bool isPagesExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        height: 40,
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF5F5F5),
        child: Center(
          child: Icon(
            isPagesExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[700],
            size: 28,
          ),
        ),
      ),
    );
  }
}

class HorizontalToggleBar extends StatelessWidget {
  const HorizontalToggleBar({
    super.key,
    required this.onToggle,
    required this.pagesList,
  });

  final VoidCallback onToggle;
  final Widget pagesList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              height: 40,
              color: Colors.transparent,
              child: const Center(
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(height: 110, child: pagesList),
        ],
      ),
    );
  }
}

// ========== Pages List Widget ==========

class PagesListWidget extends StatelessWidget {
  const PagesListWidget({
    super.key,
    required this.isVertical,
    required this.controller,
  });

  final bool isVertical;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.currentPage,
      builder: (context, currentPage, _) {
        final slidesList = PdfSlidesList(
          pageCount: controller.pageCount,
          currentPage: currentPage,
          itemWidth: isVertical ? 180 : 150,
          padding: isVertical
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
              : const EdgeInsets.fromLTRB(12, 8, 12, 24),
          getCachedOrRenderPage:
              controller.pdfCacheService.getCachedOrRenderPage,
          getCachedImage: controller.pdfCacheService.getCachedImageDirect,
          onPageTap: (pageNumber) {
            controller.jumpToPage(pageNumber);
            // 캐시되지 않은 페이지라면 즉시 캐싱 시작
            if (controller.pdfCacheService.getCachedImageDirect(pageNumber) ==
                null) {
              controller.pdfCacheService.getCachedOrRenderPage(pageNumber);
            }
            controller.seekToSlide(pageNumber);
          },
        );

        if (isVertical) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            height: 150,
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : const Color(0xFFEEEEEE),
            child: slidesList,
          );
        } else {
          return slidesList;
        }
      },
    );
  }
}

// ========== Translation Button ==========

class TranslationButton extends StatelessWidget {
  const TranslationButton({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: controller.isKoreanLanguage,
      builder: (context, isKorean, _) {
        final hasKorean = controller.hasKoreanTranscript;
        final isEnabled = hasKorean;
        final isActive = hasKorean && isKorean;
        final backgroundColor = !isEnabled
            ? (isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                  : Colors.grey.shade300)
            : (isActive
                  ? (isDark ? colorScheme.primary : Colors.blue.shade600)
                  : (isDark
                        ? colorScheme.secondaryContainer
                        : Colors.grey.shade400));
        final textColor = !isEnabled
            ? (isDark
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                  : Colors.grey.shade500)
            : (isActive
                  ? (isDark ? colorScheme.onPrimary : Colors.white)
                  : (isDark ? colorScheme.onSecondaryContainer : Colors.white));

        return GestureDetector(
          onTap: hasKorean ? controller.toggleTranscriptLanguage : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: isDark
                  ? Border.all(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.6),
                    )
                  : null,
            ),
            child: Text(
              isKorean ? 'KOR' : 'ENG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== Transcript Area ==========

class TranscriptArea extends StatelessWidget {
  const TranscriptArea({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (controller.transcriptData == null) {
      return Container(
        width: double.infinity,
        color: isDark ? colorScheme.surface : const Color(0xFFFAFAFA),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    final language = HiveManager.instance.settings.language;
    final transcriptLabel = language == 'ko' ? '대본' : 'Transcript';

    return Container(
      width: double.infinity,
      color: isDark ? colorScheme.surface : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                transcriptLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? colorScheme.onSurface : Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              TranslationButton(controller: controller),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<int?>(
              valueListenable: controller.currentSentenceIndex,
              builder: (context, currentSentenceIndex, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: controller.isKoreanLanguage,
                  builder: (context, isKorean, _) {
                    return ListView.builder(
                      controller: controller.transcriptScrollController,
                      itemCount: controller.transcriptData!.timestamps.length,
                      itemBuilder: (context, index) {
                        final sentence =
                            controller.transcriptData!.timestamps[index];
                        final isCurrentSentence = currentSentenceIndex == index;
                        final displayText =
                            (isKorean && sentence.textKor != null)
                            ? sentence.textKor!
                            : sentence.text;

                        return AutoScrollTag(
                          key: ValueKey(index),
                          controller: controller.transcriptScrollController!,
                          index: index,
                          child: GestureDetector(
                            onTap: () => controller.seekToSentence(index),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: isCurrentSentence ? 18 : 14,
                                  fontWeight: isCurrentSentence
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isCurrentSentence
                                      ? (isDark
                                            ? colorScheme.primary
                                            : Colors.black)
                                      : (isDark
                                            ? colorScheme.onSurfaceVariant
                                            : Colors.grey[600]),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ========== Caption Overlay ==========

class CaptionOverlay extends StatelessWidget {
  const CaptionOverlay({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final hiveManager = HiveManager.instance;
    final emphasizeCaptions =
        hiveManager.settings.accessibilityEmphasizeCaptions;

    return ValueListenableBuilder<int?>(
      valueListenable: controller.currentSentenceIndex,
      builder: (context, _, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: controller.isKoreanLanguage,
          builder: (context, __, ___) {
            final captionText = controller.captionText;

            if (captionText.isEmpty) {
              return const SizedBox.shrink();
            }

            return ValueListenableBuilder<bool>(
              valueListenable: controller.showControls,
              builder: (context, showControls, _) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: showControls ? 80 : 20,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        captionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: emphasizeCaptions ? 24 : 18,
                          fontWeight: emphasizeCaptions
                              ? FontWeight.bold
                              : FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
