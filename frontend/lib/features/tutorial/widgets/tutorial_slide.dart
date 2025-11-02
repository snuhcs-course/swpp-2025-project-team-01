// 튜토리얼 슬라이드 위젯
import 'package:flutter/material.dart';
import 'package:re_view/features/tutorial/widgets/tutorial_character.dart';

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
