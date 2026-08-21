import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.violet,
      secondary: AppColors.overviewAccent,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
    ),
    splashFactory: InkRipple.splashFactory,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.violet
            : AppColors.border,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.violet,
      secondary: AppColors.overviewAccent,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onSurface: AppColors.textPrimaryDark,
    ),
    splashFactory: InkRipple.splashFactory,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.violet
            : AppColors.borderDark,
      ),
    ),
  );
}

/// Small helper so widgets can read theme-aware colors without
/// sprinkling `Theme.of(context).brightness == Brightness.dark` everywhere.
extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get cardBg => isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get cardBgAlt =>
      isDark ? AppColors.surfaceDarkAlt : AppColors.inputFill;
  Color get borderColor => isDark ? AppColors.borderDark : AppColors.border;
  Color get textPrimaryColor =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondaryColor =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
}
