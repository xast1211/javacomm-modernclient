import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF1A73E8); // Modern Blue

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  // JChat "Original" Colors extracted from Source
  static ThemeData get mokkaTheme => _buildTheme(const Color(0xFF795548), const Color(0xFFD9D9D9)); // JQUERY_HOMEPAGE (Darker for Menu) / JQUERY_MOKKA (Bg)
  static ThemeData get vanilleTheme => _buildTheme(const Color(0xFFFFE135), const Color(0xFFFFF9B9)); // Custom Yellow (Darker for Menu) / JQUERY_VANILLE (Bg)
  static ThemeData get joghurtTheme => _buildTheme(const Color(0xFFB0A8E0), const Color(0xFFDAD4F7)); // JQUERY_HELLBLAU (Darkened for Menu) / JQUERY_HELLBLAU
  static ThemeData get blaubeereTheme => _buildTheme(const Color(0xFF4424D6), const Color(0xFFDAD4F7)); // JQUERY_BLAU / JQUERY_HELLBLAU
  static ThemeData get erdbeereTheme => _buildTheme(const Color(0xFFFB2943), const Color(0xFFF7A9C3)); // Custom Red (Darker for Menu) / JQUERY_ERDBEERE (Bg)
  static ThemeData get zitroneTheme => _buildTheme(const Color(0xFFB8CB3A), const Color(0xFFF2F0E4)); // Custom Lime / JQUERY_LEMON (Bg)

  static ThemeData _buildTheme(Color seed, Color background) {
     return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background, // Set explicit background color
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: seed, // AppBar takes seed color
        foregroundColor: (ThemeData.estimateBrightnessForColor(seed) == Brightness.dark) ? Colors.white : Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8), // Slightly transparent input
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: (ThemeData.estimateBrightnessForColor(seed) == Brightness.dark) ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      // ... keep rest same
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
