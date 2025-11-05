// 플레이어 튜토리얼 화면 - 플레이어 최초 진입 시 표시되는 가이드
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/tutorial/tutorial_common.dart';

/// 플레이어 최초 진입 시 표시되는 튜토리얼 화면
class PlayerTutorialScreen extends StatefulWidget {
  const PlayerTutorialScreen({super.key, required this.initialOrientation});

  final Orientation initialOrientation;

  @override
  State<PlayerTutorialScreen> createState() => _PlayerTutorialScreenState();
}

class _PlayerTutorialScreenState extends State<PlayerTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false;

  List<String> get _currentImages =>
      widget.initialOrientation == Orientation.portrait
          ? TutorialAssets.playerPortraitImages
          : TutorialAssets.playerLandscapeImages;

  @override
  void initState() {
    super.initState();
    _lockOrientation();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pageController.dispose();
    super.dispose();
  }

  void _lockOrientation() {
    if (widget.initialOrientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _nextPage() {
    if (_currentPage < _currentImages.length - 1) {
      _pageController.jumpToPage(_currentPage + 1);
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    if (page == _currentImages.length - 1 && !_showCharacter) {
      Future.delayed(TutorialConstants.characterDelayLong, () {
        if (mounted) {
          setState(() {
            _showCharacter = true;
          });
        }
      });
    }
  }

  Future<void> _completeTutorial() async {
    await HiveManager.instance.completePlayerTutorial();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorialConstants.backgroundColor,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final size = MediaQuery.of(context).size;
            final scaleFactor = TutorialConstants.calculateScaleFactor(
              size,
              orientation,
            );

            return Stack(
              children: [
                // Background - PageView with slides
                PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _currentImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imagePath = entry.value;
                    final isLastSlide = index == _currentImages.length - 1;

                    return TutorialSlide(
                      imagePath: imagePath,
                      isLastSlide: isLastSlide,
                      showCharacter: _showCharacter,
                      characterAnimation: PlayerTutorialCharacterAnimation(
                        onDone: _completeTutorial,
                        scaleFactor: scaleFactor,
                        orientation: orientation,
                      ),
                    );
                  }).toList(),
                ),

                // Navigator (Indicator + Next Button) - only show when not on last page
                if (_currentPage < _currentImages.length - 1)
                  TutorialNavigator(
                    pageCount: _currentImages.length,
                    currentPage: _currentPage,
                    onNext: _nextPage,
                    scaleFactor: scaleFactor,
                    orientation: orientation,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 마지막 페이지 캐릭터 애니메이션 (Portrait: 오른쪽에서 왼쪽, Landscape: 위에서 아래)
class PlayerTutorialCharacterAnimation extends BaseTutorialCharacterAnimation {
  const PlayerTutorialCharacterAnimation({
    super.key,
    required super.onDone,
    required super.scaleFactor,
    required this.orientation,
  }) : super(
          duration: orientation == Orientation.portrait
              ? TutorialConstants.animationDurationLong
              : TutorialConstants.animationDuration,
        );

  final Orientation orientation;

  @override
  State<PlayerTutorialCharacterAnimation> createState() =>
      _PlayerTutorialCharacterAnimationState();
}

class _PlayerTutorialCharacterAnimationState
    extends BaseTutorialCharacterAnimationState<
        PlayerTutorialCharacterAnimation> {
  @override
  Animation<Offset> createSlideAnimation() {
    return Tween<Offset>(
      begin: widget.orientation == Orientation.portrait
          ? const Offset(1.0, 0) // Portrait: 오른쪽에서 왼쪽으로
          : const Offset(0, -0.3), // Landscape: 위에서 아래로
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = widget.orientation == Orientation.portrait;

    if (isPortrait) {
      // Portrait: 하단에 가로로 배치
      return Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: screenHeight * TutorialConstants.portraitButtonBottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // DONE 버튼 (시계 방향 90도 회전)
                TutorialButton(
                  text: 'DONE',
                  onPressed: widget.onDone,
                  scaleFactor: widget.scaleFactor * 0.75,
                  quarterTurns: 1,
                ),
                SizedBox(
                    width: TutorialConstants.spacingLarge * widget.scaleFactor),
                // 말풍선
                Flexible(
                  flex: 3,
                  child: Image.asset(
                    TutorialAssets.playerSpeechBubble,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                    width:
                        TutorialConstants.spacingMedium * widget.scaleFactor),
                // 캐릭터
                Flexible(
                  flex: 2,
                  child: Image.asset(
                    TutorialAssets.playerCharacter,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Landscape: 상단에 세로로 배치
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            top: screenHeight * TutorialConstants.landscapeCharacterTop,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                TutorialAssets.playerCharacterLandscape,
                width: TutorialConstants.characterImageWidthLandscape *
                    widget.scaleFactor,
              ),
              SizedBox(
                  height: TutorialConstants.spacingMedium * widget.scaleFactor),
              // 말풍선 (반시계 방향 90도 회전)
              SizedBox(
                height: 100 * widget.scaleFactor,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Image.asset(
                    TutorialAssets.playerSpeechBubble,
                    width: TutorialConstants.speechBubbleWidth *
                        widget.scaleFactor,
                  ),
                ),
              ),
              SizedBox(
                  height: TutorialConstants.spacingMedium * widget.scaleFactor),
              TutorialButton(
                text: 'DONE',
                onPressed: widget.onDone,
                scaleFactor: widget.scaleFactor,
              ),
            ],
          ),
        ),
      );
    }
  }
}
