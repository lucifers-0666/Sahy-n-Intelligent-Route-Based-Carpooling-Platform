import 'package:flutter/material.dart';

/// Centralized color tokens for the Sahyān design system.
/// Implements the approved Sahyān brand palette.
abstract class AppColors {
  // ── Master Brief 2026 Approved Tokens (Light) ──────────────────────────
  static const Color brand = Color(
    0xFF0B5D4B,
  ); // Primary brand, primary buttons, logo (#0B5D4B)
  static const Color brandBright = Color(
    0xFF0F7A5F,
  ); // Links, active states, success (#0F7A5F)
  static const Color ink = Color(
    0xFF0A1F1A,
  ); // Primary text, dark surfaces (#0A1F1A)
  static const Color mint = Color(
    0xFF3DDC97,
  ); // Accent on dark surfaces, match ring, glows (#3DDC97)
  static const Color marigold = Color(
    0xFFF5A524,
  ); // Price badge, highlight fills with ink text (#F5A524)
  static const Color marigoldText = Color(
    0xFFB45309,
  ); // Amber text on white surfaces (#B45309)
  static const Color canvasLight = Color(
    0xFFF6F8F7,
  ); // Page background (#F6F8F7)
  static const Color cardLight = Color(0xFFFFFFFF); // Card surfaces (#FFFFFF)
  static const Color mutedLight = Color(0xFF5B6B66); // Secondary text (#5B6B66)
  static const Color error = Color(
    0xFFD9483B,
  ); // Error fills and icons (#D9483B)
  static const Color errorText = Color(
    0xFFC23B2F,
  ); // Small error text (#C23B2F)
  static const Color success = brandBright;
  static const Color warning = marigoldText;

  // ── Master Brief 2026 Approved Tokens (Dark) ───────────────────────────
  static const Color darkBg = Color(0xFF0A1F1A); // Dark background (#0A1F1A)
  static const Color darkSurface = Color(
    0xFF12302A,
  ); // Dark card/surface (#12302A)
  static const Color darkSurfaceHigh = Color(
    0xFF1A3D36,
  ); // Dark elevated surface (#1A3D36)
  static const Color darkText = Color(
    0xFFF2F7F5,
  ); // Primary text in dark mode (#F2F7F5)
  static const Color darkMuted = Color(
    0xFF9DB3AB,
  ); // Secondary text in dark mode (#9DB3AB)
  static const Color darkAccent = Color(
    0xFF3DDC97,
  ); // Mint accent in dark mode (#3DDC97)
  static const Color darkMarigold = Color(0xFFF5A524);

  // ── Glassmorphism & Gradient Tokens ─────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B5D4B), Color(0xFF0F7A5F)],
  );
  static const Color mintGlow = Color(0x403DDC97); // 25% opacity mint glow
  static const Color glassFillLight = Color(0x8CFFFFFF); // 55% white fill
  static const Color glassFillDark = Color(0x730A1F1A); // 45% ink fill
  static const Color glassHighlight = Color(
    0x66FFFFFF,
  ); // 40% white 1px border highlight
  static const Color glassHighlightDark = Color(
    0x333DDC97,
  ); // 20% mint highlight in dark

  // ── Backward Compatibility Aliases ──────────────────────────────────────
  static const Color primary = brand;
  static const Color primaryDark = brand;
  static const Color primaryMint = mint;
  static const Color primaryLight = Color(0xFFE8F5EF);
  static const Color primaryForest = brand;
  static const Color deepForest = ink;
  static const Color mutedSage = mutedLight;
  static const Color softForest = Color(0xFFDDE9E3);

  static const Color canvas = canvasLight;
  static const Color warmBackground = canvasLight;
  static const Color surface = cardLight;
  static const Color cardBackground = cardLight;
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8E4);
  static const Color borderLight = Color(0xFFE2E8E4);
  static const Color chipBackground = Color(0xFFEEF2EF);

  static const Color surfaceContainerLow = Color(0xFFF0F4F1);
  static const Color surfaceContainer = Color(0xFFE9EFEA);
  static const Color surfaceContainerHigh = Color(0xFFE2E8E4);
  static const Color surfaceDim = Color(0xFFD8DFDA);

  static const Color textMain = ink;
  static const Color textPrimary = ink;
  static const Color textMuted = mutedLight;
  static const Color textSecondary = mutedLight;
  static const Color textDisabled = Color(0xFF9EABA3);
  static const Color textTertiary = Color(0xFF9EABA3);

  static const Color goldStar = marigold;
  static const Color accentGold = marigold;
  static const Color mutedBrass = marigoldText;
  static const Color softBrass = Color(0xFFEFE4CD);
  static const Color urgentCoral = error;
  static const Color mutedRust = error;
  static const Color softRust = Color(0xFFFCEAE8);
  static const Color bluePolyline = Color(0xFF2563EB);

  static const Color secondary = mint;
  static const Color accent = mint;
  static const Color surfaceVariant = surfaceContainerLow;
  static const Color errorContainer = softRust;
  static const Color transparent = Colors.transparent;
}

/// Canonical backward compatibility alias for legacy widgets referencing SahyanColors.
abstract class SahyanColors {
  // Brand Greens
  static const Color primaryDark = AppColors.brand;
  static const Color primaryMint = AppColors.mint;
  static const Color primaryLight = AppColors.primaryLight;

  // Canvas & Surfaces
  static const Color canvas = AppColors.canvasLight;
  static const Color surface = AppColors.cardLight;
  static const Color border = AppColors.border;
  static const Color chipBackground = AppColors.chipBackground;

  // Typography Tokens
  static const Color textMain = AppColors.ink;
  static const Color textMuted = AppColors.mutedLight;
  static const Color textDisabled = AppColors.textDisabled;

  // Status & Highlights
  static const Color goldStar = AppColors.marigold;
  static const Color urgentCoral = AppColors.error;
  static const Color bluePolyline = AppColors.bluePolyline;
}
