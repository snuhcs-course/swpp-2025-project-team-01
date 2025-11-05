import 'dart:math';

import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF2196F3); // Material Blue

final ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
);

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

/// 색상의 밝기를 계산하여 어두운 배경인지 판단
///
/// W3C 기준의 상대적 휘도(relative luminance) 계산
/// 0.5보다 작으면 어두운 색상으로 판단
bool isColorDark(int argbColor) {
  final r = ((argbColor >> 16) & 0xFF) / 255.0;
  final g = ((argbColor >> 8) & 0xFF) / 255.0;
  final b = (argbColor & 0xFF) / 255.0;

  // 감마 보정
  final rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
  final gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
  final bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

  // 상대적 휘도 계산
  final luminance = 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;

  return luminance < 0.5;
}

/// 배경 색상에 따라 적절한 텍스트 색상 반환
///
/// 어두운 배경이면 흰색, 밝은 배경이면 검은색 반환
Color getTextColorForBackground(int backgroundColor) {
  return isColorDark(backgroundColor) ? Colors.white : Colors.black;
}

/// 태그 색상 테마
///
/// 태그에 적용할 수 있는 색상 테마를 정의합니다.
/// 각 테마는 15개의 색상으로 구성되어 있으며, 태그가 15개를 초과하면 순환 방식으로 색상이 재사용됩니다.
class TagColorTheme {
  const TagColorTheme(this.name, this.colors, {this.textColor = Colors.black});

  /// 테마 이름 (예: '봄', '여름', '가을')
  final String name;

  /// 테마에 포함된 색상 리스트 (ARGB 형식)
  final List<int> colors;

  /// 태그 텍스트에 사용할 색상 (기본: 검정)
  final Color textColor;
}

/// 사용 가능한 모든 태그 색상 테마
const List<TagColorTheme> tagColorThemes = [
  TagColorTheme('봄', [
    0xFFE9C9D4,
    0xFFE0E5A2,
    0xFFD8DD80,
    0xFFD1739B,
    0xFFF1E8C1,
    0xFFDA95AA,
    0xFFE3E38D,
  ]),
  TagColorTheme('여름', [
    0xFFDBC880,
    0xFFE0C44B,
    0xFF526373,
    0xFFF0E8C3,
    0xFFF1E491,
    0xFFC2C2BE,
    0xFF9CB0C5,
  ]),
  TagColorTheme('가을', [
    0xFFB5C3C4,
    0xFFCFA992,
    0xFFA75A48,
    0xFF9AAAAE,
    0xFFE1C5AE,
    0xFFD1D9D7,
    0xFFA3C1D1,
  ]),
  TagColorTheme('겨울', [0xFFCBDFEA, 0xFFC8C2BC, 0xFF4B3935, 0xFFFAF3E0]),
  TagColorTheme('솜사탕', [
    0xFFDC97B4,
    0xFFC3E2F5,
    0xFFD2ADE9,
    0xFF7D8BD5,
    0xFFEDD769,
    0xFFD0D271,
    0xFFD9C5FB,
  ]),
  TagColorTheme('비비드', [
    0xFFC65067,
    0xFFD5D887,
    0xFFB0B4E8,
    0xFF4666E3,
    0xFFE9D479,
    0xFFD09832,
    0xFF74AA84,
  ]),
  TagColorTheme('바다', [
    0xFFACBFD4,
    0xFF15253F,
    0xFF354E6B,
    0xFF889BB0,
    0xFF405066,
    0xFF263C42,
    0xFF566C86,
  ], textColor: Colors.white),
];

/// 테마 이름으로 테마 객체 찾기
///
/// 해당 이름의 테마가 없으면 첫 번째 테마(봄)를 반환합니다.
TagColorTheme getTagColorTheme(String name) {
  return tagColorThemes.firstWhere(
    (t) => t.name == name,
    orElse: () => tagColorThemes[0],
  );
}

/// 태그 테마 이름으로 텍스트 색상을 반환
Color getTagThemeTextColor(String name) {
  return getTagColorTheme(name).textColor;
}

/// ThemeData 확장 - 라이트 색상 스킴 접근을 위한 확장
extension ReViewThemeData on ThemeData {
  ColorScheme get lightScheme => colorScheme;
}

/// BuildContext 확장 - 하이라이트 색상 접근을 위한 확장
extension ReViewColors on BuildContext {
  AppHighlights get highlights => Theme.of(this).extension<AppHighlights>()!;
}
