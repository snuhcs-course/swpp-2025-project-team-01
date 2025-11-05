// 플레이어 튜토리얼 화면 - 플레이어 최초 진입 시 표시되는 가이드
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_view/data/hive_manager.dart';

/// 플레이어 최초 진입 시 표시되는 튜토리얼 화면
class PlayerTutorialScreen extends StatefulWidget {
  const PlayerTutorialScreen({super.key, required this.initialOrientation});

  final Orientation initialOrientation;

  @override
  State<PlayerTutorialScreen> createState() => _PlayerTutorialScreenState();
}

class _PlayerTutorialScreenState extends State<PlayerTutorialScreen> {
  // UI 스케일링을 위한 기준 화면 크기 (Medium Phone)
  static const double _basePortraitHeight = 844.0;
  static const double _baseLandscapeWidth = 844.0;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false; // 마지막 페이지 애니메이션 제어

  // 세로 모드 튜토리얼 이미지
  final List<String> _portraitImages = [
    'assets/tutorial/player/player_tutorial_step1.png',
    'assets/tutorial/player/player_tutorial_step2.png',
    'assets/tutorial/player/player_tutorial_step3.png',
    'assets/tutorial/player/player_tutorial_step4.png',
  ];

  // 가로 모드 튜토리얼 이미지
  final List<String> _landscapeImages = [
    'assets/tutorial/player/player_tutorial_landscape_step1.png',
    'assets/tutorial/player/player_tutorial_landscape_step2.png',
    'assets/tutorial/player/player_tutorial_landscape_step3.png',
  ];

  List<String> get _currentImages =>
      widget.initialOrientation == Orientation.portrait
      ? _portraitImages
      : _landscapeImages;

  @override
  void initState() {
    super.initState();
    _lockOrientation();
  }

  @override
  void dispose() {
    // 튜토리얼이 끝나면 화면 방향 제한 해제
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pageController.dispose();
    super.dispose();
  }

  // 튜토리얼 시작 시 화면 방향 고정
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

  // 다음 페이지로 이동
  void _nextPage() {
    if (_currentPage < _currentImages.length - 1) {
      _pageController.jumpToPage(_currentPage + 1);
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // 마지막 페이지에 도달 시 캐릭터 표시
    if (page == _currentImages.length - 1 && !_showCharacter) {
      // 가로/세로 모드에 따라 애니메이션 시작 시간 조절
      final delay = widget.initialOrientation == Orientation.portrait
          ? const Duration(milliseconds: 2400)
          : const Duration(milliseconds: 2400);
      Future.delayed(delay, () {
        if (mounted) {
          setState(() {
            _showCharacter = true;
          });
        }
      });
    }
  }

  // 튜토리얼 완료 처리
  Future<void> _completeTutorial() async {
    await HiveManager.instance.completePlayerTutorial();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF656565),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final size = MediaQuery.of(context).size;
            // 화면 방향에 따라 scaleFactor 계산
            final scaleFactor = orientation == Orientation.portrait
                ? size.height / _basePortraitHeight // 높이 비율
                : size.width / _baseLandscapeWidth; // 너비 비율

            // PageView는 공통으로 사용
            final pageView = PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: _currentImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imagePath = entry.value;
                return TutorialSlide(
                  imagePath: imagePath,
                  isLastSlide: index == _currentImages.length - 1,
                  showCharacter: _showCharacter,
                  onDone: _completeTutorial,
                  orientation: orientation,
                  scaleFactor: scaleFactor,
                );
              }).toList(),
            );

            if (orientation == Orientation.portrait) {
              return _buildPortraitLayout(pageView);
            } else {
              return _buildLandscapeLayout(pageView, scaleFactor);
            }
          },
        ),
      ),
    );
  }

  // 세로 모드 레이아웃
  Widget _buildPortraitLayout(Widget pageView) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        pageView,
        if (_currentPage < _currentImages.length - 1) ...[
          Positioned(
            bottom: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.scale(
                scale: 1.1,
                child: TutorialIndicators(
                  pageCount: _currentImages.length,
                  currentPage: _currentPage,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.03,
            left: 0,
            right: 0,
            child: Center(child: _buildNextButton(scaleFactor: 1.1)),
          ),
        ],
      ],
    );
  }

  // 가로 모드 레이아웃
  Widget _buildLandscapeLayout(Widget pageView, double scaleFactor) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        pageView,
        if (_currentPage < _currentImages.length - 1) ...[
          Positioned(
            bottom: screenHeight * 0.11,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.scale(
                scale: scaleFactor * 0.8,
                child: TutorialIndicators(
                  pageCount: _currentImages.length,
                  currentPage: _currentPage,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.008,
            left: 0,
            right: 0,
            child: Center(
              child: _buildNextButton(
                key: const ValueKey('next-button-landscape'),
                scaleFactor: scaleFactor * 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // NEXT 버튼 위젯
  Widget _buildNextButton({Key? key, required double scaleFactor}) {
    return SizedBox(
      key: key,
      width: 120 * scaleFactor,
      height: 50 * scaleFactor,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4E8D4),
          foregroundColor: Colors.black,
          shape: const StadiumBorder(
            side: BorderSide(color: Colors.black, width: 2),
          ),
          elevation: 0,
        ),
        child: const Text(
          'NEXT',
          style: TextStyle(
            fontFamily: 'NanumSquare',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 세로 모드: 마지막 페이지 캐릭터 애니메이션
class TutorialCharacterAnimation extends StatefulWidget {
  const TutorialCharacterAnimation({
    super.key,
    required this.onDone,
    required this.scaleFactor,
  });

  final VoidCallback onDone;
  final double scaleFactor;

  @override
  State<TutorialCharacterAnimation> createState() =>
      _TutorialCharacterAnimationState();
}

class _TutorialCharacterAnimationState extends State<TutorialCharacterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // 오른쪽에서 왼쪽으로 슬라이드
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );

    // 애니메이션 시작
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding( // 화면 높이에 비례하여 하단 여백 조정
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. DONE 버튼 (오른쪽으로 90도 회전)
                  RotatedBox(
                    quarterTurns: 1, // 시계 방향으로 90도 회전
                    child: SizedBox(
                      width: 120 * widget.scaleFactor * 0.7,
                      height: 50 * widget.scaleFactor * 0.7,
                      child: ElevatedButton(
                        onPressed: widget.onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4E8D4),
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontFamily: 'NanumSquare',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * widget.scaleFactor),
                  // 2. 말풍선 이미지
                  Flexible(
                    flex: 3,
                    child: Transform.scale(
                      scale: widget.scaleFactor * 0.8,
                      child: Image.asset(
                        'assets/tutorial/player/player_tutorial_speech_bubble.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * widget.scaleFactor),
                  // 3. 캐릭터 이미지
                  Flexible(
                    flex: 2,
                    child: Image.asset(
                      'assets/tutorial/player/player_tutorial_character.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 가로 모드: 마지막 페이지 캐릭터 애니메이션
class LandscapeTutorialCharacterAnimation extends StatefulWidget {
  const LandscapeTutorialCharacterAnimation({
    super.key,
    required this.onDone,
    required this.scaleFactor,
  });

  final VoidCallback onDone;
  final double scaleFactor;

  @override
  State<LandscapeTutorialCharacterAnimation> createState() =>
      _LandscapeTutorialCharacterAnimationState();
}

class _LandscapeTutorialCharacterAnimationState
    extends State<LandscapeTutorialCharacterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // initial 튜토리얼과 동일하게 위에서 아래로 슬라이드하도록 변경
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -0.3), // 위쪽에서 시작
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/tutorial/player/player_tutorial_character_landscape.png',
                  width: 150 * widget.scaleFactor * 0.9,
                ),
                SizedBox(height: 4 * widget.scaleFactor),
                SizedBox(
                  height: 100 * widget.scaleFactor * 0.9,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Image.asset(
                      'assets/tutorial/player/player_tutorial_speech_bubble.png',
                      width: 300 * widget.scaleFactor * 0.9,
                    ),
                  ),
                ),
                SizedBox(height: 4 * widget.scaleFactor),
                SizedBox(
                  width: 120 * widget.scaleFactor * 0.9,
                  height: 50 * widget.scaleFactor * 0.9,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4E8D4),
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(
                        side: BorderSide(color: Colors.black, width: 2),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontFamily: 'NanumSquare',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 현재 튜토리얼 페이지를 숫자로 표시 (예: 1/4)
class TutorialIndicators extends StatelessWidget {
  const TutorialIndicators({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${currentPage + 1}/$pageCount',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 개별 튜토리얼 슬라이드를 표시하는 위젯
class TutorialSlide extends StatelessWidget {
  const TutorialSlide({
    super.key,
    required this.imagePath,
    required this.isLastSlide,
    required this.showCharacter,
    required this.onDone,
    required this.orientation,
    required this.scaleFactor,
  });

  final String imagePath;
  final bool isLastSlide;
  final bool showCharacter;
  final Orientation orientation;
  final double scaleFactor;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 메인 이미지 (화면 전체)
        Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.contain)),

        // 마지막 슬라이드일 때 캐릭터 애니메이션
        if (isLastSlide && showCharacter) ...[
          if (orientation == Orientation.portrait)
            TutorialCharacterAnimation(
                onDone: onDone, scaleFactor: scaleFactor)
          else
            LandscapeTutorialCharacterAnimation(
              onDone: onDone,
              scaleFactor: scaleFactor,
            ),
        ],
      ],
    );
  }
}
