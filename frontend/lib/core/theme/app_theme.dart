import 'package:flutter/material.dart';
import 'color_scheme.dart';

/// 앱의 테마를 정의하는 클래스
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,   // ← color_scheme.dart 에 있는 lightScheme 사용
      scaffoldBackgroundColor: const Color(0xFFF2F3F6),

      extensions: <ThemeExtension<dynamic>>[
        AppHighlights.fromScheme(lightScheme), // ← AppHighlights 등록
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: .2,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: const ChipThemeData(
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: Color(0x33000000), width: 1),
        shape: StadiumBorder(),
      ),
    );
  }

  static ThemeData get dark {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: darkScheme,
      extensions: <ThemeExtension<dynamic>>[
        AppHighlights.fromScheme(darkScheme),
      ],
    );
  }

  /// 고대비 라이트 테마
  static ThemeData get lightHighContrast {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
        error: Color(0xFFD00000),
      ),
      scaffoldBackgroundColor: Colors.white,

      extensions: <ThemeExtension<dynamic>>[
        AppHighlights.fromScheme(lightScheme),
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: .2,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),

      chipTheme: const ChipThemeData(
        labelStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: Colors.black, width: 2),
        shape: StadiumBorder(),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        displayMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        displaySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        headlineSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        titleSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
      ),
    );
  }

  /// 고대비 다크 테마
  static ThemeData get darkHighContrast {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        background: Colors.black,
        onBackground: Colors.white,
        error: Color(0xFFFF5555),
      ),
      scaffoldBackgroundColor: Colors.black,

      extensions: <ThemeExtension<dynamic>>[
        AppHighlights.fromScheme(const ColorScheme.dark()),
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: .2,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.black,
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),

      chipTheme: const ChipThemeData(
        labelStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: Colors.white, width: 2),
        shape: StadiumBorder(),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}