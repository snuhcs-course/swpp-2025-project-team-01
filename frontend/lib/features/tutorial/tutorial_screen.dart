// 튜토리얼 화면 - 앱 최초 실행 및 플레이어 최초 진입 시 표시되는 가이드
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/tutorial/tutorial_common.dart';

/// 통합 튜토리얼 화면 (Initial & Player)
class TutorialScreen extends StatefulWidget {
  const TutorialScreen._({
    super.key,
    required this.type,
    this.initialOrientation,
  });

  /// 앱 최초 실행 시 표시되는 튜토리얼
  factory TutorialScreen.initial({Key? key}) {
    return TutorialScreen._(key: key, type: TutorialType.initial);
  }

  /// 플레이어 최초 진입 시 표시되는 튜토리얼
  factory TutorialScreen.player({
    Key? key,
    required Orientation initialOrientation,
  }) {
    return TutorialScreen._(
      key: key,
      type: TutorialType.player,
      initialOrientation: initialOrientation,
    );
  }

  final TutorialType type;
  final Orientation? initialOrientation;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false;
  Orientation? _initialOrientation;

  List<String> get _currentImages {
    if (widget.type == TutorialType.player) {
      return _initialOrientation == Orientation.portrait
          ? TutorialAssets.playerPortraitImages
          : TutorialAssets.playerLandscapeImages;
    } else {
      return _initialOrientation == Orientation.landscape
          ? TutorialAssets.initialLandscapeImages
          : TutorialAssets.initialPortraitImages;
    }
  }

  @override
  void initState() {
    super.initState();

    // Player는 생성자에서 orientation을 받고, Initial은 MediaQuery에서 가져옴
    if (widget.type == TutorialType.player) {
      _initialOrientation = widget.initialOrientation;
      _lockOrientation(widget.initialOrientation!);
    } else {
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
  }

  @override
  void dispose() {
    // Player의 경우에만 orientation 해제
    if (widget.type == TutorialType.player) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
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
      Future.delayed(TutorialConstants.animationDuration, () {
        if (mounted) {
          setState(() {
            _showCharacter = true;
          });
        }
      });
    }
  }

  Future<void> _completeTutorial() async {
    if (widget.type == TutorialType.player) {
      await HiveManager.instance.completePlayerTutorial();
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      await HiveManager.instance.completeTutorial();
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
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
                          final isLastSlide =
                              index == _currentImages.length - 1;

                          return TutorialSlide(
                            imagePath: imagePath,
                            isLastSlide: isLastSlide,
                            showCharacter: _showCharacter,
                            characterAnimation: TutorialCharacterAnimation(
                              type: widget.type,
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
