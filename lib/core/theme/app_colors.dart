import 'package:flutter/material.dart';

/// Colors extracted from the Figma "Community" design, remapped to a
/// light-mode palette (the source file used a dark theme).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryDark = Color(0xFF1C64D1);
  static const Color accentPurple = Color(0xFF5D5FEF);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentOrange = Color(0xFFF2994A);
  static const Color accentRed = Color(0xFFEB5757);
  static const Color danger = Color(0xFFEF4444);

  // Surfaces (light mode)
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F2F6);
  static const Color inputFill = Color(0xFFF1F2F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEDEEF2);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Avatar palette (cycled per user)
  static const List<Color> avatarColors = [
    accentPurple,
    accentGreen,
    accentOrange,
    accentRed,
    primary,
    Color(0xFF9B51E0),
  ];

  static Color avatarColorFor(String seed) {
    final int index = seed.codeUnits.fold<int>(0, (a, b) => a + b) % avatarColors.length;
    return avatarColors[index];
  }
}
