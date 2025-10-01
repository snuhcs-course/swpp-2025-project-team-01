import 'package:flutter/material.dart';
import 'color_scheme.dart';

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
}