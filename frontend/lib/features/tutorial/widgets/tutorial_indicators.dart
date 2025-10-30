// 튜토리얼 페이지 카운터 위젯
import 'package:flutter/material.dart';

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
