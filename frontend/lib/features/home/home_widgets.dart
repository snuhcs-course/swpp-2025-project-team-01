// 홈 전용 작은 위젯들: 필터 바 / 과목 패널 / 강의 타일

import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';

class FilterBar extends StatelessWidget {
  final List<Tag> tags;
  final Set<String> selected;
  final bool favoritesOnly;
  final ValueChanged<bool> onToggleFavOnly;
  final ValueChanged<String> onToggleTag;

  const FilterBar({
    super.key,
    required this.tags,
    required this.selected,
    required this.favoritesOnly,
    required this.onToggleFavOnly,
    required this.onToggleTag,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gap.g16),
      child: Wrap(
        spacing: Gap.g8,
        runSpacing: Gap.g8,
        children: [
          FilterChip(
            label: const Text('즐겨찾기'),
            selected: favoritesOnly,
            onSelected: onToggleFavOnly,
            avatar: const Icon(Icons.star, size: 18),
          ),
          ...tags.map((t) => FilterChip(
                label: Text('#${t.name}'),
                selected: selected.contains(t.id),
                onSelected: (_) => onToggleTag(t.id),
                backgroundColor: Color(t.color).withOpacity(.2),
              )),
        ],
      ),
    );
  }
}

class SubjectPanel extends StatefulWidget {
  final Subject subject;
  final List<Lecture> lectures;
  final VoidCallback onToggleFavorite;
  final ValueChanged<Lecture> onOpenLecture;

  const SubjectPanel({
    super.key,
    required this.subject,
    required this.lectures,
    required this.onToggleFavorite,
    required this.onOpenLecture,
  });

  @override
  State<SubjectPanel> createState() => _SubjectPanelState();
}

class _SubjectPanelState extends State<SubjectPanel> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.g16, vertical: Gap.g8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.card)),
        child: Padding(
          padding: const EdgeInsets.all(Gap.g12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(widget.subject.favorite ? Icons.star : Icons.star_border),
                    onPressed: widget.onToggleFavorite,
                  ),
                  Expanded(
                    child: Text(widget.subject.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    onPressed: () => setState(() => expanded = !expanded),
                  ),
                ],
              ),
              if (expanded) const SizedBox(height: Gap.g8),
              if (expanded)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: Gap.g12, crossAxisSpacing: Gap.g12, childAspectRatio: 1.4,
                  ),
                  itemCount: widget.lectures.length,
                  itemBuilder: (_, i) => LectureTile(lecture: widget.lectures[i], onTap: widget.onOpenLecture),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LectureTile extends StatelessWidget {
  final Lecture lecture;
  final ValueChanged<Lecture> onTap;
  const LectureTile({super.key, required this.lecture, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(lecture),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(Gap.g16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lecture.weekLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: Gap.g8),
              Text(lecture.title),
              const SizedBox(height: Gap.g12),
              Text('길이: ${formatDuration(lecture.durationSec)}'),
              const SizedBox(height: Gap.g16),
              FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
            ]),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.all(Gap.g12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(color: Colors.black12)), // 썸네일 자리
          const SizedBox(height: Gap.g8),
          Text(lecture.weekLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}