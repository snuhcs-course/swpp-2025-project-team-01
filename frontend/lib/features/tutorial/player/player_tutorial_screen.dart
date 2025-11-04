// 플레이어 튜토리얼 화면 - 플레이어 최초 진입 시 표시되는 가이드
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 플레이어 최초 진입 시 표시되는 튜토리얼 화면
class PlayerTutorialScreen extends StatefulWidget {
  const PlayerTutorialScreen({super.key});

  @override
  State<PlayerTutorialScreen> createState() => _PlayerTutorialScreenState();
}

class _PlayerTutorialScreenState extends State<PlayerTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCharacter = false;
  bool _isRotatedRight = false; // 오른쪽 회전 감지
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  final List<String> _tutorialImages = [
    'assets/tutorial/player/player_tutorial_step1.png',
    'assets/tutorial/player/player_tutorial_step2.png',
    'assets/tutorial/player/player_tutorial_step3.png',
    'assets/tutorial/player/player_tutorial_step4.png',
  ];

  @override
  void initState() {
    super.initState();
    // 세로 방향으로만 고정 (모든 페이지)
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 가속도계로 오른쪽 회전 감지
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      // 세로(정상): x≈0, y≈0, z≈-9.8
      // 오른쪽 90도 회전: x≈-9.8, y≈0, z≈0
      final isRightRotated =
          event.x < -7.0 && event.y.abs() < 5.0 && event.z.abs() < 5.0;

      if (isRightRotated != _isRotatedRight) {
        setState(() {
          _isRotatedRight = isRightRotated;
        });
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _tutorialImages.length - 1) {
      _pageController.jumpToPage(_currentPage + 1);
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // 마지막 페이지에 도달 시 캐릭터 표시
    if (page == _tutorialImages.length - 1 && !_showCharacter) {
      Future.delayed(const Duration(milliseconds: 2400), () {
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
    // 마지막 페이지 + 오른쪽 회전 시 180도 뒤집기
    final shouldFlip =
        _currentPage == _tutorialImages.length - 1 && _isRotatedRight;

    return Scaffold(
      backgroundColor: const Color(0xFF656565),
      body: RotatedBox(
        quarterTurns: shouldFlip ? 2 : 0,
        child: SafeArea(
          child: Stack(
            children: [
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

              // 페이지 카운터
              if (_currentPage < _tutorialImages.length - 1)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TutorialIndicators(
                      pageCount: _tutorialImages.length,
                      currentPage: _currentPage,
                    ),
                  ),
                ),

              // NEXT 버튼
              if (_currentPage < _tutorialImages.length - 1)
                Positioned(
                  bottom: 20,
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 페이드 인 애니메이션 (0 -> 1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(1.0, 0), // 화면 오른쪽 끝에서 시작
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
    return Positioned.fill(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. DONE 버튼 (오른쪽으로 90도 회전)
                  RotatedBox(
                    quarterTurns: 1, // 시계 방향으로 90도 회전
                    child: SizedBox(
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
                  ),
                  const SizedBox(width: 12),
                  // 2. 말풍선 이미지
                  Flexible(
                    flex: 3,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Image.asset(
                        'assets/tutorial/player/player_tutorial_speech_bubble.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
        color: Colors.black.withAlpha(80), // withValues는 deprecated
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
        Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),

        // 마지막 슬라이드일 때 캐릭터 애니메이션
        if (isLastSlide && showCharacter)
          TutorialCharacterAnimation(onDone: onDone),
      ],
    );
  }
}
