import 'package:flutter/material.dart';

class SahyanColors {
  // Brand Greens
  static const Color primaryDark = Color(0xFF1B4D3E); // Deep Luxury Pine
  static const Color primaryMint = Color(0xFF2EC486); // Energetic Mint Accent
  static const Color primaryLight = Color(0xFFE8F5EF); // Soft Mint Surface Tint

  // Canvas & Surfaces
  static const Color canvas = Color(0xFFF6F8F6); // Warm Organic Luxury Canvas
  static const Color surface = Color(0xFFFFFFFF); // Elevated Bento Surface
  static const Color border = Color(0xFFE2E8E4); // 0.8px Hairline Divider
  static const Color chipBackground = Color(0xFFEEF2EF); // Inactive Tag Fill

  // Typography Tokens
  static const Color textMain = Color(0xFF14241C); // High-contrast Forest Charcoal
  static const Color textMuted = Color(0xFF5C6E64); // Slate Sage Gray
  static const Color textDisabled = Color(0xFF9EABA3);

  // Status & Highlights
  static const Color goldStar = Color(0xFFE5A93C); // Ratings & Tier Gold
  static const Color urgentCoral = Color(0xFFE05638); // SOS & Critical Alerts
  static const Color bluePolyline = Color(0xFF2563EB); // Live GPS Path
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
