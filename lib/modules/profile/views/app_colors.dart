import 'package:flutter/material.dart';

/// Shared colors so every screen matches the Profile screen's look.
class AppColors {
  static const Color primaryPurple = Color(0xFF5B5FEF);
  static const Color gradientBlue = Color(0xFF3B82F6);
  static const Color gradientPurple = Color(0xFF7C5CF0);
  static const Color background = Color(0xFFF4F5FB);
  static const Color textDark = Color(0xFF1F2333);
}

/// Shared app bar used by every sub-page for a consistent look.
PreferredSizeWidget buildSimpleAppBar(String title) {
  return AppBar(
    backgroundColor: AppColors.background,
    elevation: 0,
    foregroundColor: AppColors.textDark,
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
    ),
  );
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}