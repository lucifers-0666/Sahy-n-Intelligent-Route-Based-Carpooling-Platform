import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

enum SahyanLogoVariant {
  mark,
  symbolOnly,
  horizontal,
  stacked,
  mono,
  wordmarkOnly,
}

enum SahyanLogoTheme {
  primaryGreen,
  monochromeWhite,
  monochromeDark,
}

/// Official Master Logo Widget for Sahyān.
///
/// Implements the unified route convergence identity:
/// Two smooth curved route lines that merge into one single path ending in a destination node.
/// Completely geometric, resolution-independent, zero tiny details, perfectly legible at 24px.
class SahyanLogo extends StatelessWidget {
  final SahyanLogoVariant variant;
  final SahyanLogoTheme theme;
  final double size;
  final Color? color;
  final Color? textColor;
  final bool showTagline;
  final double progress; // 0.0 to 1.0 for path draw animations
  final double pulseProgress; // 0.0 to 1.0 for pulse ring animation
  final bool animatePulse;

  const SahyanLogo({
    super.key,
    this.variant = SahyanLogoVariant.horizontal,
    this.theme = SahyanLogoTheme.primaryGreen,
    this.size = 36,
    this.color,
    this.textColor,
    this.showTagline = false,
    this.progress = 1.0,
    this.pulseProgress = 0.0,
    this.animatePulse = false,
  });

  /// Standalone Mark Constructor
  const SahyanLogo.mark({
    super.key,
    this.size = 40,
    this.color,
    this.progress = 1.0,
    this.pulseProgress = 0.0,
    this.animatePulse = false,
  }) : variant = SahyanLogoVariant.mark,
       theme = SahyanLogoTheme.primaryGreen,
       showTagline = false,
       textColor = null;

  /// Horizontal Lockup Constructor
  const SahyanLogo.horizontal({
    super.key,
    this.size = 32,
    this.color,
    this.textColor,
    this.showTagline = false,
    this.progress = 1.0,
  }) : variant = SahyanLogoVariant.horizontal,
       theme = SahyanLogoTheme.primaryGreen,
       pulseProgress = 0.0,
       animatePulse = false;

  /// Stacked Lockup Constructor
  const SahyanLogo.stacked({
    super.key,
    this.size = 48,
    this.color,
    this.textColor,
    this.showTagline = false,
    this.progress = 1.0,
  }) : variant = SahyanLogoVariant.stacked,
       theme = SahyanLogoTheme.primaryGreen,
       pulseProgress = 0.0,
       animatePulse = false;

  /// Monochrome White Constructor
  const SahyanLogo.mono({
    super.key,
    this.size = 32,
    this.progress = 1.0,
  }) : variant = SahyanLogoVariant.mono,
       theme = SahyanLogoTheme.monochromeWhite,
       color = Colors.white,
       textColor = Colors.white,
       showTagline = false,
       pulseProgress = 0.0,
       animatePulse = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color effectiveMarkColor;
    if (color != null) {
      effectiveMarkColor = color!;
    } else {
      switch (theme) {
        case SahyanLogoTheme.monochromeWhite:
          effectiveMarkColor = Colors.white;
          break;
        case SahyanLogoTheme.monochromeDark:
          effectiveMarkColor = const Color(0xFF1A1A1A);
          break;
        case SahyanLogoTheme.primaryGreen:
          effectiveMarkColor = isDark ? AppColors.mint : AppColors.brand;
          break;
      }
    }

    Color effectiveTextColor;
    if (textColor != null) {
      effectiveTextColor = textColor!;
    } else {
      switch (theme) {
        case SahyanLogoTheme.monochromeWhite:
          effectiveTextColor = Colors.white;
          break;
        case SahyanLogoTheme.monochromeDark:
          effectiveTextColor = const Color(0xFF1A1A1A);
          break;
        case SahyanLogoTheme.primaryGreen:
          effectiveTextColor = isDark ? AppColors.darkText : AppColors.brand;
          break;
      }
    }

    final effectiveSubColor = theme == SahyanLogoTheme.monochromeWhite
        ? Colors.white.withValues(alpha: 0.75)
        : (isDark ? AppColors.darkMuted : AppColors.mutedLight);

    final markWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SahyanRouteConvergencePainter(
          color: effectiveMarkColor,
          progress: progress.clamp(0.0, 1.0),
          pulseProgress: pulseProgress.clamp(0.0, 1.0),
        ),
      ),
    );

    switch (variant) {
      case SahyanLogoVariant.mark:
      case SahyanLogoVariant.symbolOnly:
        return markWidget;

      case SahyanLogoVariant.wordmarkOnly:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sahyān',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.72,
                fontWeight: FontWeight.w800,
                color: effectiveTextColor,
                letterSpacing: -0.6,
                height: 1.05,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                'INTERCITY CARPOOL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: effectiveSubColor,
                  letterSpacing: 1.2,
                  height: 1.1,
                ),
              ),
            ],
          ],
        );

      case SahyanLogoVariant.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            markWidget,
            SizedBox(width: size * 0.28),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sahyān',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: size * 0.72,
                    fontWeight: FontWeight.w800,
                    color: effectiveTextColor,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                if (showTagline) ...[
                  Text(
                    'INTERCITY CARPOOL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w700,
                      color: effectiveSubColor,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

      case SahyanLogoVariant.stacked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            markWidget,
            SizedBox(height: size * 0.22),
            Text(
              'Sahyān',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.54,
                fontWeight: FontWeight.w800,
                color: effectiveTextColor,
                letterSpacing: -0.5,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                'GUJARAT CARPOOL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                  color: effectiveSubColor,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ],
        );

      case SahyanLogoVariant.mono:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _SahyanRouteConvergencePainter(
                  color: Colors.white,
                  progress: progress.clamp(0.0, 1.0),
                  pulseProgress: pulseProgress.clamp(0.0, 1.0),
                ),
              ),
            ),
            SizedBox(width: size * 0.28),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sahyān',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: size * 0.72,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                if (showTagline) ...[
                  Text(
                    'INTERCITY CARPOOL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
    }
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
                backgroundColor: AppColors.mint.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '$matchScore%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Optimal Corridors Aligned',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedLight,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Resolution-independent painter for the master route convergence logo.
/// Draws:
/// - Left curved route originating at bottom-left
/// - Right curved route originating at bottom-right
/// - Central convergence trunk
/// - Destination node pin
class _SahyanRouteConvergencePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double pulseProgress;

  _SahyanRouteConvergencePainter({
    required this.color,
    required this.progress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    final strokeWidth = 10.0 * scale;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw Pulse Ring if active
    if (pulseProgress > 0.0 && pulseProgress < 1.0) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: (1.0 - pulseProgress) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
      final pulseRadius = (7.5 + pulseProgress * 18.0) * scale;
      canvas.drawCircle(Offset(84 * scale, 50 * scale), pulseRadius, pulsePaint);
    }

    if (progress <= 0.0) return;

    // 1. Top-Left Route Inlet (Smooth curve down-right to central horizontal path)
    final topPath = Path();
    topPath.moveTo(16 * scale, 28 * scale);
    topPath.cubicTo(
      42 * scale,
      28 * scale,
      50 * scale,
      50 * scale,
      66 * scale,
      50 * scale,
    );
    topPath.lineTo(82 * scale, 50 * scale);

    // 2. Bottom-Left Route Inlet (Smooth curve up-right to central horizontal path)
    final bottomPath = Path();
    bottomPath.moveTo(16 * scale, 72 * scale);
    bottomPath.cubicTo(
      42 * scale,
      72 * scale,
      50 * scale,
      50 * scale,
      66 * scale,
      50 * scale,
    );
    bottomPath.lineTo(82 * scale, 50 * scale);

    if (progress >= 1.0) {
      // Draw both origin points (two travelers starting journeys)
      canvas.drawCircle(Offset(16 * scale, 28 * scale), 7.5 * scale, fillPaint);
      canvas.drawCircle(Offset(16 * scale, 72 * scale), 7.5 * scale, fillPaint);
      // Draw converging paths
      canvas.drawPath(topPath, strokePaint);
      canvas.drawPath(bottomPath, strokePaint);
      // Destination Terminal Node Pin (one shared destination)
      canvas.drawCircle(Offset(84 * scale, 50 * scale), 7.5 * scale, fillPaint);
    } else {
      // 1. Origin dots appear first with scale transition (0.0 to 0.25)
      final originScale = (progress / 0.25).clamp(0.0, 1.0);
      if (originScale > 0.0) {
        canvas.drawCircle(
          Offset(16 * scale, 28 * scale),
          7.5 * scale * originScale,
          fillPaint,
        );
        canvas.drawCircle(
          Offset(16 * scale, 72 * scale),
          7.5 * scale * originScale,
          fillPaint,
        );
      }

      // 2. Partial animated stroke draw (0.15 to 1.0)
      final pathDrawProgress = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final topMetrics = topPath.computeMetrics().toList();
      final bottomMetrics = bottomPath.computeMetrics().toList();

      if (topMetrics.isNotEmpty && pathDrawProgress > 0.0) {
        final extractTop = topMetrics.first.extractPath(
          0,
          topMetrics.first.length * pathDrawProgress,
        );
        canvas.drawPath(extractTop, strokePaint);
      }
      if (bottomMetrics.isNotEmpty && pathDrawProgress > 0.0) {
        final extractBottom = bottomMetrics.first.extractPath(
          0,
          bottomMetrics.first.length * pathDrawProgress,
        );
        canvas.drawPath(extractBottom, strokePaint);
      }

      // 3. Destination node appears as path reaches end
      if (progress > 0.82) {
        final nodeProgress = ((progress - 0.82) / 0.18).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(84 * scale, 50 * scale),
          7.5 * scale * nodeProgress,
          fillPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SahyanRouteConvergencePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
