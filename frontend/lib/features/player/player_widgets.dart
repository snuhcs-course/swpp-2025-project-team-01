import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:re_view/core/localization/app_localizations.dart';

// 시간 포맷 유틸 함수
String formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString();
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// 비디오 컨트롤 공통 위젯 모듈
// 뒤로가기 버튼
class BackButton extends StatelessWidget {
  const BackButton({
    super.key,
    required this.onPressed,
    this.isVertical = false,
  });

  final VoidCallback onPressed;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.chevron_left,
        color: Colors.white,
        size: isVertical ? 26 : 32,
      ),
    );
  }
}

// 싱크 토글 버튼
class SyncButton extends StatelessWidget {
  const SyncButton({
    super.key,
    required this.isSynced,
    required this.onPressed,
    this.pageDifference,
    this.isVertical = false,
  });

  final bool isSynced;
  final VoidCallback onPressed;
  final int? pageDifference;
  final bool isVertical;

  String _getDifferenceText(BuildContext context, int difference) {
    final l10n = AppLocalizations.of(context);
    if (difference == 0) {
      return l10n.synchronized;
    }
    final absValue = difference.abs();
    if (difference < 0) {
      return l10n.pagesAhead(absValue);
    } else {
      return l10n.pagesBehind(absValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDifference = !isSynced && pageDifference != null;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            isSynced ? Icons.sync : Icons.sync_disabled,
            color: Colors.white,
            size: isVertical ? 22 : 28,
          ),
        ),
        if (showDifference)
          Positioned(
            top: 48, // IconButton 아래에 위치
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) => Text(
                  _getDifferenceText(context, pageDifference!),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// 재생 속도 버튼
class SpeedButton extends StatefulWidget {
  const SpeedButton({
    super.key,
    required this.onSpeedChanged,
    this.isVertical = false,
  });

  final ValueChanged<double> onSpeedChanged;
  final bool isVertical;

  @override
  State<SpeedButton> createState() => _SpeedButtonState();
}

class _SpeedButtonState extends State<SpeedButton> {
  static const _speeds = [0.7, 1.0, 1.5, 2.0];
  int _currentIndex = 1; // 기본값 1.0x

  void _toggleSpeed() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _speeds.length;
    });
    widget.onSpeedChanged(_speeds[_currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleSpeed,
      icon: Text(
        '${_speeds[_currentIndex]}x',
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.isVertical ? 13 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// 오디오 소스 버튼
class AudioSourceButton extends StatelessWidget {
  const AudioSourceButton({
    super.key,
    required this.isOriginalAudio,
    required this.onPressed,
    this.isVertical = false,
  });

  final bool isOriginalAudio;
  final VoidCallback onPressed;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVertical ? 7 : 10,
          vertical: isVertical ? 4 : 6,
        ),
        child: Text(
          isOriginalAudio ? 'Rec' : 'TTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: isVertical ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// 재생/정지 버튼
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.isVertical = false,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: isVertical ? 40 : 56,
      ),
    );
  }
}

// 15초 앞/뒤로 이동 버튼
class SkipButton extends StatefulWidget {
  const SkipButton({
    super.key,
    required this.isForward,
    required this.onPressed,
    this.isVertical = false,
  });

  final bool isForward; // true면 앞으로, false면 뒤로
  final VoidCallback onPressed;
  final bool isVertical;

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton> {
  bool _showBackground = false;

  void _handleTap() {
    setState(() {
      _showBackground = true;
    });

    widget.onPressed();

    // 애니메이션 후 배경 제거
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showBackground = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(widget.isVertical ? 6 : 8),
        decoration: BoxDecoration(
          color: _showBackground
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.isForward ? Icons.forward_10 : Icons.replay_10,
          color: Colors.white,
          size: widget.isVertical ? 32 : 44,
        ),
      ),
    );
  }
}

// 타임라인 슬라이더
class VideoTimelineSlider extends StatelessWidget {
  const VideoTimelineSlider({
    super.key,
    required this.currentTime,
    required this.totalTime,
    required this.onChanged,
  });

  final double currentTime;
  final double totalTime;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 시간 표시
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 30),
          child: Row(
            children: [
              Text(
                '${formatDuration(currentTime.toInt())} / ${formatDuration(totalTime.toInt())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // 슬라이더
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE3E3E3),
            thumbColor: const Color(0xFFFFFDFD),
            overlayColor: Colors.white.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: currentTime,
            min: 0,
            max: totalTime,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// 하단 컨트롤 바 (슬라이더 + 자막/대본/전체화면 버튼)
class BottomControlBar extends StatelessWidget {
  const BottomControlBar({
    super.key,
    required this.isVertical,
    required this.currentTime,
    required this.totalTime,
    required this.onTimeChanged,
    required this.isCaptionEnabled,
    required this.onCaptionToggle,
    required this.showTranscriptPanel,
    required this.onTranscriptToggle,
    required this.isFullscreen,
    required this.onFullscreenToggle,
  });

  final bool isVertical;
  final double currentTime;
  final double totalTime;
  final ValueChanged<double> onTimeChanged;
  final bool isCaptionEnabled;
  final VoidCallback onCaptionToggle;
  final bool showTranscriptPanel;
  final VoidCallback onTranscriptToggle;
  final bool isFullscreen;
  final VoidCallback onFullscreenToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 슬라이더 (세로 모드일 때는 전체화면 버튼과 함께 Stack으로)
        if (isVertical)
          Stack(
            children: [
              VideoTimelineSlider(
                currentTime: currentTime,
                totalTime: totalTime,
                onChanged: onTimeChanged,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: FullscreenButton(
                  isEnabled: isFullscreen,
                  onPressed: onFullscreenToggle,
                  isVertical: isVertical,
                ),
              ),
            ],
          ),
        // 버튼들
        if (!isVertical) ...[
          VideoTimelineSlider(
            currentTime: currentTime,
            totalTime: totalTime,
            onChanged: onTimeChanged,
          ),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 중앙
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CaptionButton(
                        isEnabled: isCaptionEnabled,
                        onPressed: onCaptionToggle,
                      ),
                      const SizedBox(width: 24),
                      TranscriptButton(onPressed: onTranscriptToggle),
                    ],
                  ),
                ),
                // 우측: 전체화면 버튼
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: FullscreenButton(
                    isEnabled: isFullscreen,
                    onPressed: onFullscreenToggle,
                    isVertical: isVertical,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// 자막 버튼
class CaptionButton extends StatelessWidget {
  const CaptionButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _IconTextButton(
      icon: isEnabled ? Icons.closed_caption : Icons.closed_caption_outlined,
      label: l10n.subtitle,
      onPressed: onPressed,
    );
  }
}

// 대본 버튼
class TranscriptButton extends StatelessWidget {
  const TranscriptButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _IconTextButton(
      icon: Icons.subject,
      label: l10n.transcript,
      onPressed: onPressed,
    );
  }
}

// 전체화면 버튼
class FullscreenButton extends StatelessWidget {
  const FullscreenButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
    required this.isVertical,
  });

  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: isVertical ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      onPressed: onPressed,
      icon: Icon(
        isEnabled ? Icons.fullscreen_exit : Icons.fullscreen,
        color: Colors.white,
        size: isVertical ? 24 : 28,
      ),
    );
  }
}

// 아이콘 + 텍스트 버튼 (내부 헬퍼 위젯)
// 가로모드에서만 표시되므로 항상 가로모드 크기 사용
class _IconTextButton extends StatelessWidget {
  const _IconTextButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 중앙 재생 컨트롤 (재생/정지 + 15초 앞뒤)
class CenterPlayControls extends StatelessWidget {
  const CenterPlayControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
    this.isVertical = false,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SkipButton(
          isForward: false,
          onPressed: onSkipBackward,
          isVertical: isVertical,
        ),
        SizedBox(width: isVertical ? 28 : 40),
        PlayPauseButton(
          isPlaying: isPlaying,
          onPressed: onPlayPause,
          isVertical: isVertical,
        ),
        SizedBox(width: isVertical ? 28 : 40),
        SkipButton(
          isForward: true,
          onPressed: onSkipForward,
          isVertical: isVertical,
        ),
      ],
    );
  }
}

// 상단 컨트롤 바
class TopControlBar extends StatelessWidget {
  const TopControlBar({
    super.key,
    required this.isVertical,
    required this.onBack,
    required this.isOriginalAudio,
    required this.onAudioToggle,
    required this.onSpeedChanged,
    required this.isSynced,
    required this.onSyncToggle,
    this.pageDifference,
  });

  final bool isVertical;

  final VoidCallback onBack;
  final bool isOriginalAudio;
  final VoidCallback onAudioToggle;
  final ValueChanged<double> onSpeedChanged;
  final bool isSynced;
  final VoidCallback onSyncToggle;
  final int? pageDifference;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          BackButton(onPressed: onBack, isVertical: isVertical),
          const Spacer(),
          AudioSourceButton(
            isOriginalAudio: isOriginalAudio,
            onPressed: onAudioToggle,
            isVertical: isVertical,
          ),
          const SizedBox(width: 8),
          SpeedButton(onSpeedChanged: onSpeedChanged, isVertical: isVertical),
          const SizedBox(width: 8),
          SyncButton(
            isSynced: isSynced,
            onPressed: onSyncToggle,
            pageDifference: pageDifference,
            isVertical: isVertical,
          ),
        ],
      ),
    );
  }
}

/// PDF 슬라이드 리스트
class PdfSlidesList extends StatefulWidget {
  const PdfSlidesList({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.itemWidth,
    required this.padding,
    required this.getCachedOrRenderPage,
    required this.onPageTap,
    this.getCachedImage,
    this.onScroll,
  });

  final int pageCount;
  final int currentPage;
  final double itemWidth;
  final EdgeInsets padding;
  final Future<Uint8List> Function(int pageNumber) getCachedOrRenderPage;
  final Uint8List? Function(int pageNumber)? getCachedImage; // 캐시된 이미지 직접 조회
  final void Function(int pageNumber) onPageTap;
  final void Function(int visibleEndPage)? onScroll; // 스크롤 시 보이는 마지막 페이지 전달

  @override
  State<PdfSlidesList> createState() => _PdfSlidesListState();
}

class _SlideThumbnailImage extends StatelessWidget {
  const _SlideThumbnailImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    if (bytes.isEmpty) {
      return _placeholder();
    }

    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
    );
  }
}

class _PdfSlidesListState extends State<PdfSlidesList> {
  final ScrollController _scrollController = ScrollController();
  // Future를 캐시하여 FutureBuilder가 매번 새로운 Future를 생성하지 않도록 함
  final Map<int, Future<Uint8List>> _futureCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    // 현재 스크롤 위치 계산
    final scrollOffset = _scrollController.offset;
    final viewportWidth = _scrollController.position.viewportDimension;

    // 보이는 영역의 끝 위치
    final visibleEnd = scrollOffset + viewportWidth;

    // 각 아이템의 너비 (itemWidth + separator)
    final itemTotalWidth = widget.itemWidth + 12;

    // 보이는 영역의 마지막 페이지 번호 계산
    final visibleEndPage = ((visibleEnd - widget.padding.left) / itemTotalWidth)
        .ceil();

    // 스크롤 콜백 호출 (범위 체크)
    if (visibleEndPage > 0 && visibleEndPage <= widget.pageCount) {
      widget.onScroll?.call(visibleEndPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      scrollDirection: Axis.horizontal,
      itemCount: widget.pageCount,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        final isCurrentPage = widget.currentPage == pageNumber;

        // 캐시된 이미지가 있는지 먼저 확인
        final cachedImage = widget.getCachedImage?.call(pageNumber);

        return GestureDetector(
          onTap: () => widget.onPageTap(pageNumber),
          child: Container(
            width: widget.itemWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isCurrentPage ? Colors.blue : Colors.grey[300]!,
                width: isCurrentPage ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: cachedImage != null
                ? _SlideThumbnailImage(bytes: cachedImage)
                : FutureBuilder<Uint8List>(
                    // Future를 캐시하여 매번 새로운 Future가 생성되지 않도록 함
                    future: _futureCache.putIfAbsent(
                      pageNumber,
                      () => widget.getCachedOrRenderPage(pageNumber),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return _SlideThumbnailImage(bytes: snapshot.data!);
                      }

                      // 에러 표시
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: widget.itemWidth > 160 ? 32 : 24,
                              ),
                              SizedBox(height: widget.itemWidth > 160 ? 8 : 4),
                              Text(
                                'Error',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: widget.itemWidth > 160 ? 12 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Page $pageNumber',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: widget.itemWidth > 160 ? 10 : 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // 로딩 중
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Slide',
                              style: TextStyle(
                                color: Colors.grey[isCurrentPage ? 500 : 400],
                                fontSize: widget.itemWidth > 160 ? 12 : 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: widget.itemWidth > 160 ? 4 : 2),
                            Text(
                              '$pageNumber',
                              style: TextStyle(
                                color: isCurrentPage
                                    ? Colors.blue
                                    : Colors.grey[widget.itemWidth > 160
                                          ? 800
                                          : 700],
                                fontSize: widget.itemWidth > 160 ? 32 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
