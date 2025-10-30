// 튜토리얼 마지막 페이지 캐릭터 애니메이션 위젯
import 'package:flutter/material.dart';

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
