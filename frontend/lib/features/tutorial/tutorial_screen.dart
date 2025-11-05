// 튜토리얼 화면 - 앱 최초 실행 시 표시되는 5단계 가이드
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/tutorial/tutorial_common.dart';

/// 앱 최초 실행 시 표시되는 튜토리얼 화면
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false;
  Orientation? _initialOrientation;

  List<String> get _currentImages =>
      _initialOrientation == Orientation.landscape
          ? TutorialAssets.initialLandscapeImages
          : TutorialAssets.initialPortraitImages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final orientation = MediaQuery.of(context).orientation;
        setState(() {
          _initialOrientation = orientation;
        });
        _lockOrientation(orientation);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pageController.dispose();
    super.dispose();
  }

  void _lockOrientation(Orientation orientation) {
    if (orientation == Orientation.portrait) {
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
      Future.delayed(TutorialConstants.characterDelayShort, () {
        if (mounted) {
          setState(() {
            _showCharacter = true;
          });
        }
      });
    }
  }

  Future<void> _completeTutorial() async {
    await HiveManager.instance.completeTutorial();
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorialConstants.backgroundColor,
      body: SafeArea(
        child: _initialOrientation == null
            ? const Center(child: CircularProgressIndicator())
            : OrientationBuilder(
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
                            characterAnimation: InitialTutorialCharacterAnimation(
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

/// 마지막 페이지 캐릭터 애니메이션 (위에서 아래로)
class InitialTutorialCharacterAnimation extends BaseTutorialCharacterAnimation {
  const InitialTutorialCharacterAnimation({
    super.key,
    required super.onDone,
    required super.scaleFactor,
    required this.orientation,
  }) : super(duration: TutorialConstants.animationDuration);

  final Orientation orientation;

  @override
  State<InitialTutorialCharacterAnimation> createState() =>
      _InitialTutorialCharacterAnimationState();
}

class _InitialTutorialCharacterAnimationState
    extends BaseTutorialCharacterAnimationState<
        InitialTutorialCharacterAnimation> {
  @override
  Animation<Offset> createSlideAnimation() {
    return Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final isPortrait = widget.orientation == Orientation.portrait;

    final characterWidth = (isPortrait
            ? TutorialConstants.characterImageWidth
            : TutorialConstants.characterImageWidthLandscape) *
        widget.scaleFactor;

    final spacing1 = (isPortrait
            ? TutorialConstants.spacingXLarge
            : TutorialConstants.spacingSmall) *
        widget.scaleFactor;

    final spacing2 = (isPortrait
            ? TutorialConstants.spacingLarge
            : TutorialConstants.spacingSmall) *
        widget.scaleFactor;

    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              TutorialAssets.initialCharacter,
              width: characterWidth,
            ),
            SizedBox(height: spacing1),
            Image.asset(
              TutorialAssets.initialSpeechBubble,
              width: TutorialConstants.speechBubbleWidth * widget.scaleFactor,
            ),
            SizedBox(height: spacing2),
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
