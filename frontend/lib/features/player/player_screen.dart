// 세로/가로 전환 가능한 최소 플레이어 스켈레톤
import 'package:flutter/material.dart';
import '../../core/utils.dart';

/// 강의 재생 화면
class PlayerScreen extends StatelessWidget {
  final Object? args;
  const PlayerScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final map = (args is Map) ? args as Map : const {};
    final lectureId = map['lectureId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('플레이어 · $lectureId')),
      body: OrientationBuilder(
        builder: (_, o) {
          final isPortrait = o == Orientation.portrait;
          return isPortrait ? _portrait() : _landscape();
        },
      ),
    );
  }

  Widget _portrait() {
    return Column(children: [
      Expanded(child: Container(color: Colors.black12, child: const Center(child: Text('슬라이드 영역')))),
      SizedBox(
        height: 90,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(color: Colors.black26, alignment: Alignment.center, child: Text('${i + 1}')),
          ),
        ),
      ),
      _controls(),
    ]);
  }

  Widget _landscape() {
    return Row(children: [
      Expanded(child: Container(color: Colors.black12, child: const Center(child: Text('슬라이드 영역')))),
      SizedBox(
        width: 140,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(color: Colors.black26, alignment: Alignment.center, child: Text('${i + 1}')),
          ),
        ),
      ),
    ]);
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.replay_10)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.forward_10)),
        const Spacer(),
        Text('${formatDuration(132)} / ${formatDuration(4056)}'),
        const SizedBox(width: 12),
        IconButton(onPressed: () {}, icon: const Icon(Icons.closed_caption)),
      ]),
    );
  }
}