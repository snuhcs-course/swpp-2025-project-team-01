// 자주 쓰는 작은 위젯들
import 'package:flutter/material.dart';

/// 전체 너비를 차지하는 주요 버튼 위젯
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// 빈 상태를 표시하는 위젯
class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

/// 로딩 중임을 표시하는 오버레이 위젯
class LoadingOverlay extends StatelessWidget {
  final String message;
  const LoadingOverlay({super.key, this.message = 'Processing...'});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }
}