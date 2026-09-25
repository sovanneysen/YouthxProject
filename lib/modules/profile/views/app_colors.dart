import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
export '../../../core/theme/app_theme.dart';

/// Shared colors so every screen matches the Profile screen's look.
class AppColors {
  static const Color primaryPurple = Color(0xFF5B5FEF);
  static const Color gradientBlue = Color(0xFF3B82F6);
  static const Color gradientPurple = Color(0xFF7C5CF0);
  static const Color background = Color(0xFFF4F5FB);
  static const Color textDark = Color(0xFF1F2333);
}

/// Shared app bar used by every sub-page for a consistent look.
PreferredSizeWidget buildSimpleAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: context.bg,
    elevation: 0,
    foregroundColor: context.textPrimaryColor,
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: context.textPrimaryColor,
      ),
    ),
  );
}

BoxDecoration cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: context.cardBg,
    borderRadius: BorderRadius.circular(16),
    border: context.isDark ? Border.all(color: context.borderColor, width: 1) : null,
    boxShadow: context.isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
  );
}