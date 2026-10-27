import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Resolution-independent, vector-accurate brand painter for Sahyān.
/// Represents: "Different paths. One shared journey."
///
/// Features:
/// - Top curved emerald highway with mint border and white dashed markings.
/// - Bottom curved emerald highway with mint border and white dashed markings.
/// - Central junction hub ring connecting all paths.
/// - Right forward shared highway extending outward with directional arrow head.
/// - Origin circle nodes for separate travel origins.
/// - Smooth animated vehicle traversal with tangent-aligned natural rotation.
/// - Subtle champagne gold & mint junction pulse.
class SahyanBrandMarkPainter extends CustomPainter {
  final double drawProgress; // 0.0 to 1.0 (roads draw in)
  final double vehicleProgress; // 0.0 to 1.0 (vehicles traverse roads)
  final double hubPulseProgress; // 0.0 to 1.0 (radial ripple on hub)
  final double originProgress; // 0.0 to 1.0 (origin nodes appear)
  final bool showVehicles;
  final bool isDark;
  final Color? colorOverride;

  const SahyanBrandMarkPainter({
    this.drawProgress = 1.0,
    this.vehicleProgress = 1.0,
    this.hubPulseProgress = 0.0,
    this.originProgress = 1.0,
    this.showVehicles = false,
    this.isDark = true,
    this.colorOverride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base design coordinate space: 300 x 200
    final scale = size.width / 300.0;
    // Offset vertically if aspect ratio differs from 300:200
    final yOffset = (size.height - (200.0 * scale)) / 2.0;

    canvas.save();
    canvas.translate(0, yOffset);

    final effectiveRoadColor =
        colorOverride ?? (isDark ? AppColors.brand : AppColors.darkEmerald);
    final effectiveBorderColor = colorOverride != null
        ? colorOverride!.withValues(alpha: 0.6)
        : AppColors.softMint;
    final effectiveDashedColor = colorOverride != null
        ? colorOverride!.withValues(alpha: 0.9)
        : Colors.white;

    // ── Build Base Paths ────────────────────────────────────────────────────
    // 1. Top Curved Road (Origin: (45, 45) -> Hub: (150, 100))
    final topPath = Path()
      ..moveTo(45 * scale, 45 * scale)
      ..cubicTo(
        95 * scale,
        45 * scale,
        120 * scale,
        78 * scale,
        150 * scale,
        100 * scale,
      );

    // 2. Bottom Curved Road (Origin: (45, 155) -> Hub: (150, 100))
    final bottomPath = Path()
      ..moveTo(45 * scale, 155 * scale)
      ..cubicTo(
        95 * scale,
        155 * scale,
        120 * scale,
        122 * scale,
        150 * scale,
        100 * scale,
      );

    // 3. Right Converged Highway (Hub: (150, 100) -> Exit: (252, 100))
    final rightPath = Path()
      ..moveTo(150 * scale, 100 * scale)
      ..lineTo(252 * scale, 100 * scale);

    final clampedDraw = drawProgress.clamp(0.0, 1.0);

    // ── Hub Pulse Wave (Convergence trigger) ────────────────────────────────
    if (hubPulseProgress > 0.0 && hubPulseProgress < 1.0) {
      final pulseRadius = (22.0 + (hubPulseProgress * 32.0)) * scale;
      final pulsePaint = Paint()
        ..color = (colorOverride ?? AppColors.champagneGold).withValues(
          alpha: (1.0 - hubPulseProgress) * 0.45,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * scale;
      canvas.drawCircle(
        Offset(150 * scale, 100 * scale),
        pulseRadius,
        pulsePaint,
      );

      final mintPulsePaint = Paint()
        ..color = AppColors.softMint.withValues(
          alpha: (1.0 - hubPulseProgress) * 0.35,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale;
      canvas.drawCircle(
        Offset(150 * scale, 100 * scale),
        pulseRadius * 0.85,
        mintPulsePaint,
      );
    }

    if (clampedDraw <= 0.0) {
      canvas.restore();
      return;
    }

    // ── Road Borders (Mint/light outline behind road surface) ────────────────
    final borderPaint = Paint()
      ..color = effectiveBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Road Surfaces (Emerald green fill) ───────────────────────────────────
    final roadPaint = Paint()
      ..color = effectiveRoadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Dashed Center Line Paint ─────────────────────────────────────────────
    final dashPaint = Paint()
      ..color = effectiveDashedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;

    // Arrow fill paints
    final arrowBorderPaint = Paint()
      ..color = effectiveBorderColor
      ..style = PaintingStyle.fill;
    final arrowRoadPaint = Paint()
      ..color = effectiveRoadColor
      ..style = PaintingStyle.fill;

    // Extract paths based on drawProgress
    final topMetric = topPath.computeMetrics().firstOrNull;
    final bottomMetric = bottomPath.computeMetrics().firstOrNull;
    final rightMetric = rightPath.computeMetrics().firstOrNull;

    final topLen = topMetric?.length ?? 1.0;
    final bottomLen = bottomMetric?.length ?? 1.0;
    final rightLen = rightMetric?.length ?? 1.0;

    // Timing splits:
    // 0.0 to 0.70: Top and Bottom roads draw into hub
    // 0.65 to 1.0: Right road extends outward and arrow pops
    final inProgress = (clampedDraw / 0.70).clamp(0.0, 1.0);
    final outProgress = ((clampedDraw - 0.65) / 0.35).clamp(0.0, 1.0);

    final drawnTop = topMetric != null && inProgress > 0.0
        ? topMetric.extractPath(0, topLen * inProgress)
        : null;
    final drawnBottom = bottomMetric != null && inProgress > 0.0
        ? bottomMetric.extractPath(0, bottomLen * inProgress)
        : null;
    final drawnRight = rightMetric != null && outProgress > 0.0
        ? rightMetric.extractPath(0, rightLen * outProgress)
        : null;

    // 1. Draw Borders
    if (drawnTop != null) canvas.drawPath(drawnTop, borderPaint);
    if (drawnBottom != null) canvas.drawPath(drawnBottom, borderPaint);
    if (drawnRight != null) canvas.drawPath(drawnRight, borderPaint);

    // Arrow Head Border (at right end)
    if (outProgress >= 0.85) {
      final arrowScale = ((outProgress - 0.85) / 0.15).clamp(0.0, 1.0);
      final arrowPath = Path()
        ..moveTo(244 * scale, (100 - (20 * arrowScale)) * scale)
        ..lineTo((244 + (28 * arrowScale)) * scale, 100 * scale)
        ..lineTo(244 * scale, (100 + (20 * arrowScale)) * scale)
        ..close();
      canvas.drawPath(arrowPath, arrowBorderPaint);
    }

    // 2. Draw Road Surfaces
    if (drawnTop != null) canvas.drawPath(drawnTop, roadPaint);
    if (drawnBottom != null) canvas.drawPath(drawnBottom, roadPaint);
    if (drawnRight != null) canvas.drawPath(drawnRight, roadPaint);

    // Arrow Head Road Surface
    if (outProgress >= 0.85) {
      final arrowScale = ((outProgress - 0.85) / 0.15).clamp(0.0, 1.0);
      final innerArrow = Path()
        ..moveTo(244 * scale, (100 - (15 * arrowScale)) * scale)
        ..lineTo((244 + (22 * arrowScale)) * scale, 100 * scale)
        ..lineTo(244 * scale, (100 + (15 * arrowScale)) * scale)
        ..close();
      canvas.drawPath(innerArrow, arrowRoadPaint);
    }

    // 3. Draw Dashed Lane Lines along each path
    if (drawnTop != null) {
      _drawDashedPath(canvas, drawnTop, dashPaint, 6.0 * scale, 7.0 * scale);
    }
    if (drawnBottom != null) {
      _drawDashedPath(canvas, drawnBottom, dashPaint, 6.0 * scale, 7.0 * scale);
    }
    if (drawnRight != null) {
      _drawDashedPath(canvas, drawnRight, dashPaint, 6.0 * scale, 7.0 * scale);
    }

    // 4. Origin Circle Nodes
    final effectiveOriginScale = originProgress.clamp(0.0, 1.0);
    if (effectiveOriginScale > 0.0) {
      _drawOriginNode(
        canvas,
        Offset(45 * scale, 45 * scale),
        14.0 * scale * effectiveOriginScale,
        effectiveBorderColor,
        effectiveRoadColor,
      );
      _drawOriginNode(
        canvas,
        Offset(45 * scale, 155 * scale),
        14.0 * scale * effectiveOriginScale,
        effectiveBorderColor,
        effectiveRoadColor,
      );
    }

    // 5. Central Junction Hub Node (Concentric rings)
    if (inProgress >= 0.70) {
      final hubScale = ((inProgress - 0.70) / 0.30).clamp(0.0, 1.0);
      _drawCentralHub(
        canvas,
        Offset(150 * scale, 100 * scale),
        22.0 * scale * hubScale,
        effectiveBorderColor,
        effectiveRoadColor,
        scale,
      );
    }

    // ── Animated Vehicles ───────────────────────────────────────────────────
    if (showVehicles && clampedDraw > 0.25) {
      _paintVehicles(canvas, topMetric, bottomMetric, rightMetric, scale);
    }

    canvas.restore();
  }

  void _drawOriginNode(
    Canvas canvas,
    Offset center,
    double radius,
    Color outerColor,
    Color innerColor,
  ) {
    if (radius <= 0) return;
    // Outer mint ring
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Dark ring border
    final strokePaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.28;
    canvas.drawCircle(center, radius * 0.9, strokePaint);

    // Inner bright center dot
    final centerPaint = Paint()
      ..color = isDark ? AppColors.lightSurface : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.50, centerPaint);
  }

  void _drawCentralHub(
    Canvas canvas,
    Offset center,
    double radius,
    Color outerColor,
    Color innerColor,
    double scale,
  ) {
    if (radius <= 0) return;
    // Outer Mint Hub Ring
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Outer Dark Rim
    final rimPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale;
    canvas.drawCircle(center, radius, rimPaint);

    // Inner Emerald Well
    final innerPaint = Paint()
      ..color = isDark ? AppColors.darkEmerald : AppColors.brand
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.65, innerPaint);

    // Core Connection Dot
    final corePaint = Paint()
      ..color = isDark ? AppColors.softMint : AppColors.brandBright
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.32, corePaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path sourcePath,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    for (final metric in sourcePath.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashLength, metric.length - distance);
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  void _paintVehicles(
    Canvas canvas,
    PathMetric? topMetric,
    PathMetric? bottomMetric,
    PathMetric? rightMetric,
    double scale,
  ) {
    final vp = vehicleProgress.clamp(0.0, 1.0);

    // Phase 1: Incoming Vehicles on Top and Bottom Paths (0.0 to 0.65)
    if (vp <= 0.68) {
      final inT = (vp / 0.58).clamp(0.0, 1.0);
      final alpha = inT > 0.82 ? ((1.0 - inT) / 0.18).clamp(0.0, 1.0) : 1.0;

      // Top Path: Compact Car traveling toward hub
      if (topMetric != null && alpha > 0.0) {
        final dist = topMetric.length * inT;
        final tangent = topMetric.getTangentForOffset(dist);
        if (tangent != null) {
          canvas.save();
          canvas.translate(tangent.position.dx, tangent.position.dy);
          canvas.rotate(tangent.angle);
          if (alpha < 1.0) {
            canvas.saveLayer(
              null,
              Paint()
                ..color = Color.fromARGB((255 * alpha).round(), 255, 255, 255),
            );
          }
          _drawCompactCar(canvas, scale, isShared: false);
          if (alpha < 1.0) {
            canvas.restore();
          }
          canvas.restore();
        }
      }

      // Bottom Path: Motorcycle traveling toward hub
      if (bottomMetric != null && alpha > 0.0) {
        final dist = bottomMetric.length * inT;
        final tangent = bottomMetric.getTangentForOffset(dist);
        if (tangent != null) {
          canvas.save();
          canvas.translate(tangent.position.dx, tangent.position.dy);
          canvas.rotate(tangent.angle);
          if (alpha < 1.0) {
            canvas.saveLayer(
              null,
              Paint()
                ..color = Color.fromARGB((255 * alpha).round(), 255, 255, 255),
            );
          }
          _drawMotorcycle(canvas, scale);
          if (alpha < 1.0) {
            canvas.restore();
          }
          canvas.restore();
        }
      }
    }

    // Phase 2: Converged Shared Vehicle along Right Highway (0.50 to 1.0)
    if (vp >= 0.50 && rightMetric != null) {
      final outT = ((vp - 0.50) / 0.50).clamp(0.0, 1.0);
      final alpha = outT < 0.20 ? (outT / 0.20).clamp(0.0, 1.0) : 1.0;
      final dist = rightMetric.length * outT;
      final tangent = rightMetric.getTangentForOffset(dist);
      if (tangent != null && alpha > 0.0) {
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(tangent.angle);
        if (alpha < 1.0) {
          canvas.saveLayer(
            null,
            Paint()
              ..color = Color.fromARGB((255 * alpha).round(), 255, 255, 255),
          );
        }
        _drawCompactCar(canvas, scale, isShared: true);
        if (alpha < 1.0) {
          canvas.restore();
        }
        canvas.restore();
      }
    }
  }

  /// Compact car drawn with clean vector geometry (facing right: 0 rad)
  void _drawCompactCar(Canvas canvas, double scale, {required bool isShared}) {
    final w = 24.0 * scale;
    final h = 13.0 * scale;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 1.5 * scale),
          width: w * 0.98,
          height: h * 0.95,
        ),
        Radius.circular(3.5 * scale),
      ),
      shadowPaint,
    );

    // Body Chassis (Pearl white/champagne car)
    final bodyPaint = Paint()
      ..color = isShared ? const Color(0xFFFFFFFF) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(4.0 * scale),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Thin chassis outline
    final outlinePaint = Paint()
      ..color = isShared ? AppColors.champagneGold : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(bodyRect, outlinePaint);

    // Front Windshield (curved black glass)
    final frontGlass = Path()
      ..moveTo(2.5 * scale, -4.5 * scale)
      ..lineTo(5.5 * scale, -3.5 * scale)
      ..lineTo(5.5 * scale, 3.5 * scale)
      ..lineTo(2.5 * scale, 4.5 * scale)
      ..close();
    canvas.drawPath(frontGlass, Paint()..color = const Color(0xFF0F172A));

    // Cabin Roof Deck
    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-1.5 * scale, 0),
        width: 9.0 * scale,
        height: 7.0 * scale,
      ),
      Radius.circular(2.0 * scale),
    );
    canvas.drawRRect(
      roofRect,
      Paint()..color = isShared ? AppColors.brand : const Color(0xFF1E293B),
    );

    // Rear Window Glass
    final rearGlass = Path()
      ..moveTo(-6.5 * scale, -4.0 * scale)
      ..lineTo(-8.5 * scale, -3.0 * scale)
      ..lineTo(-8.5 * scale, 3.0 * scale)
      ..lineTo(-6.5 * scale, 4.0 * scale)
      ..close();
    canvas.drawPath(rearGlass, Paint()..color = const Color(0xFF0F172A));

    // Dual Front Headlights (Amber / bright white)
    final lightPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawCircle(
      Offset((w / 2) - (1.0 * scale), -3.5 * scale),
      1.2 * scale,
      lightPaint,
    );
    canvas.drawCircle(
      Offset((w / 2) - (1.0 * scale), 3.5 * scale),
      1.2 * scale,
      lightPaint,
    );

    // Dual Rear Taillights (Red)
    final tailPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(
      Offset((-w / 2) + (1.0 * scale), -3.5 * scale),
      1.0 * scale,
      tailPaint,
    );
    canvas.drawCircle(
      Offset((-w / 2) + (1.0 * scale), 3.5 * scale),
      1.0 * scale,
      tailPaint,
    );
  }

  /// Two-wheeler / Motorcycle with rider helmet (facing right: 0 rad)
  void _drawMotorcycle(Canvas canvas, double scale) {
    final w = 18.0 * scale;
    final h = 8.5 * scale;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 1.0 * scale),
        width: w * 0.95,
        height: h * 0.85,
      ),
      shadowPaint,
    );

    // Front & Rear Rubber Tires
    final tirePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(7.0 * scale, 0),
          width: 3.5 * scale,
          height: 2.2 * scale,
        ),
        Radius.circular(1.0 * scale),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-6.5 * scale, 0),
          width: 3.5 * scale,
          height: 2.5 * scale,
        ),
        Radius.circular(1.0 * scale),
      ),
      tirePaint,
    );

    // Bike Frame (Emerald / Orange sports commuter)
    final framePath = Path()
      ..moveTo(5.0 * scale, 0)
      ..lineTo(1.5 * scale, -2.5 * scale)
      ..lineTo(-4.5 * scale, -2.0 * scale)
      ..lineTo(-6.0 * scale, 0)
      ..lineTo(-4.5 * scale, 2.0 * scale)
      ..lineTo(1.5 * scale, 2.5 * scale)
      ..close();
    canvas.drawPath(framePath, Paint()..color = const Color(0xFFEA580C));

    // Handlebar line
    canvas.drawLine(
      Offset(4.0 * scale, -3.5 * scale),
      Offset(4.0 * scale, 3.5 * scale),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Rider Helmet (Crisp white helmet with dark visor)
    final helmetPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, 0), 2.8 * scale, helmetPaint);
    canvas.drawCircle(
      Offset(0, 0),
      2.8 * scale,
      Paint()
        ..color = const Color(0xFFEA580C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale,
    );
    // Dark Visor pointing forward
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(1.5 * scale, 0),
          width: 1.2 * scale,
          height: 2.8 * scale,
        ),
        Radius.circular(0.5 * scale),
      ),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Front Headlight
    canvas.drawCircle(
      Offset(8.0 * scale, 0),
      1.2 * scale,
      Paint()..color = const Color(0xFFFEF08A),
    );
    // Rear Taillight
    canvas.drawCircle(
      Offset(-8.0 * scale, 0),
      1.0 * scale,
      Paint()..color = const Color(0xFFEF4444),
    );
  }

  @override
  bool shouldRepaint(covariant SahyanBrandMarkPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.vehicleProgress != vehicleProgress ||
        oldDelegate.hubPulseProgress != hubPulseProgress ||
        oldDelegate.originProgress != originProgress ||
        oldDelegate.showVehicles != showVehicles ||
        oldDelegate.isDark != isDark ||
        oldDelegate.colorOverride != colorOverride;
  }
}

/// Standalone, reusable brand mark widget for headers, cards, and dialogs.
class SahyanBrandMark extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool showVehicles;
  final Color? color;

  const SahyanBrandMark({
    super.key,
    this.size = 48,
    this.isDark = true,
    this.showVehicles = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 3:2 aspect ratio maintains the converging geometry perfectly
    return SizedBox(
      width: size * 1.35,
      height: size * 0.90,
      child: CustomPaint(
        painter: SahyanBrandMarkPainter(
          drawProgress: 1.0,
          vehicleProgress: 1.0,
          hubPulseProgress: 0.0,
          showVehicles: showVehicles,
          isDark: isDark,
          colorOverride: color,
        ),
      ),
    );
  }
}
