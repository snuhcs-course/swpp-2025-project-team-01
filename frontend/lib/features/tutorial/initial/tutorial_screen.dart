// 튜토리얼 화면 - 앱 최초 실행 시 표시되는 5단계 가이드
import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:flutter/services.dart';
import 'package:re_view/data/hive_manager.dart';

/// 앱 최초 실행 시 표시되는 튜토리얼 화면
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  // UI 스케일링을 위한 기준 화면 크기 (Medium Phone)
  static const double _basePortraitHeight = 844.0;
  static const double _baseLandscapeWidth = 844.0;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false; // 마지막 캐릭터 애니메이션 제어
  Orientation? _initialOrientation;

  // 튜토리얼 이미지 경로
  final List<String> _portraitImages = [
    'assets/tutorial/initial/tutorial_step1.png',
    'assets/tutorial/initial/tutorial_step2.png',
    'assets/tutorial/initial/tutorial_step3.png',
    'assets/tutorial/initial/tutorial_step4.png',
    'assets/tutorial/initial/tutorial_step5.png',
  ];

  // 가로 모드 튜토리얼 이미지
  final List<String> _landscapeImages = [
    'assets/tutorial/initial/tutorial_landscape_step1.png',
    'assets/tutorial/initial/tutorial_landscape_step2.png',
    'assets/tutorial/initial/tutorial_landscape_step3.png',
    'assets/tutorial/initial/tutorial_landscape_step4.png',
    'assets/tutorial/initial/tutorial_landscape_step5.png',
  ];

  List<String> get _currentImages =>
      _initialOrientation == Orientation.landscape
      ? _landscapeImages
      : _portraitImages;

  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 첫 프레임에서 화면 방향을 결정하고 고정
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
    // 튜토리얼이 끝나면 화면 방향 제한 해제
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pageController.dispose();
    super.dispose();
  }

  // 다음 페이지로 이동 (즉시 전환, 애니메이션 없음)
  void _nextPage() {
    if (_currentPage < _currentImages.length - 1) {
      _pageController.jumpToPage(_currentPage + 1);
    }
  }

  // 튜토리얼 시작 시 화면 방향 고정
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

  // 마지막 페이지 도달 시 캐릭터 애니메이션 시작
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // 마지막 페이지에 도달했을 때
    if (page == _currentImages.length - 1 && !_showCharacter) {
      // 1초 후 캐릭터 표시
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _showCharacter = true;
          });
        }
      });
    }
  }

  // 튜토리얼 완료 및 홈으로 이동
  Future<void> _completeTutorial() async {
    await HiveManager.instance.completeTutorial();
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF656565),
      body: SafeArea(
        child: _initialOrientation == null
            ? const Center(child: CircularProgressIndicator())
            : OrientationBuilder(
                builder: (context, orientation) {
                  final size = MediaQuery.of(context).size;
                  // 화면 방향에 따라 scaleFactor 계산
                  final scaleFactor = orientation == Orientation.portrait
                      ? size.height /
                            _basePortraitHeight // 높이 비율
                      : size.width / _baseLandscapeWidth; // 너비 비율

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
                    return _buildPortraitLayout(pageView, scaleFactor);
                  } else {
                    return _buildLandscapeLayout(pageView, scaleFactor);
                  }
                },
              ),
      ),
    );
  }

  // 세로 모드 레이아웃
  Widget _buildPortraitLayout(Widget pageView, double scaleFactor) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        pageView,
        if (_currentPage < _currentImages.length - 1) ...[
          Positioned(
            bottom: screenHeight * 0.1, // 100
            left: 0,
            right: 0,
            child: Center(
              child: Transform.scale(
                scale: scaleFactor * 1.1,
                child: TutorialIndicators(
                  pageCount: _currentImages.length,
                  currentPage: _currentPage,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.03, // 40
            left: 0,
            right: 0,
            child: Center(
              child: _buildNextButton(scaleFactor: 1.1),
            ), // 크기 10% 증가
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
            bottom: screenHeight * 0.11, // 43
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
            bottom: screenHeight * 0.008, // 2
            left: 0,
            right: 0,
            child: Center(
              child: _buildNextButton(scaleFactor: scaleFactor * 0.8),
            ),
          ),
        ],
      ],
    );
  }

  // NEXT 버튼 위젯
  Widget _buildNextButton({required double scaleFactor}) {
    return SizedBox(
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 페이드 인 애니메이션 (0 -> 1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // 위에서 아래로 슬라이드 애니메이션
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -0.3), // 위쪽에서 시작
          end: Offset.zero,
        ).animate(
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
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.3,
        ), // 화면 높이의 15% 지점
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 캐릭터 이미지
                Image.asset(
                  'assets/tutorial/initial/tutorial_character.png',
                  width: 120 * widget.scaleFactor,
                ),

                SizedBox(height: 24 * widget.scaleFactor),
                // 말풍선 이미지
                Image.asset(
                  'assets/tutorial/initial/tutorial_speech_bubble.png',
                  width: 300 * widget.scaleFactor,
                ),

                SizedBox(height: 12 * widget.scaleFactor),

                // DONE 버튼
                SizedBox(
                  width: 120 * widget.scaleFactor,
                  height: 50 * widget.scaleFactor,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4E8D4),
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(
                        side: BorderSide(color: Colors.black, width: 4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontFamily: 'NanumSquare',
                        fontSize: 20,
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
    // 세로 모드와 동일한 레이아웃으로 변경
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.topCenter,
            // 가로 모드에 맞게 전체적으로 크기 축소
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/tutorial/initial/tutorial_character.png',
                  width: 150 * widget.scaleFactor * 0.9,
                ),
                SizedBox(height: 4 * widget.scaleFactor),
                Image.asset(
                  'assets/tutorial/initial/tutorial_speech_bubble.png',
                  width: 300 * widget.scaleFactor * 0.9,
                ),
                SizedBox(height: 4 * widget.scaleFactor),
                SizedBox(
                  width: 100 * widget.scaleFactor * 0.8,
                  height: 50 * widget.scaleFactor * 0.9,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4E8D4),
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(
                        side: BorderSide(color: Colors.black, width: 4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontFamily: 'NanumSquare',
                        fontSize: 20,
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

/// 현재 튜토리얼 페이지를 숫자로 표시 (예: 1/5)
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
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
            TutorialCharacterAnimation(onDone: onDone, scaleFactor: scaleFactor)
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
