import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Aurora Colors
  static const Color primaryGreen = Color(0xFF00FF7F);
  static const Color primaryBlue = Color(0xFF00BFFF);
  static const Color primaryPurple = Color(0xFF8A2BE2);

  // Light Theme Colors
  static const Color _lightBg = Color(0xFFF0F4F8);
  static const Color _lightSurface = Colors.white;
  static const Color _lightText = Color(0xFF1A1A1A);
  
  // Dark Theme Colors
  static const Color _darkBg = Color(0xFF0A0F1A);
  static const Color _darkSurface = Color(0xFF151C2A);
  static const Color _darkText = Color(0xFFE0E0E0);

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryGreen,
        surface: _lightSurface,
        onSurface: _lightText,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: _lightText,
        displayColor: _lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _lightText),
        titleTextStyle: TextStyle(color: _lightText, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }

  // Dark Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryGreen,
        surface: _darkSurface,
        onSurface: _darkText,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: _darkText,
        displayColor: _darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkText),
        titleTextStyle: TextStyle(color: _darkText, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }

  // Aurora Gradient Helper
  static BoxDecoration buildAuroraBackground(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF0D1B2A), // Very dark blue
                const Color(0xFF1B263B).withValues(alpha: 0.8), // Dark slate
                const Color(0xFF415A77).withValues(alpha: 0.5), // Muted cyan
                const Color(0xFF778DA9).withValues(alpha: 0.2), // Light silver blue
              ]
            : [
                const Color(0xFFE0EAFC), // Light bright periwinkle
                const Color(0xFFCFDEF3), // Lavender blue
                const Color(0xFFA1C4FD).withValues(alpha: 0.6), // Light blue
                const Color(0xFFC2E9FB).withValues(alpha: 0.6), // Cyan mist
              ],
      ),
    );
  }
}
