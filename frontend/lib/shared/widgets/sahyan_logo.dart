import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official Sahyān Brand Color Palette Constants
class SahyanBrandColors {
  static const Color primary = Color(0xFF0B5D4B); // Deep Forest / Emerald Green
  static const Color secondary = Color(0xFF084C3A); // Dark Emerald
  static const Color accentMint = Color(0xFFA7E8D2); // Soft Mint
  static const Color accentGold = Color(0xFFC9A96E); // Subtle Champagne Gold
  static const Color lightSurface = Color(0xFFF2F7F4); // Pale Surface
  static const Color textMain = Color(0xFF12352E); // Deep Forest Text
  static const Color textMuted = Color(0xFF6B7F78); // Muted Sage Text
  static const Color white = Colors.white;
}

enum SahyanLogoVariant {
  horizontal, // Symbol + Wordmark
  stacked, // Symbol above Wordmark
  symbolOnly, // Standalone symbol
  wordmarkOnly, // Wordmark only
}

enum SahyanLogoTheme {
  primaryGreen, // Default emerald on light surface
  monochromeWhite, // White on dark background
  monochromeDark, // Neutral dark on light surface
}

/// Production-ready vector logo widget for Sahyān powered by official SVG branding assets.
class SahyanLogo extends StatelessWidget {
  final SahyanLogoVariant variant;
  final SahyanLogoTheme theme;
  final double size;
  final bool showTagline;

  const SahyanLogo({
    super.key,
    this.variant = SahyanLogoVariant.horizontal,
    this.theme = SahyanLogoTheme.primaryGreen,
    this.size = 36.0,
    this.showTagline = false,
  });

  Color get _primaryColor {
    switch (theme) {
      case SahyanLogoTheme.primaryGreen:
        return SahyanBrandColors.primary;
      case SahyanLogoTheme.monochromeWhite:
        return Colors.white;
      case SahyanLogoTheme.monochromeDark:
        return const Color(0xFF1A1A1A);
    }
  }

  Color get _taglineColor {
    switch (theme) {
      case SahyanLogoTheme.primaryGreen:
        return SahyanBrandColors.textMuted;
      case SahyanLogoTheme.monochromeWhite:
        return Colors.white70;
      case SahyanLogoTheme.monochromeDark:
        return const Color(0xFF777777);
    }
  }

  ColorFilter? get _svgColorFilter {
    if (theme == SahyanLogoTheme.monochromeWhite) {
      return const ColorFilter.mode(Colors.white, BlendMode.srcIn);
    }
    if (theme == SahyanLogoTheme.monochromeDark) {
      return const ColorFilter.mode(Color(0xFF1A1A1A), BlendMode.srcIn);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SahyanLogoVariant.symbolOnly:
        return SvgPicture.asset(
          'assets/branding/sahyan_symbol.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          semanticsLabel: 'Sahyān Symbol',
          colorFilter: _svgColorFilter,
        );

      case SahyanLogoVariant.wordmarkOnly:
        return _buildWordmark(context);

      case SahyanLogoVariant.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/branding/sahyan_symbol.svg',
              width: size,
              height: size,
              fit: BoxFit.contain,
              semanticsLabel: 'Sahyān Symbol',
              colorFilter: _svgColorFilter,
            ),
            SizedBox(width: size * 0.28),
            _buildWordmark(context),
          ],
        );

      case SahyanLogoVariant.stacked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/branding/sahyan_symbol.svg',
              width: size * 1.4,
              height: size * 1.4,
              fit: BoxFit.contain,
              semanticsLabel: 'Sahyān Symbol',
              colorFilter: _svgColorFilter,
            ),
            SizedBox(height: size * 0.22),
            _buildWordmark(context, centerAlign: true),
          ],
        );
    }
  }

  Widget _buildWordmark(BuildContext context, {bool centerAlign = false}) {
    final fontSize = size * 0.72;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Sahyān',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: _primaryColor,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.05),
          Text(
            'INTELLIGENT CARPOOLING',
            style: TextStyle(
              fontSize: math.max(9.0, fontSize * 0.26),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _taglineColor,
            ),
          ),
        ],
      ],
    );
  }
}



/// Supporting visual language widget for Sahyān's Route Match Score (e.g. 94% Match)
class SahyanRouteMatchBadge extends StatelessWidget {
  final int matchScore;
  final double radius;
  final bool showLabel;

  const SahyanRouteMatchBadge({
    super.key,
    required this.matchScore,
    this.radius = 28.0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (matchScore.clamp(0, 100)) / 100.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: radius * 0.18,
                backgroundColor: SahyanBrandColors.accentMint.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  SahyanBrandColors.primary,
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '$matchScore%',
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w800,
                color: SahyanBrandColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$matchScore% Route Match',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SahyanBrandColors.textMain,
                ),
              ),
              const Text(
                'Optimal Corridors Aligned',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: SahyanBrandColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
