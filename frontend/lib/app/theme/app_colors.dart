import 'package:flutter/material.dart';

/// Centralized color tokens for the Sahyān design system.
/// Standardized color palette strictly enforcing the approved Stitch/Figma design guidelines.
abstract class AppColors {
  /// Brand Primary - Forest Green (primary actions, selected states, active nav)
  static const Color primaryForest = Color(0xFF285A4A);

  /// Brand Secondary - Deep Forest (headers, dark surfaces, main titles)
  static const Color deepForest = Color(0xFF193D33);

  /// Informational / Secondary Accent - Muted Sage
  static const Color mutedSage = Color(0xFF71877B);

  /// Subtle Surface Tint / Highlight - Soft Forest
  static const Color softForest = Color(0xFFDDE9E3);

  /// Verification & Rating Highlight - Muted Brass
  static const Color mutedBrass = Color(0xFFB99558);

  /// Rating Container Tint - Soft Brass
  static const Color softBrass = Color(0xFFEFE4CD);

  /// Primary Canvas Surface - Warm Background
  static const Color warmBackground = Color(0xFFF6F7F4);

  /// Card / Surface Pure White
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Tonal Surface Containers (from Stitch specification)
  static const Color surfaceContainerLow = Color(0xFFF3F4F1);
  static const Color surfaceContainer = Color(0xFFEDEEEB);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E6);
  static const Color surfaceDim = Color(0xFFDCDAD4);

  /// Dividers and Input Borders
  static const Color border = Color(0xFFE2E7E3);
  static const Color borderLight = Color(0xFFEFF2F0);

  /// Text Primary - Dominant dark text
  static const Color textPrimary = Color(0xFF18211D);

  /// Text Secondary - Muted subtitles, timestamps, captions
  static const Color textSecondary = Color(0xFF68736C);

  /// Text Tertiary - Inactive placeholders, subtle hints
  static const Color textTertiary = Color(0xFF9AA39E);

  /// Error / Alert / Cancellation - Muted Rust
  static const Color mutedRust = Color(0xFFA65B4B);

  /// Soft Rust container tint for cancellation and error banners
  static const Color softRust = Color(0xFFFCEAE8);

  /// Success State Tint
  static const Color success = Color(0xFF285A4A);

  /// Standard design token aliases
  static const Color primary = primaryForest;
  static const Color primaryDark = deepForest;
  static const Color primaryLight = softForest;
  static const Color accent = mutedBrass;
  static const Color surface = warmBackground;
  static const Color surfaceVariant = surfaceContainerLow;
  static const Color error = mutedRust;
  static const Color errorContainer = softRust;

  /// Transparent
  static const Color transparent = Colors.transparent;
}
