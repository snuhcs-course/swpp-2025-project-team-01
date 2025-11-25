import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/device_orientation_helper.dart';
import 'package:re_view/features/player/player_widgets.dart';
import 'package:re_view/features/player/player_controller.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/player/widgets/high_contrast_container.dart';

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
                isVertical: true,
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
                              // isSynced, currentPage, currentSentenceIndex를 함께 감시하여 즉시 업데이트
                              child: ListenableBuilder(
                                listenable: Listenable.merge([
                                  controller.isSynced,
                                  controller.currentPage,
                                  controller.currentSentenceIndex,
                                ]),
                                builder: (context, _) {
                                  return SyncButton(
                                    isSynced: controller.isSynced.value,
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
                      isVertical: false,
                    ),
                  ),
              ],
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
        final content = Stack(
          children: [
            // PDF 내용
            if (controller.pdfController != null)
              ValueListenableBuilder<bool>(
                valueListenable: controller.isSynced,
                builder: (context, isSynced, _) {
                  return HighContrastContainer(
                    enabled:
                        HiveManager.instance.settings.accessibilityHighContrast,
                    child: PdfView(
                      key: controller.pdfViewKey,
                      controller: controller.pdfController!,
                      onPageChanged: controller.onPdfPageChanged,
                      physics: !isSynced
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                    ),
                  );
                },
              )
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // 투명 제스처 레이어 - 컨트롤이 없을 때만 활성화
            ValueListenableBuilder<bool>(
              valueListenable: controller.showControls,
              builder: (context, showControls, _) {
                if (showControls) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: GestureDetector(
                    key: ValueKey(
                      'pdf-gesture-overlay-${isVertical ? 'vertical' : 'horizontal'}',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: isVertical
                        ? null
                        : (details) {
                            controller.handleVerticalDrag(details);
                          },
                    onTap: () => controller.handlePdfTap(isVertical),
                    onDoubleTapDown: (TapDownDetails details) {
                      controller.saveDoubleTapPosition(
                        details.localPosition.dx,
                      );
                    },
                    onDoubleTap: () {
                      controller.handleDoubleTapSkip(
                        MediaQuery.of(context).size.width,
                      );
                    },
                    // Sync off일 때 horizontal swipe로 페이지 전환
                    onHorizontalDragEnd: controller.isSynced.value
                        ? null
                        : (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < -300) {
                              // 왼쪽 스와이프 → 다음 페이지
                              if (currentPage < controller.pageCount) {
                                controller.jumpToPage(currentPage + 1);
                              }
                            } else if (velocity > 300) {
                              // 오른쪽 스와이프 → 이전 페이지
                              if (currentPage > 1) {
                                controller.jumpToPage(currentPage - 1);
                              }
                            }
                          },
                    child: Container(color: Colors.transparent),
                  ),
                );
              },
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
        );

        if (isVertical) {
          // LayoutBuilder와 MediaQuery를 조합하여 회전 중 overflow 방지
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = MediaQuery.of(context).size;
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;

              // thumbnail 캐시에서 가져온 aspect ratio 사용 (width/height)
              // 기본값: 16:9 = 1.778
              final aspectRatio = controller.pdfAspectRatio ?? (16 / 9);

              // 이상적인 높이 계산 (width 기준)
              final idealHeight = availableWidth / aspectRatio;

              // 최종 높이 결정 로직
              double finalHeight;

              if (availableHeight.isFinite && availableHeight > 0) {
                // constraints가 유한한 경우: 사용 가능한 높이 내에서 제한
                finalHeight = idealHeight <= availableHeight
                    ? idealHeight
                    : availableHeight;
              } else {
                // constraints가 무한대인 경우: idealHeight 사용하되
                // 화면 높이를 초과하지 않도록 제한 (회전 중 안전장치)
                final maxSafeHeight = screenSize.height * 0.6; // 화면의 60%까지만
                finalHeight = idealHeight <= maxSafeHeight
                    ? idealHeight
                    : maxSafeHeight;
              }

              return SizedBox(
                width: availableWidth,
                height: finalHeight,
                child: content,
              );
            },
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
      child: GestureDetector(
        onTap: controller.toggleControls,
        child: Container(
          color: const Color(0x4D1D1D1D),
          child: Stack(
            children: [
              // Top control bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ListenableBuilder(
                  // isOriginalAudio, isSynced, currentPage, currentSentenceIndex를 함께 감시
                  listenable: Listenable.merge([
                    controller.isOriginalAudio,
                    controller.isSynced,
                    controller.currentPage,
                    controller.currentSentenceIndex,
                  ]),
                  builder: (context, _) {
                    return TopControlBar(
                      isVertical: isVertical,
                      onBack: onBack,
                      isOriginalAudio: controller.isOriginalAudio.value,
                      isKoreanLecture: controller.isKoreanLecture ?? true,
                      onAudioToggle: controller.toggleAudioSource,
                      onSpeedChanged: controller.setPlaybackSpeed,
                      isSynced: controller.isSynced.value,
                      onSyncToggle: controller.toggleSync,
                      pageDifference: controller.pageDifference,
                    );
                  },
                ),
              ),

              // Center play controls - always in the exact center
              Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: controller.isPlaying,
                  builder: (context, isPlaying, _) {
                    return CenterPlayControls(
                      isPlaying: isPlaying,
                      onPlayPause: controller.playPause,
                      onSkipBackward: controller.skipBackward,
                      onSkipForward: controller.skipForward,
                      isVertical: isVertical,
                    );
                  },
                ),
              ),

              // Bottom control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    controller.currentTime,
                    controller.isCaptionEnabled,
                    controller.showTranscriptPanel,
                    controller.isFullscreen,
                    controller.actualAudioDuration,
                  ]),
                  builder: (context, _) {
                    return BottomControlBar(
                      isVertical: isVertical,
                      currentTime: controller.currentTime.value,
                      totalTime: controller.actualAudioDuration.value,
                      onTimeChanged: (seconds) {
                        // 슬라이더 움직일 때 즉시 PDF 페이지 업데이트
                        controller.seek(seconds);
                        controller.updateCurrentSentence(false, seconds);
                      },
                      isCaptionEnabled: controller.isCaptionEnabled.value,
                      onCaptionToggle: controller.toggleCaption,
                      showTranscriptPanel: controller.showTranscriptPanel.value,
                      onTranscriptToggle: controller.toggleTranscriptPanel,
                      isFullscreen: controller.isFullscreen.value,
                      onFullscreenToggle: controller.toggleFullscreen,
                      isTablet: isTabletDevice(context),
                    );
                  },
                ),
              ),
            ],
          ),
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
      child: HighContrastContainer(
        enabled: HiveManager.instance.settings.accessibilityHighContrast,
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
      height: 170,
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
            child: HighContrastContainer(
              enabled: HiveManager.instance.settings.accessibilityHighContrast,
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
          ),
          SizedBox(height: 130, child: pagesList),
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
        final itemHeight = isVertical ? 120.0 : 100.0;
        final aspectRatio = controller.pdfAspectRatio ?? (16 / 9);
        final calculatedWidth = itemHeight * aspectRatio;

        final slidesList = PdfSlidesList(
          pageCount: controller.pageCount,
          currentPage: currentPage,
          itemWidth: calculatedWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          return HighContrastContainer(
            enabled: HiveManager.instance.settings.accessibilityHighContrast,
            child: Container(
              height: 150,
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : const Color(0xFFEEEEEE),
              child: slidesList,
            ),
          );
        } else {
          return HighContrastContainer(
            enabled: HiveManager.instance.settings.accessibilityHighContrast,
            child: slidesList,
          );
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
        final isActive = isKorean;
        final backgroundColor = (isActive
            ? (isDark ? colorScheme.primary : Colors.blue.shade600)
            : (isDark ? colorScheme.secondaryContainer : Colors.grey.shade400));
        final textColor = isActive
            ? (isDark ? colorScheme.onPrimary : Colors.white)
            : (isDark ? colorScheme.onSecondaryContainer : Colors.white);

        return InkWell(
          onTap: controller.toggleTranscriptLanguage,
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
  const TranscriptArea({
    super.key,
    required this.controller,
    required this.isVertical,
  });

  final PlayerController controller;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (controller.transcriptData == null) {
      return HighContrastContainer(
        enabled: HiveManager.instance.settings.accessibilityHighContrast,
        child: Container(
          width: double.infinity,
          color: isDark ? colorScheme.surface : const Color(0xFFFAFAFA),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);

    return HighContrastContainer(
      enabled: HiveManager.instance.settings.accessibilityHighContrast,
      child: Container(
        width: double.infinity,
        color: isDark ? colorScheme.surface : const Color(0xFFFAFAFA),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.transcript,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? colorScheme.onSurface : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                TranslationButton(controller: controller),
                if (!isVertical) ...[
                  const Spacer(),
                  IconButton(
                    onPressed: controller.toggleTranscriptPanel,
                    icon: Icon(
                      Icons.close,
                      color: isDark ? colorScheme.onSurface : Colors.grey[700],
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
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
                          final isCurrentSentence =
                              currentSentenceIndex == index;
                          final displayText = isKorean
                              ? sentence.textKor
                              : sentence.textEng;

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
                    child: HighContrastContainer(
                      enabled: HiveManager
                          .instance
                          .settings
                          .accessibilityHighContrast,
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
