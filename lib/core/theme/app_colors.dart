import 'package:flutter/material.dart';

/// Merged color system: Growth Center (core) + Community (accents/avatars)
class AppColors {
  AppColors._();

  // ---- Core brand (Growth Center) ----
  static const Color navy = Color(0xFF1B2A4A);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFB020);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color cyan = Color(0xFF38BDF8);

  static const Color background = Color(0xFFF6F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF181B2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE9EAF3);
  static const Color inputFill = Color(0xFFF2F3F9);

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

  static const Color goalsAccent = Color(0xFF6366F1);
  static const Color habitsAccent = Color(0xFFFF6B6B);
  static const Color todoAccent = Color(0xFF22C55E);
  static const Color overviewAccent = Color(0xFF2DD4BF);

  static const Color goalsBadgeBg = Color(0xFFEEF0FE);
  static const Color habitsBadgeBg = Color(0xFFFFECEC);
  static const Color todoBadgeBg = Color(0xFFE9F9EF);
  static const Color overviewBadgeBg = Color(0xFFE6FBF8);

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

  static const Color communityPrimary = Color(0xFF2F80ED);
  static const Color communityPrimaryDark = Color(0xFF1C64D1);
  static const Color communityAccentPurple = Color(0xFF5D5FEF);
  static const Color communityAccentGreen = Color(0xFF27AE60);
  static const Color communityAccentOrange = Color(0xFFF2994A);
  static const Color communityAccentRed = Color(0xFFEB5757);
  static const Color communityDanger = Color(0xFFEF4444);

  static const Color communitySurfaceAlt = Color(0xFFF1F2F6);
  static const Color communityDivider = Color(0xFFEDEEF2);
  static const Color communityTextMuted = Color(0xFF9CA3AF);
  static const Color communityTextOnPrimary = Color(0xFFFFFFFF);

  static const List<Color> avatarColors = [
    communityAccentPurple,
    communityAccentGreen,
    communityAccentOrange,
    communityAccentRed,
    communityPrimary,
    Color(0xFF9B51E0),
  ];

  static Color avatarColorFor(String seed) {
    final int index =
        seed.codeUnits.fold<int>(0, (a, b) => a + b) % avatarColors.length;
    return avatarColors[index];
  }
}