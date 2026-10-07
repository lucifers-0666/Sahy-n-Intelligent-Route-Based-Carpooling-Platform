import 'package:flutter/material.dart';

/// Centralized color tokens for the Sahyān design system.
/// Implements the approved Sahyān brand palette.
abstract class AppColors {
  // Brand Greens (Approved Sahyān Palette & Stitch Tokens)
  static const Color primary = Color(0xFF0B5D4B); // Approved Primary Forest Green (#0B5D4B)
  static const Color primaryDark = Color(0xFF084C3A); // Approved Dark Primary (#084C3A)
  static const Color primaryMint = Color(0xFFA7E8D2); // Approved Accent / Mint (#A7E8D2)
  static const Color primaryLight = Color(0xFFE8F5EF); // Soft Mint Surface Tint
  static const Color primaryForest = Color(0xFF285A4A); // Stitch Primary Forest
  static const Color deepForest = Color(0xFF193D33); // Stitch Deep Forest
  static const Color mutedSage = Color(0xFF6B7F78); // Approved Muted Text (#6B7F78)
  static const Color softForest = Color(0xFFDDE9E3); // Stitch Soft Forest

  // Canvas & Surfaces (Approved Sahyān Palette)
  static const Color canvas = Color(0xFFF2F7F4); // Approved Light Surface Canvas (#F2F7F4)
  static const Color warmBackground = Color(0xFFF6F7F4); // Stitch Warm Background
  static const Color surface = Color(0xFFFFFFFF); // Approved White Surface (#FFFFFF)
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8E4); // Hairline Divider
  static const Color borderLight = Color(0xFFE2E8E4);
  static const Color chipBackground = Color(0xFFEEF2EF);

  // Tonal Surface Containers
  static const Color surfaceContainerLow = Color(0xFFF0F4F1);
  static const Color surfaceContainer = Color(0xFFE9EFEA);
  static const Color surfaceContainerHigh = Color(0xFFE2E8E4);
  static const Color surfaceDim = Color(0xFFD8DFDA);

  // Typography Tokens (Approved Sahyān Palette)
  static const Color textMain = Color(0xFF12352E); // Approved Primary Text (#12352E)
  static const Color textPrimary = Color(0xFF18211D); // Stitch Text Primary
  static const Color textMuted = Color(0xFF6B7F78); // Approved Muted Text (#6B7F78)
  static const Color textSecondary = Color(0xFF68736C); // Stitch Text Secondary
  static const Color textDisabled = Color(0xFF9EABA3);
  static const Color textTertiary = Color(0xFF9EABA3);

  // Status & Highlights
  static const Color goldStar = Color(0xFFC9A96E); // Approved Subtle Accent Gold (#C9A96E)
  static const Color accentGold = Color(0xFFC9A96E);
  static const Color mutedBrass = Color(0xFFB99558); // Stitch Muted Brass
  static const Color softBrass = Color(0xFFEFE4CD); // Stitch Soft Brass
  static const Color urgentCoral = Color(0xFFE05638);
  static const Color mutedRust = Color(0xFFA65B4B);
  static const Color softRust = Color(0xFFFCEAE8);
  static const Color bluePolyline = Color(0xFF2563EB); // Live GPS Path

  // Standard design token aliases
  static const Color secondary = primaryMint;
  static const Color accent = primaryMint;
  static const Color surfaceVariant = surfaceContainerLow;
  static const Color error = urgentCoral;
  static const Color errorContainer = softRust;
  static const Color success = Color(0xFF0B5D4B);

  // Transparent
  static const Color transparent = Colors.transparent;
}
