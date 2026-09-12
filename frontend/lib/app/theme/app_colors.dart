import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Centralized color tokens for the Sahyān design system.
/// Aligned with Luxury Light Bento Grid and SahyanColors tokens.
abstract class AppColors {
  // Brand Greens
  static const Color primaryDark = SahyanColors.primaryDark; // #1B4D3E Deep Luxury Pine
  static const Color primaryMint = SahyanColors.primaryMint; // #2EC486 Energetic Mint Accent
  static const Color primaryLight = SahyanColors.primaryLight; // #E8F5EF Soft Mint Surface Tint
  static const Color primaryForest = Color(0xFF285A4A);
  static const Color deepForest = Color(0xFF193D33);
  static const Color mutedSage = Color(0xFF5C6E64);
  static const Color softForest = Color(0xFFDDE9E3);

  // Canvas & Surfaces
  static const Color canvas = SahyanColors.canvas; // #F6F8F6 Warm Organic Luxury Canvas
  static const Color warmBackground = Color(0xFFF6F7F4);
  static const Color surface = SahyanColors.surface; // #FFFFFF Elevated Bento Surface
  static const Color cardBackground = SahyanColors.surface;
  static const Color white = SahyanColors.surface;
  static const Color border = SahyanColors.border; // #E2E8E4 0.8px Hairline Divider
  static const Color borderLight = SahyanColors.border;
  static const Color chipBackground = SahyanColors.chipBackground; // #EEF2EF Inactive Tag Fill

  // Tonal Surface Containers
  static const Color surfaceContainerLow = Color(0xFFF0F4F1);
  static const Color surfaceContainer = Color(0xFFE9EFEA);
  static const Color surfaceContainerHigh = Color(0xFFE2E8E4);
  static const Color surfaceDim = Color(0xFFD8DFDA);

  // Typography Tokens
  static const Color textMain = SahyanColors.textMain; // #14241C High-contrast Forest Charcoal
  static const Color textPrimary = Color(0xFF18211D);
  static const Color textMuted = SahyanColors.textMuted; // #5C6E64 Slate Sage Gray
  static const Color textSecondary = Color(0xFF68736C);
  static const Color textDisabled = SahyanColors.textDisabled; // #9EABA3
  static const Color textTertiary = SahyanColors.textDisabled;

  // Status & Highlights
  static const Color goldStar = SahyanColors.goldStar; // #E5A93C Ratings & Tier Gold
  static const Color mutedBrass = Color(0xFFB99558);
  static const Color softBrass = Color(0xFFEFE4CD);
  static const Color urgentCoral = SahyanColors.urgentCoral; // #E05638 SOS & Critical Alerts
  static const Color mutedRust = Color(0xFFA65B4B);
  static const Color softRust = Color(0xFFFCEAE8);
  static const Color bluePolyline = SahyanColors.bluePolyline; // #2563EB Live GPS Path

  // Standard design token aliases
  static const Color primary = primaryDark;
  static const Color secondary = primaryMint;
  static const Color accent = primaryMint;
  static const Color surfaceVariant = surfaceContainerLow;
  static const Color error = urgentCoral;
  static const Color errorContainer = softRust;
  static const Color success = primaryMint;

  // Transparent
  static const Color transparent = Colors.transparent;
}
