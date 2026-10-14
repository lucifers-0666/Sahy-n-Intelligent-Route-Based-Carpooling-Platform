import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Subtle brand route-line background pattern for Sahyān auth screens.
/// A single route and its destination dots draw in once as the page appears.
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
      duration: const Duration(milliseconds: 1050),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _routeAnimation.value = 1;
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
    return CustomPaint(
      painter: _RouteBackgroundPainter(
        isDark: widget.isDark,
        progress: _routeAnimation,
      ),
      child: widget.child,
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
    final strokeColor = (isDark ? AppColors.mint : AppColors.brand).withValues(
      alpha: isDark ? 0.13 : 0.12,
    );

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.95, h * 0.08)
      ..cubicTo(w * 0.65, h * 0.22, w * 0.85, h * 0.48, w * 0.15, h * 0.68)
      ..cubicTo(w * 0.42, h * 0.77, w * 0.73, h * 0.84, w * 1.03, h * 0.91);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.value),
      linePaint,
    );

    for (final stop in const [0.22, 0.52, 0.82]) {
      final tangent = metric.getTangentForOffset(metric.length * stop);
      if (tangent == null) continue;
      final reveal = ((progress.value - stop * 0.72) / 0.18).clamp(0.0, 1.0);
      if (reveal == 0) continue;
      canvas.drawCircle(
        tangent.position,
        6 * reveal,
        Paint()
          ..color = strokeColor.withValues(
            alpha: strokeColor.a * 0.55 * reveal,
          ),
      );
      canvas.drawCircle(
        tangent.position,
        2.2 * reveal,
        Paint()..color = strokeColor.withValues(alpha: strokeColor.a * reveal),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
