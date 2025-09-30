import 'package:flutter/material.dart';

import '../../core/theme/color_scheme.dart';

// 홈 화면 카드 구성을 위한 강의 요약 모델
class CourseSummary {
  CourseSummary({
    required this.id,
    required this.title,
    required this.tags,
    required this.notes,
    this.isFavorite = false,
    this.isInitiallyExpanded = true,
  });

  final String id;
  final String title;
  final List<String> tags;
  final List<NoteSummary> notes;
  final bool isFavorite;
  final bool isInitiallyExpanded;
}

// 각 카드에 들어갈 노트 요약 정보 모델
class NoteSummary {
  const NoteSummary({
    required this.week,
    required this.title,
    required this.subtitle,
    this.previewAsset,
    this.isPlaceholder = false,
  });

  final String week;
  final String title;
  final String subtitle;
  final String? previewAsset;
  final bool isPlaceholder;
}

// 화면 시안을 재현하기 위한 목업 데이터 세트
final List<CourseSummary> mockCourses = [
  CourseSummary(
    id: 'software-principles',
    title: '소프트웨어 개발의 원리와 실습',
    tags: ['#25-2', '#전필', '#살려야한다'],
    isFavorite: true,
    isInitiallyExpanded: true,
    notes: const [
      NoteSummary(
        week: 'Week 1-1',
        title: 'Course Overview',
        subtitle: 'Course Overview',
      ),
      NoteSummary(
        week: 'Week 1-2',
        title: 'AI App Examples',
        subtitle: 'AI App Examples',
      ),
      NoteSummary(
        week: 'Week 1-2',
        title: 'Software Processes',
        subtitle: 'Software Processes',
      ),
      NoteSummary(
        week: '',
        title: '',
        subtitle: '',
        isPlaceholder: true,
      ),
    ],
  ),
  CourseSummary(
    id: 'outerspace-life',
    title: '외계행성과 생명',
    tags: ['#25-2', '#교양'],
    isFavorite: true,
    isInitiallyExpanded: false,
    notes: const [
      NoteSummary(
        week: 'Week 1-1',
        title: 'Course Overview',
        subtitle: 'Course Overview',
      ),
      NoteSummary(
        week: 'Week 1-2',
        title: 'AI App Examples',
        subtitle: 'AI App Examples',
      ),
      NoteSummary(
        week: 'Week 1-2',
        title: 'Software Processes',
        subtitle: 'Software Processes',
      ),
      NoteSummary(
        week: '',
        title: '',
        subtitle: '',
        isPlaceholder: true,
      ),
    ],
  ),
  CourseSummary(
    id: 'automata',
    title: '오토마타이론',
    tags: ['#25-2', '#전필'],
    isFavorite: true,
    isInitiallyExpanded: true,
    notes: const [
      NoteSummary(
        week: 'Week 1-1',
        title: 'Course Overview',
        subtitle: 'Course Overview',
      ),
      NoteSummary(
        week: 'Week 1-2',
        title: 'AI App Examples',
        subtitle: 'AI App Examples',
      ),
      NoteSummary(
        week: 'Week 1-2',
        title: 'Software Processes',
        subtitle: 'Software Processes',
      ),
      NoteSummary(
        week: '',
        title: '',
        subtitle: '',
        isPlaceholder: true,
      ),
    ],
  ),
  CourseSummary(
    id: 'deep-learning',
    title: '딥러닝의 기초',
    tags: ['#25-1', '#전선'],
    isFavorite: true,
    isInitiallyExpanded: true,
    notes: const [
      NoteSummary(
        week: '',
        title: '',
        subtitle: '',
        isPlaceholder: true,
      ),
    ],
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Map<String, bool> _expanded;

  @override
  void initState() {
    super.initState();
    // 강의별 펼침 상태를 초기값에 맞춰 저장
    _expanded = {
      for (final course in mockCourses) course.id: course.isInitiallyExpanded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).lightScheme;
    final highlights = Theme.of(context).extension<AppHighlights>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더 + 필터 영역
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 5),
                    _buildFilterRow(context),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final course = mockCourses[index];
                  final isExpanded = _expanded[course.id] ?? false;
                  // 강의 카드와 펼침 상태 토글
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: index == mockCourses.length - 1 ? 28 : 20,
                    ),
                    child: _CourseCard(
                      course: course,
                      isExpanded: isExpanded,
                      highlightColor: highlights?.important ?? const Color(0xFFF6D16F),
                      tagHighlights: highlights?.tagHighlights,
                      onToggle: () {
                        setState(() {
                          _expanded[course.id] = !(isExpanded);
                        });
                      },
                    ),
                  );
                },
                childCount: mockCourses.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.menu,
          onTap: () {},
          background: colorScheme.background,
        ),
        const Spacer(),
        Text(
          'Re:View',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _RoundIconButton(
          icon: Icons.search,
          onTap: () {},
          background: colorScheme.background,
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: const [
        _FilterPill(icon: Icons.tune, label: '필터'),
        _FilterPill(icon: Icons.star, label: '즐겨찾기'),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.isExpanded,
    required this.highlightColor,
    required this.tagHighlights,
    required this.onToggle,
  });

  final CourseSummary course;
  final bool isExpanded;
  final Color highlightColor;
  final List<TagHighlight>? tagHighlights;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        course.isFavorite ? Icons.star : Icons.star_border,
                        color: highlightColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          course.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onToggle,
                        icon: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: const Icon(
                            Icons.expand_more,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < course.tags.length; i++)
                        _TagChip(
                          label: course.tags[i],
                          background: _tagBackground(i),
                          foreground: const Color(0xFF1D1D1D),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // 접기/펼치기 애니메이션 영역
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _NotesGrid(notes: course.notes),
              ),
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              sizeCurve: Curves.easeInOut,
              crossFadeState:
                  isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 450),
            ),
          ],
        ),
      ),
    );
}

  Color _tagBackground(int index) {
    final palette = tagHighlights;
    if (palette != null && palette.isNotEmpty) {
      final selected = palette[index % palette.length];
      return selected.background;
    }
    return highlightColor.withValues(alpha: 0.2);
  }

}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes});

  final List<NoteSummary> notes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 16.0;
        final columns = 2;
        final itemWidth = (constraints.maxWidth - spacing) / columns;

        // 2열 그리드처럼 보이도록 Wrap으로 배치
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: notes
              .map(
                (note) => SizedBox(
                  width: itemWidth,
                  child: _NoteCard(note: note),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final NoteSummary note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (note.isPlaceholder) {
      // 새 노트를 추가하기 위한 + 카드
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 38),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              alignment: Alignment.center,
              child: Text(
                note.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.week,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  note.subtitle,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 필터/즐겨찾기 선택 버튼
    return Material(
      color: colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: background ?? Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon),
        ),
      ),
    );
  }
}
