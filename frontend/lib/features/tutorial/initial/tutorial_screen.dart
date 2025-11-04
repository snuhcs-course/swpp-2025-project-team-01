// 튜토리얼 화면 - 앱 최초 실행 시 표시되는 5단계 가이드
import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/data/hive_manager.dart';

/// 앱 최초 실행 시 표시되는 튜토리얼 화면
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false; // 마지막 캐릭터 애니메이션 제어

  // 튜토리얼 이미지 경로
  final List<String> _tutorialImages = [
    'assets/tutorial/initial/tutorial_step1.png',
    'assets/tutorial/initial/tutorial_step2.png',
    'assets/tutorial/initial/tutorial_step3.png',
    'assets/tutorial/initial/tutorial_step4.png',
    'assets/tutorial/initial/tutorial_step5.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 다음 페이지로 이동 (즉시 전환, 애니메이션 없음)
  void _nextPage() {
    if (_currentPage < _tutorialImages.length - 1) {
      _pageController.jumpToPage(_currentPage + 1);
    }
  }

  // 마지막 페이지 도달 시 캐릭터 애니메이션 시작
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // 마지막 페이지에 도달했을 때
    if (page == _tutorialImages.length - 1 && !_showCharacter) {
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
        child: Stack(
          children: [
            // 페이지뷰 (슬라이드) - 즉시 전환
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: _tutorialImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imagePath = entry.value;
                return TutorialSlide(
                  imagePath: imagePath,
                  isLastSlide: index == _tutorialImages.length - 1,
                  showCharacter: _showCharacter,
                  onDone: _completeTutorial,
                );
              }).toList(),
            ),

            // 페이지 카운터 (NEXT 버튼 바로 위, 마지막 페이지 제외)
            if (_currentPage < _tutorialImages.length - 1)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: TutorialIndicators(
                    pageCount: _tutorialImages.length,
                    currentPage: _currentPage,
                  ),
                ),
              ),

            // 다음 버튼 (마지막 페이지 제외)
            if (_currentPage < _tutorialImages.length - 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 50,
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 마지막 페이지에서 나타나는 캐릭터와 말풍선 애니메이션
class TutorialCharacterAnimation extends StatefulWidget {
  const TutorialCharacterAnimation({super.key, required this.onDone});

  final VoidCallback onDone;

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
          end: Offset.zero, // 원래 위치로
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
          top: MediaQuery.of(context).size.height * 0.25, // 화면 높이의 25% 지점
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 캐릭터 이미지
                Image.asset(
                  'assets/tutorial/tutorial_character.png',
                  width: 150,
                ),

                const SizedBox(height: 24),
                // 말풍선 이미지
                Image.asset(
                  'assets/tutorial/tutorial_speech_bubble.png',
                  width: 300,
                ),

                const SizedBox(height: 12),

                // DONE 버튼
                SizedBox(
                  width: 120,
                  height: 50,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
  });

  final String imagePath;
  final bool isLastSlide;
  final bool showCharacter;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 메인 이미지 (화면 전체)
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover, // 또는 BoxFit.contain
          ),
        ),

        // 마지막 슬라이드일 때 캐릭터 애니메이션
        if (isLastSlide && showCharacter)
          TutorialCharacterAnimation(onDone: onDone),
      ],
    );
  }
}
