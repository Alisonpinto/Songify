import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF080B10);
  static const Color darkSurface = Color(0xFF13171F);
  static const Color darkCard = Color(0xFF1E2430);
  
  static const Color primaryYellow = Color(0xFFE2F163);
  static const Color secondaryYellow = Color(0xFFB1C52A);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A8B5);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryYellow,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: secondaryYellow,
        surface: darkSurface,
        background: darkBackground,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto', // Ideally we'd add Inter or similar
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: textSecondary),
      ),
    );
  }
}
