import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---- Core brand ----
  static const Color navy = Color(0xFF1B2A4A);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFB020);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color cyan = Color(0xFF38BDF8);

  // ---- Light theme surfaces ----
  static const Color background = Color(0xFFF6F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF181B2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE9EAF3);
  static const Color inputFill = Color(0xFFF2F3F9);

  // ---- Dark theme surfaces ----
  static const Color backgroundDark = Color(0xFF0B0D17);
  static const Color surfaceDark = Color(0xFF161927);
  static const Color surfaceDarkAlt = Color(0xFF1E2233);
  static const Color textPrimaryDark = Color(0xFFF2F3FA);
  static const Color textSecondaryDark = Color(0xFF9297AE);
  static const Color borderDark = Color(0xFF2A2E42);
  static const Color inputFillDark = Color(0xFF1E2233);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = amber;
  static const Color error = Color(0xFFFF4D6D);

  static const Color growthAccent = teal;

  // Per-tab accents (Growth Center: Goals / Habits / To-Do / Overview)
  static const Color goalsAccent = Color(0xFF6366F1);
  static const Color habitsAccent = Color(0xFFFF6B6B);
  static const Color todoAccent = Color(0xFF22C55E);
  static const Color overviewAccent = Color(0xFF2DD4BF);

  static const Color goalsBadgeBg = Color(0xFFEEF0FE);
  static const Color habitsBadgeBg = Color(0xFFFFECEC);
  static const Color todoBadgeBg = Color(0xFFE9F9EF);
  static const Color overviewBadgeBg = Color(0xFFE6FBF8);

  // ---- Gen-Z gradients (used for headers, buttons, rings, glows) ----
  static const LinearGradient goalsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFFA78BFA), Color(0xFFEC4899)],
  );

  static const LinearGradient habitsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB020)],
  );

  static const LinearGradient todoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF2DD4BF)],
  );

  static const LinearGradient overviewGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2DD4BF), Color(0xFF38BDF8), Color(0xFF6366F1)],
  );

  // Hero header gradient (brand, theme-agnostic — pops in both modes)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static LinearGradient gradientFor(Color accent) {
    if (accent == goalsAccent) return goalsGradient;
    if (accent == habitsAccent) return habitsGradient;
    if (accent == todoAccent) return todoGradient;
    if (accent == overviewAccent) return overviewGradient;
    return heroGradient;
  }
}
