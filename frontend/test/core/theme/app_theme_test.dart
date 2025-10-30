import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/core/theme/app_theme.dart';
import 'package:re_view/core/theme/color_scheme.dart';

void main() {
  group('AppTheme.light', () {
    late ThemeData lightTheme;

    setUp(() {
      lightTheme = AppTheme.light;
    });

    test('should use Material 3', () {
      expect(lightTheme.useMaterial3, true);
    });

    test('should use light color scheme', () {
      expect(lightTheme.colorScheme, lightScheme);
      expect(lightTheme.colorScheme.brightness, Brightness.light);
    });

    test('should have correct scaffold background color', () {
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF2F3F6));
    });

    test('should have AppHighlights extension', () {
      final highlights = lightTheme.extension<AppHighlights>();
      expect(highlights, isNotNull);
      expect(highlights, isA<AppHighlights>());
    });

    group('AppBar theme', () {
      test('should have correct colors', () {
        expect(lightTheme.appBarTheme.backgroundColor, Colors.white);
        expect(lightTheme.appBarTheme.foregroundColor, Colors.black);
      });

      test('should have no elevation', () {
        expect(lightTheme.appBarTheme.elevation, 0);
      });

      test('should center title', () {
        expect(lightTheme.appBarTheme.centerTitle, true);
      });

      test('should have correct title text style', () {
        final titleStyle = lightTheme.appBarTheme.titleTextStyle;
        expect(titleStyle?.fontSize, 20);
        expect(titleStyle?.fontWeight, FontWeight.w800);
        expect(titleStyle?.color, Colors.black);
        expect(titleStyle?.letterSpacing, 0.2);
        expect(titleStyle?.fontFamily, 'NanumSquare');
      });
    });

    group('Card theme', () {
      test('should have correct color', () {
        expect(lightTheme.cardTheme.color, Colors.white);
      });

      test('should have correct elevation', () {
        expect(lightTheme.cardTheme.elevation, 1.5);
      });

      test('should have zero margin', () {
        expect(lightTheme.cardTheme.margin, EdgeInsets.zero);
      });

      test('should have rounded corners', () {
        final shape = lightTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      });
    });

    group('Chip theme', () {
      test('should have correct label style', () {
        expect(lightTheme.chipTheme.labelStyle?.fontWeight, FontWeight.w600);
      });

      test('should have correct padding', () {
        expect(
          lightTheme.chipTheme.padding,
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
      });

      test('should have border', () {
        expect(lightTheme.chipTheme.side?.color, const Color(0x33000000));
        expect(lightTheme.chipTheme.side?.width, 1);
      });

      test('should have stadium shape', () {
        expect(lightTheme.chipTheme.shape, isA<StadiumBorder>());
      });
    });
  });

  group('AppTheme.dark', () {
    late ThemeData darkTheme;

    setUp(() {
      darkTheme = AppTheme.dark;
    });

    test('should use Material 3', () {
      expect(darkTheme.useMaterial3, true);
    });

    test('should use dark color scheme', () {
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('should have AppHighlights extension', () {
      final highlights = darkTheme.extension<AppHighlights>();
      expect(highlights, isNotNull);
      expect(highlights, isA<AppHighlights>());
    });
  });

  group('AppTheme.lightHighContrast', () {
    late ThemeData highContrastTheme;

    setUp(() {
      highContrastTheme = AppTheme.lightHighContrast;
    });

    test('should use Material 3', () {
      expect(highContrastTheme.useMaterial3, true);
    });

    test('should have high contrast colors', () {
      expect(highContrastTheme.colorScheme.primary, Colors.black);
      expect(highContrastTheme.colorScheme.onPrimary, Colors.white);
      expect(highContrastTheme.colorScheme.surface, Colors.white);
      expect(highContrastTheme.colorScheme.onSurface, Colors.black);
    });

    test('should have white scaffold background', () {
      expect(highContrastTheme.scaffoldBackgroundColor, Colors.white);
    });

    group('High contrast AppBar', () {
      test('should have increased elevation', () {
        expect(highContrastTheme.appBarTheme.elevation, 2);
      });

      test('should have bold title', () {
        final titleStyle = highContrastTheme.appBarTheme.titleTextStyle;
        expect(titleStyle?.fontWeight, FontWeight.w900);
      });
    });

    group('High contrast Card', () {
      test('should have increased elevation', () {
        expect(highContrastTheme.cardTheme.elevation, 3);
      });

      test('should have visible border', () {
        final shape =
            highContrastTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.side.color, Colors.black);
        expect(shape.side.width, 2);
      });
    });

    group('High contrast Chip', () {
      test('should have bold label', () {
        expect(
          highContrastTheme.chipTheme.labelStyle?.fontWeight,
          FontWeight.w900,
        );
        expect(highContrastTheme.chipTheme.labelStyle?.color, Colors.black);
      });

      test('should have thick border', () {
        expect(highContrastTheme.chipTheme.side?.color, Colors.black);
        expect(highContrastTheme.chipTheme.side?.width, 2);
      });
    });

    group('High contrast Text theme', () {
      test('should have bold body text', () {
        expect(
          highContrastTheme.textTheme.bodyLarge?.fontWeight,
          FontWeight.w600,
        );
        expect(
          highContrastTheme.textTheme.bodyMedium?.fontWeight,
          FontWeight.w600,
        );
        expect(
          highContrastTheme.textTheme.bodySmall?.fontWeight,
          FontWeight.w600,
        );
      });

      test('should have very bold headings', () {
        expect(
          highContrastTheme.textTheme.headlineLarge?.fontWeight,
          FontWeight.w900,
        );
        expect(
          highContrastTheme.textTheme.headlineMedium?.fontWeight,
          FontWeight.w900,
        );
        expect(
          highContrastTheme.textTheme.headlineSmall?.fontWeight,
          FontWeight.w900,
        );
      });

      test('should have very bold titles', () {
        expect(
          highContrastTheme.textTheme.titleLarge?.fontWeight,
          FontWeight.w900,
        );
        expect(
          highContrastTheme.textTheme.titleMedium?.fontWeight,
          FontWeight.w900,
        );
        expect(
          highContrastTheme.textTheme.titleSmall?.fontWeight,
          FontWeight.w900,
        );
      });

      test('all text should be black', () {
        expect(highContrastTheme.textTheme.bodyLarge?.color, Colors.black);
        expect(highContrastTheme.textTheme.headlineLarge?.color, Colors.black);
        expect(highContrastTheme.textTheme.titleLarge?.color, Colors.black);
      });
    });
  });

  group('AppTheme.darkHighContrast', () {
    late ThemeData darkHighContrastTheme;

    setUp(() {
      darkHighContrastTheme = AppTheme.darkHighContrast;
    });

    test('should use Material 3', () {
      expect(darkHighContrastTheme.useMaterial3, true);
    });

    test('should have high contrast dark colors', () {
      expect(darkHighContrastTheme.colorScheme.primary, Colors.white);
      expect(darkHighContrastTheme.colorScheme.onPrimary, Colors.black);
      expect(darkHighContrastTheme.colorScheme.surface, Colors.black);
      expect(darkHighContrastTheme.colorScheme.onSurface, Colors.white);
    });

    test('should have black scaffold background', () {
      expect(darkHighContrastTheme.scaffoldBackgroundColor, Colors.black);
    });

    group('Dark high contrast AppBar', () {
      test('should have white foreground on black background', () {
        expect(darkHighContrastTheme.appBarTheme.backgroundColor, Colors.black);
        expect(darkHighContrastTheme.appBarTheme.foregroundColor, Colors.white);
      });

      test('should have bold white title', () {
        final titleStyle = darkHighContrastTheme.appBarTheme.titleTextStyle;
        expect(titleStyle?.color, Colors.white);
        expect(titleStyle?.fontWeight, FontWeight.w900);
      });
    });

    group('Dark high contrast Card', () {
      test('should have white border on black card', () {
        final shape =
            darkHighContrastTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.side.color, Colors.white);
        expect(shape.side.width, 2);
      });
    });

    group('Dark high contrast Chip', () {
      test('should have white label and border', () {
        expect(darkHighContrastTheme.chipTheme.labelStyle?.color, Colors.white);
        expect(darkHighContrastTheme.chipTheme.side?.color, Colors.white);
      });
    });

    group('Dark high contrast Text theme', () {
      test('all text should be white', () {
        expect(darkHighContrastTheme.textTheme.bodyLarge?.color, Colors.white);
        expect(
          darkHighContrastTheme.textTheme.headlineLarge?.color,
          Colors.white,
        );
        expect(darkHighContrastTheme.textTheme.titleLarge?.color, Colors.white);
      });
    });
  });

  group('Theme consistency', () {
    test('all themes should have AppHighlights extension', () {
      final themes = [
        AppTheme.light,
        AppTheme.dark,
        AppTheme.lightHighContrast,
        AppTheme.darkHighContrast,
      ];

      for (final theme in themes) {
        expect(theme.extension<AppHighlights>(), isNotNull);
      }
    });

    test('light themes should have light brightness', () {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(
        AppTheme.lightHighContrast.colorScheme.brightness,
        Brightness.light,
      );
    });

    test('dark themes should have dark brightness', () {
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
      expect(AppTheme.darkHighContrast.colorScheme.brightness, Brightness.dark);
    });

    test('high contrast themes should have higher elevation than normal', () {
      expect(
        AppTheme.lightHighContrast.cardTheme.elevation,
        greaterThan(AppTheme.light.cardTheme.elevation!),
      );
      expect(
        AppTheme.darkHighContrast.cardTheme.elevation,
        greaterThan(AppTheme.dark.cardTheme.elevation ?? 0),
      );
    });
  });

  group('Theme integration', () {
    testWidgets('light theme should work in MaterialApp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Test')),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('dark theme should work in MaterialApp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Text('Test')),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('can access highlights from context', (tester) async {
      late AppHighlights? highlights;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              highlights = context.highlights;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(highlights, isNotNull);
      expect(highlights?.important, const Color(0xFFF6D16F));
    });
  });
}
