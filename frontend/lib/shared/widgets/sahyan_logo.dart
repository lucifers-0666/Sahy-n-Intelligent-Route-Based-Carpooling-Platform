import 'dart:math' as math;
import 'package:flutter/material.dart';

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

/// Production-ready vector logo widget for Sahyān
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

  Color get _accentColor {
    switch (theme) {
      case SahyanLogoTheme.primaryGreen:
        return SahyanBrandColors.accentMint;
      case SahyanLogoTheme.monochromeWhite:
        return Colors.white.withValues(alpha: 0.8);
      case SahyanLogoTheme.monochromeDark:
        return const Color(0xFF555555);
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

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SahyanLogoVariant.symbolOnly:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SahyanSymbolPainter(
              primaryColor: _primaryColor,
              accentColor: _accentColor,
            ),
          ),
        );

      case SahyanLogoVariant.wordmarkOnly:
        return _buildWordmark(context);

      case SahyanLogoVariant.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _SahyanSymbolPainter(
                  primaryColor: _primaryColor,
                  accentColor: _accentColor,
                ),
              ),
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
            SizedBox(
              width: size * 1.4,
              height: size * 1.4,
              child: CustomPaint(
                painter: _SahyanSymbolPainter(
                  primaryColor: _primaryColor,
                  accentColor: _accentColor,
                ),
              ),
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

/// Custom painter executing the mathematical geometric construction of the Sahyān symbol
class _SahyanSymbolPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const _SahyanSymbolPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.scale(scale);

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Upper Route Arc: Originates at top-left, curves smoothly into central corridor
    final upperPath = Path()
      ..moveTo(22, 28)
      ..cubicTo(36, 28, 52, 40, 64, 54)
      ..lineTo(88, 54)
      ..cubicTo(92, 54, 94, 57, 92, 60)
      ..lineTo(76, 74)
      ..cubicTo(73, 76, 69, 74, 69, 70)
      ..lineTo(69, 66)
      ..cubicTo(58, 56, 46, 44, 22, 44)
      ..cubicTo(18, 44, 16, 40, 16, 36)
      ..cubicTo(16, 32, 18, 28, 22, 28)
      ..close();

    // Lower Route Arc: Converges from bottom-left into shared corridor
    final lowerPath = Path()
      ..moveTo(22, 92)
      ..cubicTo(36, 92, 52, 80, 64, 66)
      ..lineTo(88, 66)
      ..cubicTo(92, 66, 94, 63, 92, 60)
      ..lineTo(76, 46)
      ..cubicTo(73, 44, 69, 46, 69, 50)
      ..lineTo(69, 54)
      ..cubicTo(58, 64, 46, 76, 22, 76)
      ..cubicTo(18, 76, 16, 80, 16, 84)
      ..cubicTo(16, 88, 18, 92, 22, 92)
      ..close();

    // Dynamic Convergence Core: Forward-pointing match apex
    final apexPath = Path()
      ..moveTo(58, 60)
      ..lineTo(78, 43)
      ..cubicTo(81, 40, 86, 42, 86, 47)
      ..lineTo(86, 73)
      ..cubicTo(86, 78, 81, 80, 78, 77)
      ..close();

    canvas.drawPath(upperPath, primaryPaint);
    canvas.drawPath(lowerPath, primaryPaint);
    canvas.drawPath(apexPath, accentPaint);

    // Sync Point Node
    canvas.drawCircle(const Offset(68, 60), 4.5, nodePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SahyanSymbolPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
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
