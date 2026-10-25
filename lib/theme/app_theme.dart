import 'package:flutter/material.dart';

/// FabriCare design tokens — cream background, near-black ink, burnt-coral
/// accent (matches the "Care" wordmark) and a mustard secondary accent
/// used for feature tiles on the Home screen.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF7F2E2);
  static const surface = Color(0xFFFFFCF3);
  static const surfaceMuted = Color(0xFFEFE8D4);
  static const ink = Color(0xFF1C1B17);
  static const inkSoft = Color(0xFF6F6A5C);
  static const coral = Color(0xFFD2502E);
  static const mustard = Color(0xFFD9A53C);
  static const sage = Color(0xFF6E8B6A);
  static const danger = Color(0xFFC1453B);
  static const border = Color(0xFFE3DBC2);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        secondary: AppColors.coral,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        fontFamily: 'Roboto',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.inkSoft),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}

/// Reusable status colors for condition / risk badges.
Color severityColor(String level) {
  switch (level.toLowerCase()) {
    case 'low':
    case 'minor':
    case 'good':
    case 'excellent':
    case 'none':
      return AppColors.sage;
    case 'medium':
    case 'moderate':
    case 'fair':
      return AppColors.mustard;
    case 'high':
    case 'poor':
    case 'detected':
    case 'severe':
      return AppColors.danger;
    default:
      return AppColors.inkSoft;
  }
}
