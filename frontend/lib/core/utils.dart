// 공통 유틸 (시간 포맷 등)
String formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString();
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}