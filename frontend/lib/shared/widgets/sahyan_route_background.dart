import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Ultra-premium ambient route and glowing orb backdrop for Sahyān auth screens.
/// Features soft blurred radial ambient glows (emerald & mint) and dynamic flowing
/// route curves with animated waypoints and pulse nodes.
class SahyanRouteBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const SahyanRouteBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  State<SahyanRouteBackground> createState() => _SahyanRouteBackgroundState();
}

class _SahyanRouteBackgroundState extends State<SahyanRouteBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _routeAnimation;

  @override
  void initState() {
    super.initState();
    _routeAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _routeAnimation.value = 1.0;
      } else {
        _routeAnimation.forward();
      }
    });
  }

  @override
  void dispose() {
    _routeAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Ambient Glow Canvas & Animated Route Painter
        CustomPaint(
          painter: _RouteBackgroundPainter(
            isDark: widget.isDark,
            progress: _routeAnimation,
          ),
        ),

        // 2. Main Content
        widget.child,
      ],
    );
  }
}

class _RouteBackgroundPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> progress;

  _RouteBackgroundPainter({required this.isDark, required this.progress})
      : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Soft Ambient Glowing Radial Orbs ──
    // Top-right emerald aura
    final topGlowCenter = Offset(w * 0.88, h * 0.14);
    final topGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? AppColors.mint : AppColors.brandBright).withValues(
            alpha: isDark ? 0.16 : 0.08,
          ),
          (isDark ? AppColors.brand : AppColors.brandBright).withValues(
            alpha: isDark ? 0.08 : 0.03,
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: topGlowCenter, radius: w * 0.55));
    canvas.drawCircle(topGlowCenter, w * 0.55, topGlowPaint);

    // Center-left mint aura
    final midGlowCenter = Offset(w * 0.12, h * 0.48);
    final midGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? AppColors.brandBright : AppColors.mint).withValues(
            alpha: isDark ? 0.12 : 0.06,
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: midGlowCenter, radius: w * 0.45));
    canvas.drawCircle(midGlowCenter, w * 0.45, midGlowPaint);

    // Bottom-right subtle highway reflection
    final botGlowCenter = Offset(w * 0.75, h * 0.82);
    final botGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? AppColors.brand : AppColors.brandBright).withValues(
            alpha: isDark ? 0.09 : 0.04,
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: botGlowCenter, radius: w * 0.5));
    canvas.drawCircle(botGlowCenter, w * 0.5, botGlowPaint);

    // ── 2. Primary Route Bezier Path ──
    final strokeColor = (isDark ? AppColors.mint : AppColors.brand).withValues(
      alpha: isDark ? 0.22 : 0.18,
    );

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(w * 0.95, h * 0.08)
      ..cubicTo(w * 0.65, h * 0.22, w * 0.85, h * 0.48, w * 0.15, h * 0.68)
      ..cubicTo(w * 0.42, h * 0.77, w * 0.73, h * 0.84, w * 1.03, h * 0.91);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final currentLength = metric.length * progress.value;
    canvas.drawPath(metric.extractPath(0, currentLength), linePaint);

    // Secondary subtle parallel harmonic trace
    final tracePaint = Paint()
      ..color = strokeColor.withValues(alpha: strokeColor.a * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final secondaryPath = Path()
      ..moveTo(w * 0.98, h * 0.10)
      ..cubicTo(w * 0.68, h * 0.24, w * 0.88, h * 0.50, w * 0.18, h * 0.70)
      ..cubicTo(w * 0.44, h * 0.79, w * 0.75, h * 0.86, w * 1.05, h * 0.93);

    final secMetrics = secondaryPath.computeMetrics().toList();
    if (secMetrics.isNotEmpty) {
      canvas.drawPath(
        secMetrics.first.extractPath(0, secMetrics.first.length * progress.value),
        tracePaint,
      );
    }

    // ── 3. Waypoint Glowing Pulsing Nodes ──
    for (final stop in const [0.22, 0.52, 0.82]) {
      final tangent = metric.getTangentForOffset(metric.length * stop);
      if (tangent == null) continue;
      final reveal = ((progress.value - stop * 0.72) / 0.18).clamp(0.0, 1.0);
      if (reveal == 0) continue;

      // Outer soft aura
      canvas.drawCircle(
        tangent.position,
        8.0 * reveal,
        Paint()
          ..color = strokeColor.withValues(
            alpha: strokeColor.a * 0.4 * reveal,
          ),
      );

      // Inner waypoint ring
      canvas.drawCircle(
        tangent.position,
        4.0 * reveal,
        Paint()
          ..color = (isDark ? AppColors.mint : AppColors.brandBright)
              .withValues(alpha: 0.8 * reveal),
      );

      // Core white center pin
      canvas.drawCircle(
        tangent.position,
        1.8 * reveal,
        Paint()..color = Colors.white.withValues(alpha: 0.95 * reveal),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

