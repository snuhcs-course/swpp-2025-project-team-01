// 튜토리얼 화면 - 앱 최초 실행 시 표시되는 5단계 가이드
import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/tutorial/widgets/tutorial_indicators.dart';
import 'package:re_view/features/tutorial/widgets/tutorial_slide.dart';

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
    'assets/tutorial/tutorial_step1.png',
    'assets/tutorial/tutorial_step2.png',
    'assets/tutorial/tutorial_step3.png',
    'assets/tutorial/tutorial_step4.png',
    'assets/tutorial/tutorial_step5.png',
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
