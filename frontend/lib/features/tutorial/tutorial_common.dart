// 튜토리얼 공통 컴포넌트, 상수, 애셋 관리
import 'package:flutter/material.dart';

/// 튜토리얼 관련 모든 상수 정의
class TutorialConstants {
  // 기준 화면 크기
  static const double baseSize = 844.0;

  // 색상
  static const Color backgroundColor = Color.fromARGB(255, 73, 73, 73);
  static const Color buttonColor = Color(0xFFD4E8D4);
  static const double indicatorBackgroundAlpha = 0.3;

  // 버튼 크기
  static const double buttonWidth = 120.0;
  static const double buttonHeight = 50.0;
  static const double buttonBorderWidth = 2.0;

  // 텍스트 크기
  static const double buttonFontSize = 18.0;
  static const double indicatorFontSize = 15.0;

  // 애니메이션 시간
  static const Duration animationDuration = Duration(milliseconds: 1400);

  // ScaleFactor 계산 - 화면 크기에 따른 반응형 배율
  static double calculateScaleFactor(Size size, Orientation orientation) {
    return orientation == Orientation.portrait
        ? size.height / baseSize
        : size.width / baseSize;
  }

  // Portrait 레이아웃 위치 비율
  static const double portraitIndicatorBottom = 0.1;
  static const double portraitButtonBottom = 0.03;
  static const double portraitCharacterTop = 0.3;

  // Landscape 레이아웃 위치 비율
  static const double landscapeIndicatorBottom = 0.11;
  static const double landscapeButtonBottom = 0.008;
  static const double landscapeCharacterTop = 0.12;

  // 캐릭터 이미지 크기
  static const double characterImageWidth = 120.0;
  static const double characterImageWidthLandscape = 150.0;
  static const double speechBubbleWidth = 300.0;

  // 간격
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 8.0;
  static const double spacingLarge = 12.0;
  static const double spacingXLarge = 24.0;
}

/// 튜토리얼 관련 모든 애셋 경로
class TutorialAssets {
  static const String tutorialCharacter =
      'assets/tutorial/tutorial_character.png';

  // Initial Tutorial 이미지
  static const List<String> initialPortraitImages = [
    'assets/tutorial/initial/tutorial_step1.png',
    'assets/tutorial/initial/tutorial_step2.png',
    'assets/tutorial/initial/tutorial_step3.png',
    'assets/tutorial/initial/tutorial_step4.png',
    'assets/tutorial/initial/tutorial_step5.png',
  ];

  static const List<String> initialLandscapeImages = [
    'assets/tutorial/initial/tutorial_landscape_step1.png',
    'assets/tutorial/initial/tutorial_landscape_step2.png',
    'assets/tutorial/initial/tutorial_landscape_step3.png',
    'assets/tutorial/initial/tutorial_landscape_step4.png',
    'assets/tutorial/initial/tutorial_landscape_step5.png',
  ];

  static const String initialSpeechBubble =
      'assets/tutorial/initial/tutorial_speech_bubble.png';

  // Player Tutorial 이미지
  static const List<String> playerPortraitImages = [
    'assets/tutorial/player/player_tutorial_step1.png',
    'assets/tutorial/player/player_tutorial_step2.png',
    'assets/tutorial/player/player_tutorial_step3.png',
    'assets/tutorial/player/player_tutorial_step4.png',
  ];

  static const List<String> playerLandscapeImages = [
    'assets/tutorial/player/player_tutorial_landscape_step1.png',
    'assets/tutorial/player/player_tutorial_landscape_step2.png',
    'assets/tutorial/player/player_tutorial_landscape_step3.png',
  ];

  static const String playerSpeechBubble =
      'assets/tutorial/player/player_tutorial_speech_bubble.png';
}

/// 페이지 인디케이터 (예: 1/5)
class TutorialIndicators extends StatelessWidget {
  const TutorialIndicators({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.scaleFactor = 1.0,
  });

  final int pageCount;
  final int currentPage;
  final double scaleFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scaleFactor,
        vertical: 6 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: TutorialConstants.indicatorBackgroundAlpha,
        ),
        borderRadius: BorderRadius.circular(12 * scaleFactor),
      ),
      child: Text(
        '${currentPage + 1}/$pageCount',
        style: TextStyle(
          fontSize: TutorialConstants.indicatorFontSize * scaleFactor,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 튜토리얼 버튼 (NEXT/DONE)
class TutorialButton extends StatelessWidget {
  const TutorialButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.scaleFactor = 1.0,
    this.quarterTurns = 0,
  });

  final String text;
  final VoidCallback onPressed;
  final double scaleFactor;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: TutorialConstants.buttonWidth * scaleFactor,
      height: TutorialConstants.buttonHeight * scaleFactor,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: TutorialConstants.buttonColor,
          foregroundColor: Colors.black,
          shape: StadiumBorder(
            side: BorderSide(
              color: Colors.black,
              width: TutorialConstants.buttonBorderWidth,
            ),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'NanumSquare',
            fontSize: TutorialConstants.buttonFontSize * scaleFactor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    return quarterTurns != 0
        ? RotatedBox(quarterTurns: quarterTurns, child: button)
        : button;
  }
}

/// 개별 튜토리얼 슬라이드
class TutorialSlide extends StatelessWidget {
  const TutorialSlide({
    super.key,
    required this.imagePath,
    required this.isLastSlide,
    required this.showCharacter,
    required this.characterAnimation,
  });

  final String imagePath;
  final bool isLastSlide;
  final bool showCharacter;
  final Widget characterAnimation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경 이미지
        Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.contain)),

        // 마지막 슬라이드일 때 캐릭터 애니메이션
        if (isLastSlide && showCharacter) characterAnimation,
      ],
    );
  }
}

/// 튜토리얼 네비게이터 (인디케이터 + 버튼)
class TutorialNavigator extends StatelessWidget {
  const TutorialNavigator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.onNext,
    required this.scaleFactor,
    required this.orientation,
  });

  final int pageCount;
  final int currentPage;
  final VoidCallback onNext;
  final double scaleFactor;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isPortrait = orientation == Orientation.portrait;

    // 위치 계산 (겹치지 않도록)
    final indicatorBottom = isPortrait
        ? screenSize.height * TutorialConstants.portraitIndicatorBottom
        : screenSize.height * TutorialConstants.landscapeIndicatorBottom;

    final buttonBottom = isPortrait
        ? screenSize.height * TutorialConstants.portraitButtonBottom
        : screenSize.height * TutorialConstants.landscapeButtonBottom;

    return Stack(
      children: [
        // 인디케이터
        Positioned(
          bottom: indicatorBottom,
          left: 0,
          right: 0,
          child: Center(
            child: TutorialIndicators(
              pageCount: pageCount,
              currentPage: currentPage,
              scaleFactor: scaleFactor,
            ),
          ),
        ),

        // Next 버튼
        Positioned(
          bottom: buttonBottom,
          left: 0,
          right: 0,
          child: Center(
            child: TutorialButton(
              text: 'NEXT',
              onPressed: onNext,
              scaleFactor: scaleFactor,
            ),
          ),
        ),
      ],
    );
  }
}

/// 튜토리얼 타입
enum TutorialType { initial, player }

/// 튜토리얼 캐릭터 콘텐츠 (캐릭터 + 말풍선 + DONE 버튼)
class TutorialCharacterContent extends StatelessWidget {
  const TutorialCharacterContent({
    super.key,
    required this.type,
    required this.orientation,
    required this.onDone,
    required this.scaleFactor,
  });

  final TutorialType type;
  final Orientation orientation;
  final VoidCallback onDone;
  final double scaleFactor;

  @override
  Widget build(BuildContext context) {
    // Player Portrait는 Column 전체를 회전시키므로 landscape 크기 사용
    final effectiveOrientation =
        (type == TutorialType.player && orientation == Orientation.portrait)
        ? Orientation.landscape
        : orientation;

    final isPortrait = effectiveOrientation == Orientation.portrait;

    final characterWidth =
        (isPortrait
            ? TutorialConstants.characterImageWidth
            : TutorialConstants.characterImageWidthLandscape) *
        scaleFactor;

    final spacing1 =
        (isPortrait
            ? TutorialConstants.spacingXLarge
            : TutorialConstants.spacingMedium) *
        scaleFactor;

    final spacing2 =
        (isPortrait
            ? TutorialConstants.spacingLarge
            : TutorialConstants.spacingMedium) *
        scaleFactor;

    // 말풍선 이미지
    final speechBubbleAsset = type == TutorialType.initial
        ? TutorialAssets.initialSpeechBubble
        : TutorialAssets.playerSpeechBubble;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(TutorialAssets.tutorialCharacter, width: characterWidth),
        SizedBox(height: spacing1),
        Image.asset(
          speechBubbleAsset,
          width: TutorialConstants.speechBubbleWidth * scaleFactor,
        ),
        SizedBox(height: spacing2),
        TutorialButton(
          text: 'DONE',
          onPressed: onDone,
          scaleFactor: scaleFactor,
        ),
      ],
    );
  }
}

/// 페이드 + 슬라이드 애니메이션 베이스
abstract class BaseTutorialCharacterAnimation extends StatefulWidget {
  const BaseTutorialCharacterAnimation({
    super.key,
    required this.onDone,
    required this.scaleFactor,
  });

  final VoidCallback onDone;
  final double scaleFactor;
  final Duration duration = TutorialConstants.animationDuration;
}

abstract class BaseTutorialCharacterAnimationState<
  T extends BaseTutorialCharacterAnimation
>
    extends State<T>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: widget.duration, vsync: this);

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutSine));

    slideAnimation = createSlideAnimation();
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Animation<Offset> createSlideAnimation();

  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: buildContent(context),
      ),
    );
  }
}

/// 통합 튜토리얼 캐릭터 애니메이션
class TutorialCharacterAnimation extends BaseTutorialCharacterAnimation {
  const TutorialCharacterAnimation({
    super.key,
    required super.onDone,
    required super.scaleFactor,
    required this.type,
    required this.orientation,
  });

  final TutorialType type;
  final Orientation orientation;

  @override
  State<TutorialCharacterAnimation> createState() =>
      _TutorialCharacterAnimationState();
}

class _TutorialCharacterAnimationState
    extends BaseTutorialCharacterAnimationState<TutorialCharacterAnimation> {
  @override
  Animation<Offset> createSlideAnimation() {
    // Initial: 항상 위→아래
    // Player Portrait: 오른쪽→왼쪽
    // Player Landscape: 위→아래
    return Tween<Offset>(
      begin:
          (widget.orientation == Orientation.portrait &&
              widget.type == TutorialType.player)
          ? const Offset(1.0, 0) // Portrait: 오른쪽에서 왼쪽으로
          : const Offset(0, -0.3), // Landscape: 위에서 아래로
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutSine));
  }

  @override
  Widget buildContent(BuildContext context) {
    final content = TutorialCharacterContent(
      type: widget.type,
      orientation: widget.orientation,
      onDone: widget.onDone,
      scaleFactor: widget.scaleFactor,
    );

    // Player Portrait: Column 전체를 회전하여 하단에 배치
    if (widget.type == TutorialType.player &&
        widget.orientation == Orientation.portrait) {
      return Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Transform.scale(
                  scale: 0.65,
                  alignment: Alignment.bottomCenter, // 아래를 중심으로 스케일
                  child: RotatedBox(quarterTurns: 1, child: content),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Initial & Player Landscape: 정중앙 배치
    return Stack(
      children: [Positioned.fill(child: Center(child: content))],
    );
  }
}
