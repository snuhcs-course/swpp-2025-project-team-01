import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF1D1D1D);

final ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
).copyWith(primary: seedColor);

/// AppHighlights holds the highlight color roles for the app.
class AppHighlights extends ThemeExtension<AppHighlights> {
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
      onImportant: scheme.primary,
      list1: const Color(0xFFEFF0A4),
      onList1: scheme.primary,
      list2: const Color(0xFFFDECB0),
      onList2: scheme.primary,
      list3: const Color(0xFFD8DFE9),
      onList3: scheme.primary,
      misc: const Color(0x33B5A9FF),
      onMisc: scheme.primary,
    );
  }

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

  @override
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
  AppHighlights lerp(covariant ThemeExtension<AppHighlights>? other, double t) {
    if (other is! AppHighlights) {
      return this;
    }

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

  List<TagHighlight> get tagHighlights => [
    TagHighlight(background: list1, foreground: onList1),
    TagHighlight(background: list2, foreground: onList2),
    TagHighlight(background: list3, foreground: onList3),
  ];
}

/// 태그 하이라이트 색상을 담는 클래스
class TagHighlight {
  const TagHighlight({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// 태그 색상 테마
///
/// 태그에 적용할 수 있는 색상 테마를 정의합니다.
/// 각 테마는 15개의 색상으로 구성되어 있으며, 태그가 15개를 초과하면 순환 방식으로 색상이 재사용됩니다.
class TagColorTheme {
  const TagColorTheme(this.name, this.colors);

  /// 테마 이름 (예: '파스텔', '비비드')
  final String name;

  /// 테마에 포함된 색상 리스트 (ARGB 형식)
  final List<int> colors;
}

/// 사용 가능한 모든 태그 색상 테마
const List<TagColorTheme> tagColorThemes = [
  TagColorTheme('봄', [
    0xFFFFDADA,
    0xFFFFE4C4,
    0xFFFFF4B3,
    0xFFE8F5E9,
    0xFFB3E5FC,
    0xFFE1BEE7,
    0xFFF8BBD0,
    0xFFFFCCBC,
    0xFFD1C4E9,
    0xFFC5E1A5,
    0xFFFFE082,
    0xFFFFAB91,
    0xFFCE93D8,
    0xFFA5D6A7,
    0xFFB39DDB,
  ]),
  TagColorTheme('비비드', [
    0xFFFF6B6B,
    0xFFFFAA33,
    0xFFFFEB3B,
    0xFF66BB6A,
    0xFF42A5F5,
    0xFF9C27B0,
    0xFFEC407A,
    0xFFFF7043,
    0xFF7E57C2,
    0xFF9CCC65,
    0xFFFDD835,
    0xFFFF8A65,
    0xFFAB47BC,
    0xFF81C784,
    0xFF8E24AA,
  ]),
  TagColorTheme('네온', [
    0xFFFF1744,
    0xFFFF9100,
    0xFFFFEA00,
    0xFF00E676,
    0xFF00B0FF,
    0xFFD500F9,
    0xFFFF4081,
    0xFFFF6E40,
    0xFF651FFF,
    0xFF76FF03,
    0xFFC6FF00,
    0xFFFF3D00,
    0xFFE040FB,
    0xFF00E5FF,
    0xFFAA00FF,
  ]),
  TagColorTheme('소프트', [
    0xFFEFDBD5,
    0xFFF3E5DC,
    0xFFFFF8DC,
    0xFFE8F4EA,
    0xFFE0F2F7,
    0xFFF3E5F5,
    0xFFFCE4EC,
    0xFFFBE9E7,
    0xFFEDE7F6,
    0xFFE7EED3,
    0xFFFFF9C4,
    0xFFFFE0B2,
    0xFFF1E1F5,
    0xFFDCEDC8,
    0xFFE1BEE7,
  ]),
  TagColorTheme('어스톤', [
    0xFFBCAAA4,
    0xFFD7CCC8,
    0xFFE6D7C3,
    0xFFC5E1A5,
    0xFFB0BEC5,
    0xFFCE93D8,
    0xFFF48FB1,
    0xFFFFAB91,
    0xFFB39DDB,
    0xFFA5D6A7,
    0xFFDCE775,
    0xFFFFCC80,
    0xFFBA68C8,
    0xFF90CAF9,
    0xFF9FA8DA,
  ]),
];

/// 테마 이름으로 테마 객체 찾기
///
/// 해당 이름의 테마가 없으면 첫 번째 테마(파스텔)를 반환합니다.
TagColorTheme getTagColorTheme(String name) {
  return tagColorThemes.firstWhere(
    (t) => t.name == name,
    orElse: () => tagColorThemes[0],
  );
}

/// ThemeData 확장 - 라이트 색상 스킴 접근을 위한 확장
extension ReViewThemeData on ThemeData {
  ColorScheme get lightScheme => colorScheme;
}

/// BuildContext 확장 - 하이라이트 색상 접근을 위한 확장
extension ReViewColors on BuildContext {
  AppHighlights get highlights => Theme.of(this).extension<AppHighlights>()!;
}
