import 'dart:async';

import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';

/// 앱 첫 진입 시 노출되는 스플래시 화면.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();

    // 애니메이션 종료 직후 다음 화면으로 전환.
    _navigationTimer = Timer(const Duration(milliseconds: 1500), _navigateNext);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    bottom: -8,
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        final opacity = _fadeAnimation.value;
                        final dy = (1 - opacity) * 16;
                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(0, dy),
                            child: child,
                          ),
                        );
                      },
                      child: const _GradientTitle(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FBAE), Color(0xFFE5F8DF)],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: const Text(
        'Re:View',
        style: TextStyle(
          fontFamily: 'NanumSquare',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
