import 'package:flutter/material.dart';

/// Dunkles Blau als Hauptfarbe der App (DieBlaueAPP).
class AppColors {
  static const Color darkBlue = Color(0xFF0B1F3A);
  static const Color mediumBlue = Color(0xFF13335C);
  static const Color accentBlue = Color(0xFF1E5AA8);
  static const Color beerGold = Color(0xFFE6A817);
  static const Color surface = Color(0xFF102540);
  static const Color textLight = Color(0xFFE8EEF7);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.darkBlue,
    primaryColor: AppColors.mediumBlue,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.mediumBlue,
      secondary: AppColors.beerGold,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBlue,
      foregroundColor: AppColors.textLight,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.mediumBlue,
      selectedColor: AppColors.beerGold,
      labelStyle: const TextStyle(color: AppColors.textLight),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
    ),
  );
}
