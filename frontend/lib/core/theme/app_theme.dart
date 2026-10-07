import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SahyanColors {
  // Brand Greens
  static const Color primaryDark = AppColors.primaryDark; // #084C3A
  static const Color primaryMint = AppColors.primaryMint; // #A7E8D2
  static const Color primaryLight = AppColors.primaryLight; // Soft Mint Surface Tint

  // Canvas & Surfaces
  static const Color canvas = AppColors.canvas; // #F2F7F4
  static const Color surface = AppColors.surface; // #FFFFFF
  static const Color border = AppColors.border; // #E2E8E4
  static const Color chipBackground = AppColors.chipBackground; // #EEF2EF

  // Typography Tokens
  static const Color textMain = AppColors.textMain; // #12352E
  static const Color textMuted = AppColors.textMuted; // #6B7F78
  static const Color textDisabled = AppColors.textDisabled;

  // Status & Highlights
  static const Color goldStar = AppColors.goldStar; // #C9A96E
  static const Color urgentCoral = AppColors.urgentCoral; // #E05638
  static const Color bluePolyline = AppColors.bluePolyline; // #2563EB
}

class SahyanTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: SahyanColors.canvas,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: const ColorScheme.light(
        primary: SahyanColors.primaryDark,
        secondary: SahyanColors.primaryMint,
        surface: SahyanColors.surface,
        onSurface: SahyanColors.textMain,
      ),
      cardTheme: CardThemeData(
        color: SahyanColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: SahyanColors.border, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SahyanColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
