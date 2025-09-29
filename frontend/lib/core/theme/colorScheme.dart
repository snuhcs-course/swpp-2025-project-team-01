import 'package:flutter/material.dart';

final ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1D1D1D),
  brightness: Brightness.light,
);

/// AppHighlights holds the highlight color roles for the app.
class AppHighlights extends ThemeExtension<AppHighlights> {
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

  @override
  AppHighlights lerp(
    covariant ThemeExtension<AppHighlights>? other,
    double t,
  ) {
    if (other is! AppHighlights) return this;

    return AppHighlights(
      important: Color.lerp(important, other.important, t) ?? important,
      onImportant: Color.lerp(onImportant, other.onImportant, t) ?? onImportant,
      list1: Color.lerp(list1, other.list1, t) ?? list1,
      onList1: Color.lerp(onList1, other.onList1, t) ?? onList1,
      list2: Color.lerp(list2, other.list2, t) ?? list2,
      onList2: Color.lerp(onList2, other.onList2, t) ?? onList2,
      list3: Color.lerp(list3, other.list3, t) ?? list3,
      onList3: Color.lerp(onList3, other.onList3, t) ?? onList3,
      misc: Color.lerp(misc, other.misc, t) ?? misc,
      onMisc: Color.lerp(onMisc, other.onMisc, t) ?? onMisc,
    );
  }
}