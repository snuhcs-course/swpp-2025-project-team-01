import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:re_view/core/utils.dart';

/// 비디오 컨트롤 공통 위젯 모듈

// 뒤로가기 버튼
class BackButton extends StatelessWidget {
  const BackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
    );
  }
}

// 싱크 토글 버튼
class SyncButton extends StatelessWidget {
  const SyncButton({
    super.key,
    required this.isSynced,
    required this.onPressed,
  });

  final bool isSynced;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isSynced ? Icons.sync : Icons.sync_disabled,
        color: Colors.white,
        size: 28,
      ),
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
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isEnabled ? Icons.closed_caption : Icons.closed_caption_outlined,
        color: Colors.white,
        size: 28,
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
  });

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 56,
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
  });

  final bool isForward; // true면 앞으로, false면 뒤로
  final VoidCallback onPressed;

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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _showBackground
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isForward ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            const Text(
              '15',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
        // 시간 표시
        Padding(
          padding: const EdgeInsets.only(left: 1, right: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(currentTime.toInt()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '-${formatDuration((totalTime - currentTime).toInt())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
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
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SkipButton(isForward: false, onPressed: onSkipBackward),
        const SizedBox(width: 40),
        PlayPauseButton(isPlaying: isPlaying, onPressed: onPlayPause),
        const SizedBox(width: 40),
        SkipButton(isForward: true, onPressed: onSkipForward),
      ],
    );
  }
}

// 상단 컨트롤 바 (세로 모드용)
class TopControlBarPortrait extends StatelessWidget {
  const TopControlBarPortrait({
    super.key,
    required this.onBack,
    required this.isSynced,
    required this.onSyncToggle,
  });

  final VoidCallback onBack;
  final bool isSynced;
  final VoidCallback onSyncToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          BackButton(onPressed: onBack),
          const Spacer(),
          SyncButton(isSynced: isSynced, onPressed: onSyncToggle),
        ],
      ),
    );
  }
}

// 상단 컨트롤 바 (가로 모드용)
class TopControlBarLandscape extends StatelessWidget {
  const TopControlBarLandscape({
    super.key,
    required this.onBack,
    required this.isCaptionEnabled,
    required this.onCaptionToggle,
    required this.isSynced,
    required this.onSyncToggle,
  });

  final VoidCallback onBack;
  final bool isCaptionEnabled;
  final VoidCallback onCaptionToggle;
  final bool isSynced;
  final VoidCallback onSyncToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          BackButton(onPressed: onBack),
          const Spacer(),
          CaptionButton(
            isEnabled: isCaptionEnabled,
            onPressed: onCaptionToggle,
          ),
          const SizedBox(width: 8),
          SyncButton(isSynced: isSynced, onPressed: onSyncToggle),
        ],
      ),
    );
  }
}

/// PDF 슬라이드 리스트 (가로/세로 모드 공통 사용)
class PdfSlidesList extends StatelessWidget {
  const PdfSlidesList({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.itemWidth,
    required this.padding,
    required this.getCachedOrRenderPage,
    required this.onPageTap,
  });

  final int pageCount;
  final int currentPage;
  final double itemWidth;
  final EdgeInsets padding;
  final Future<Uint8List> Function(int pageNumber) getCachedOrRenderPage;
  final void Function(int pageNumber) onPageTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      scrollDirection: Axis.horizontal,
      itemCount: pageCount,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        final isCurrentPage = currentPage == pageNumber;

        return GestureDetector(
          onTap: () => onPageTap(pageNumber),
          child: Container(
            width: itemWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isCurrentPage ? Colors.blue : Colors.grey[300]!,
                width: isCurrentPage ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FutureBuilder<Uint8List>(
              future: getCachedOrRenderPage(pageNumber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Slide',
                        style: TextStyle(
                          color: Colors.grey[isCurrentPage ? 500 : 400],
                          fontSize: itemWidth > 160 ? 12 : 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: itemWidth > 160 ? 4 : 2),
                      Text(
                        '$pageNumber',
                        style: TextStyle(
                          color: isCurrentPage
                              ? Colors.blue
                              : Colors.grey[itemWidth > 160 ? 800 : 700],
                          fontSize: itemWidth > 160 ? 32 : 24,
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
