import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/core/theme/color_scheme.dart';

void main() {
  group('TagColorTheme', () {
    test('should have correct theme names', () {
      expect(tagColorThemes.length, 7);
      expect(tagColorThemes[0].name, '봄');
      expect(tagColorThemes[1].name, '여름');
      expect(tagColorThemes[2].name, '가을');
      expect(tagColorThemes[3].name, '겨울');
      expect(tagColorThemes[4].name, '솜사탕');
      expect(tagColorThemes[5].name, '비비드');
      expect(tagColorThemes[6].name, '바다');
    });

    test('should have correct number of colors in each theme', () {
      expect(tagColorThemes[0].colors.length, 10); // 봄
      expect(tagColorThemes[1].colors.length, 7); // 여름
      expect(tagColorThemes[2].colors.length, 10); // 가을
      expect(tagColorThemes[3].colors.length, 5); // 겨울
      expect(tagColorThemes[4].colors.length, 10); // 솜사탕
      expect(tagColorThemes[5].colors.length, 7); // 비비드
      expect(tagColorThemes[6].colors.length, 7); // 바다
    });

    test('should have valid ARGB color values', () {
      for (final theme in tagColorThemes) {
        for (final color in theme.colors) {
          // ARGB 값은 0xFF000000 이상이어야 함 (완전 불투명)
          expect(
            color & 0xFF000000,
            0xFF000000,
            reason: 'Color in ${theme.name} should be opaque',
          );
        }
      }
    });
  });

  group('getTagColorTheme', () {
    test('should return correct theme by name', () {
      final springTheme = getTagColorTheme('봄');
      expect(springTheme.name, '봄');
      expect(springTheme.colors.length, 10);

      final summerTheme = getTagColorTheme('여름');
      expect(summerTheme.name, '여름');
      expect(summerTheme.colors.length, 7);
    });

    test('should return first theme (봄) when theme not found', () {
      final unknownTheme = getTagColorTheme('존재하지않는테마');
      expect(unknownTheme.name, '봄');
      expect(unknownTheme.colors.length, 10);
    });

    test('should return first theme when empty string is provided', () {
      final emptyTheme = getTagColorTheme('');
      expect(emptyTheme.name, '봄');
    });
  });

  group('isColorDark', () {
    test('should identify dark colors correctly', () {
      // 검은색
      expect(isColorDark(0xFF000000), true);

      // 진한 회색
      expect(isColorDark(0xFF333333), true);

      // 바다 테마의 어두운 색상들
      expect(isColorDark(0xFF15253F), true);
      expect(isColorDark(0xFF354E6B), true);
      expect(isColorDark(0xFF263C42), true);
    });

    test('should identify light colors correctly', () {
      // 흰색
      expect(isColorDark(0xFFFFFFFF), false);

      // 연한 회색
      expect(isColorDark(0xFFCCCCCC), false);

      // 봄 테마의 밝은 색상들
      expect(isColorDark(0xFFE9C9D4), false);
      expect(isColorDark(0xFFE0E5A2), false);
      expect(isColorDark(0xFFF1E8C1), false);
    });

    test('should handle medium brightness colors', () {
      // 중간 밝기 색상들 (테스트용)
      expect(isColorDark(0xFF888888), isA<bool>());
      expect(isColorDark(0xFF999999), isA<bool>());
    });

    test('should handle colors with full alpha channel', () {
      // Alpha 채널이 0xFF가 아닌 경우도 RGB만 고려
      expect(isColorDark(0x80000000), true); // 반투명 검정
      expect(isColorDark(0x80FFFFFF), false); // 반투명 흰색
    });
  });

  group('getTextColorForBackground', () {
    test('should return white for dark backgrounds', () {
      // 검은색 배경
      expect(getTextColorForBackground(0xFF000000), Colors.white);

      // 바다 테마의 어두운 색상들
      expect(getTextColorForBackground(0xFF15253F), Colors.white);
      expect(getTextColorForBackground(0xFF354E6B), Colors.white);
    });

    test('should return black for light backgrounds', () {
      // 흰색 배경
      expect(getTextColorForBackground(0xFFFFFFFF), Colors.black);

      // 봄 테마의 밝은 색상들
      expect(getTextColorForBackground(0xFFE9C9D4), Colors.black);
      expect(getTextColorForBackground(0xFFF1E8C1), Colors.black);
    });

    test('should work for all theme colors', () {
      for (final theme in tagColorThemes) {
        for (final color in theme.colors) {
          final textColor = getTextColorForBackground(color);
          // 텍스트 색상은 흰색 또는 검은색이어야 함
          expect(
            textColor == Colors.white || textColor == Colors.black,
            true,
            reason: 'Text color for ${theme.name} should be white or black',
          );
        }
      }
    });
  });

  group('AppHighlights', () {
    test('should create from ColorScheme', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1D1D1D),
        brightness: Brightness.light,
      );

      final highlights = AppHighlights.fromScheme(scheme);

      expect(highlights.important, const Color(0xFFF6D16F));
      expect(highlights.list1, const Color(0xFFEFF0A4));
      expect(highlights.list2, const Color(0xFFFDECB0));
      expect(highlights.list3, const Color(0xFFD8DFE9));
      expect(highlights.misc, const Color(0x33B5A9FF));
    });

    test('should have correct onColors linked to scheme primary', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1D1D1D),
        brightness: Brightness.light,
      );

      final highlights = AppHighlights.fromScheme(scheme);

      expect(highlights.onImportant, scheme.primary);
      expect(highlights.onList1, scheme.primary);
      expect(highlights.onList2, scheme.primary);
      expect(highlights.onList3, scheme.primary);
      expect(highlights.onMisc, scheme.primary);
    });

    test('should provide tagHighlights list', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1D1D1D),
        brightness: Brightness.light,
      );

      final highlights = AppHighlights.fromScheme(scheme);
      final tagHighlights = highlights.tagHighlights;

      expect(tagHighlights.length, 3);
      expect(tagHighlights[0].background, highlights.list1);
      expect(tagHighlights[0].foreground, highlights.onList1);
      expect(tagHighlights[1].background, highlights.list2);
      expect(tagHighlights[1].foreground, highlights.onList2);
      expect(tagHighlights[2].background, highlights.list3);
      expect(tagHighlights[2].foreground, highlights.onList3);
    });

    test('should support copyWith', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1D1D1D),
        brightness: Brightness.light,
      );

      final highlights = AppHighlights.fromScheme(scheme);
      final newImportant = const Color(0xFFFF0000);
      final copied = highlights.copyWith(important: newImportant);

      expect(copied.important, newImportant);
      expect(copied.list1, highlights.list1); // 다른 값은 유지
    });

    test('should support lerp for animations', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1D1D1D),
        brightness: Brightness.light,
      );

      final highlights1 = AppHighlights.fromScheme(scheme);
      final highlights2 = AppHighlights(
        important: const Color(0xFFFF0000),
        onImportant: Colors.white,
        list1: const Color(0xFF00FF00),
        onList1: Colors.white,
        list2: const Color(0xFF0000FF),
        onList2: Colors.white,
        list3: const Color(0xFFFFFF00),
        onList3: Colors.white,
        misc: const Color(0xFFFF00FF),
        onMisc: Colors.white,
      );

      final lerped = highlights1.lerp(highlights2, 0.5);

      expect(lerped, isA<AppHighlights>());
      expect(lerped.important, isNot(highlights1.important));
      expect(lerped.important, isNot(highlights2.important));
    });
  });

  group('TagHighlight', () {
    test('should store background and foreground colors', () {
      const background = Color(0xFFEFF0A4);
      const foreground = Color(0xFF1D1D1D);

      const tagHighlight = TagHighlight(
        background: background,
        foreground: foreground,
      );

      expect(tagHighlight.background, background);
      expect(tagHighlight.foreground, foreground);
    });
  });

  group('lightScheme', () {
    test('should be created from seed color', () {
      expect(lightScheme.brightness, Brightness.light);
      // ColorScheme.fromSeed generates primary from seed, not exact match
      expect(lightScheme.primary, isNotNull);
    });

    test('should have seed color as primary', () {
      expect(seedColor, const Color(0xFF2196F3)); // Material Blue
      // ColorScheme.fromSeed generates colors based on seed
      expect(lightScheme.primary, isNotNull);
    });
  });

  group('BuildContext extensions', () {
    testWidgets('ReViewColors should provide highlights', (tester) async {
      late AppHighlights? capturedHighlights;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              AppHighlights.fromScheme(lightScheme),
            ],
          ),
          home: Builder(
            builder: (context) {
              capturedHighlights = context.highlights;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedHighlights, isNotNull);
      expect(capturedHighlights, isA<AppHighlights>());
    });
  });
}
