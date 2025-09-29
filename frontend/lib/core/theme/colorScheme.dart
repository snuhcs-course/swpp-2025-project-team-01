final ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1D1D1D),
  brightness: Brightness.light,
);

/// AppHighlights holds the highlight color roles for the app.
class AppHighlights {
  final Color important;
  final Color onImportant;
  final Color list1;
  final Color onList1;
  final Color list2;
  final Color onList2;
  final Color list3;
  final Color onList3;
  final Color misc;
  final Color onMisc;

  const AppHighlights({
    required this.important,
    required this.onImportant,
    required this.list1,
    required this.onList1,
    required this.list2,
    required this.onList2,
    required this.list3,
    required this.onList3,
    required this.misc,
    required this.onMisc,
  });

  factory AppHighlights.fromScheme(ColorScheme scheme) {
    return AppHighlights(
      important: const Color(0xFFF6D16F),
      onImportant: lightScheme.primary,
      list1: const Color(0xFFEFF0A4),
      onList1: lightScheme.primary,
      list2: const Color(0xFFFDECB0),
      onList2: lightScheme.primary,
      list3: const Color(0xFFD8DFE9),
      onList3: lightScheme.primary,
      misc: const Color(0x33B5A9FF),
      onMisc: lightScheme.primary,
    );
  }

  AppHighlights copyWith({
    Color? important,
    Color? onImportant,
    Color? list1,
    Color? onList1,
    Color? list2,
    Color? onList2,
    Color? list3,
    Color? onList3,
    Color? misc,
    Color? onMisc,
  }) {
    return AppHighlights(
      important: important ?? this.important,
      onImportant: onImportant ?? this.onImportant,
      list1: list1 ?? this.list1,
      onList1: onList1 ?? this.onList1,
      list2: list2 ?? this.list2,
      onList2: onList2 ?? this.onList2,
      list3: list3 ?? this.list3,
      onList3: onList3 ?? this.onList3,
      misc: misc ?? this.misc,
      onMisc: onMisc ?? this.onMisc,
    );
  }

  static AppHighlights lerp(AppHighlights a, AppHighlights b, double t) {
    return AppHighlights(
      important: Color.lerp(a.important, b.important, t)!,
      onImportant: Color.lerp(a.onImportant, b.onImportant, t)!,
      list1: Color.lerp(a.list1, b.list1, t)!,
      onList1: Color.lerp(a.onList1, b.onList1, t)!,
      list2: Color.lerp(a.list2, b.list2, t)!,
      onList2: Color.lerp(a.onList2, b.onList2, t)!,
      list3: Color.lerp(a.list3, b.list3, t)!,
      onList3: Color.lerp(a.onList3, b.onList3, t)!,
      misc: Color.lerp(a.misc, b.misc, t)!,
      onMisc: Color.lerp(a.onMisc, b.onMisc, t)!,
    );
  }
}