import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Original vector hero illustration depicting a Gujarat highway at sunrise.
///
/// Features:
/// - Atmospheric morning sky gradient over the Gujarat horizon
/// - Distant Saurashtra ridgelines and landscape silhouettes
/// - Express highway corridor (NH48 / NE1) with perspective lines
/// - Floating route indicator: "Ahmedabad → Rajkot"
/// - Car with sharing passengers moving forward together
/// - Responsive scaling without pixelation or heavy image assets
class SahyanHighwaySunriseHero extends StatelessWidget {
  final double height;
  final bool isDark;

  const SahyanHighwaySunriseHero({
    super.key,
    this.height = 320.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: CustomPaint(
          painter: _HighwaySunrisePainter(isDark: isDark),
          size: Size(double.infinity, height),
        ),
      ),
    );
  }
}

class _HighwaySunrisePainter extends CustomPainter {
  final bool isDark;

  _HighwaySunrisePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient (Sunrise over Gujarat)
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF071F19), // Midnight Pine
                const Color(0xFF0B5D4B), // Brand Forest
                const Color(0xFF7A4A1E), // Twilight Warmth
              ]
            : [
                const Color(0xFF0B5D4B), // Brand Forest Dawn
                const Color(0xFF1E8268), // Fresh Morning Emerald
                const Color(0xFFFBD38D), // Warm Amber Glow at Horizon
              ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Rising Sun Disc with Ambient Halo
    final sunCenter = Offset(w * 0.62, h * 0.52);
    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? AppColors.marigold : const Color(0xFFFFF3C4)).withValues(
            alpha: 0.6,
          ),
          AppColors.marigold.withValues(alpha: 0.15),
          AppColors.marigold.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: h * 0.35));

    canvas.drawCircle(sunCenter, h * 0.35, sunGlowPaint);

    final sunDiscPaint = Paint()
      ..color = isDark ? const Color(0xFFFFD166) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, h * 0.09, sunDiscPaint);

    // 3. Distant Saurashtra Hills / Skyline Ridges
    final hillPath1 = Path()
      ..moveTo(0, h * 0.58)
      ..quadraticBezierTo(w * 0.25, h * 0.52, w * 0.48, h * 0.57)
      ..quadraticBezierTo(w * 0.72, h * 0.62, w, h * 0.56)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint1 = Paint()
      ..color = (isDark ? const Color(0xFF093127) : const Color(0xFF0E634F))
          .withValues(alpha: 0.75);
    canvas.drawPath(hillPath1, hillPaint1);

    final hillPath2 = Path()
      ..moveTo(0, h * 0.63)
      ..quadraticBezierTo(w * 0.35, h * 0.59, w * 0.62, h * 0.65)
      ..quadraticBezierTo(w * 0.85, h * 0.61, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint2 = Paint()
      ..color = isDark ? const Color(0xFF06231C) : const Color(0xFF084839);
    canvas.drawPath(hillPath2, hillPaint2);

    // 4. Highway Corridor (Perspective Highway Ribbon)
    final horizonY = h * 0.64;
    final vanishingX = w * 0.52;

    final roadPath = Path()
      ..moveTo(vanishingX - (w * 0.04), horizonY)
      ..lineTo(vanishingX + (w * 0.04), horizonY)
      ..lineTo(w * 0.92, h)
      ..lineTo(w * 0.08, h)
      ..close();

    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF092A22), const Color(0xFF051713)]
            : [const Color(0xFF134538), const Color(0xFF0A2B23)],
      ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY));

    canvas.drawPath(roadPath, roadPaint);

    // Highway Shoulder Lines (Mint glow guide lines)
    final shoulderPaint = Paint()
      ..color = AppColors.mint.withValues(alpha: isDark ? 0.4 : 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(vanishingX - (w * 0.04), horizonY),
      Offset(w * 0.08, h),
      shoulderPaint,
    );
    canvas.drawLine(
      Offset(vanishingX + (w * 0.04), horizonY),
      Offset(w * 0.92, h),
      shoulderPaint,
    );

    // Dashed Center Divider Line
    final centerDashPaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.85)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final steps = 7;
    for (int i = 0; i < steps; i++) {
      final t1 = i / steps;
      final t2 = (i + 0.6) / steps;
      final y1 = horizonY + (h - horizonY) * math.pow(t1, 1.6);
      final y2 = horizonY + (h - horizonY) * math.pow(t2, 1.6);
      final x1 = vanishingX + (w * 0.01) * t1;
      final x2 = vanishingX + (w * 0.01) * t2;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), centerDashPaint);
    }

    // 5. Shared Carpool Vehicle on the Highway
    final carY = h * 0.74;
    final carX = w * 0.55;
    final carW = w * 0.22;
    final carH = h * 0.11;

    // Soft car shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(carX, carY + (carH * 0.45)),
        width: carW * 1.1,
        height: carH * 0.35,
      ),
      shadowPaint,
    );

    // Car Body (Modern aerodynamic crossover)
    final carBody = Path()
      ..moveTo(carX - carW * 0.48, carY + carH * 0.35)
      ..lineTo(carX - carW * 0.46, carY + carH * 0.05)
      ..quadraticBezierTo(
        carX - carW * 0.35,
        carY - carH * 0.22,
        carX - carW * 0.15,
        carY - carH * 0.42,
      )
      ..lineTo(carX + carW * 0.15, carY - carH * 0.42)
      ..quadraticBezierTo(
        carX + carW * 0.38,
        carY - carH * 0.22,
        carX + carW * 0.48,
        carY + carH * 0.05,
      )
      ..lineTo(carX + carW * 0.48, carY + carH * 0.35)
      ..close();

    final carPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF3DDC97), const Color(0xFF0F7A5F)]
                : [Colors.white, const Color(0xFFD6EDE4)],
          ).createShader(
            Rect.fromLTWH(carX - carW / 2, carY - carH / 2, carW, carH),
          );

    canvas.drawPath(carBody, carPaint);

    // Car Rear Windshield Glass
    final windowPath = Path()
      ..moveTo(carX - carW * 0.32, carY - carH * 0.05)
      ..lineTo(carX - carW * 0.14, carY - carH * 0.36)
      ..lineTo(carX + carW * 0.14, carY - carH * 0.36)
      ..lineTo(carX + carW * 0.32, carY - carH * 0.05)
      ..close();

    final windowPaint = Paint()..color = const Color(0xFF072B22);
    canvas.drawPath(windowPath, windowPaint);

    // Passenger Silhouettes inside (Two riders travelling together)
    final passengerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85);
    // Driver silhouette
    canvas.drawCircle(
      Offset(carX - carW * 0.12, carY - carH * 0.18),
      carW * 0.055,
      passengerPaint,
    );
    // Passenger silhouette
    canvas.drawCircle(
      Offset(carX + carW * 0.12, carY - carH * 0.18),
      carW * 0.055,
      passengerPaint,
    );

    // Tail Lights (Subtle warm amber/ruby glow)
    final tailLightPaint = Paint()
      ..color = const Color(0xFFFF4D4D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          carX - carW * 0.44,
          carY + carH * 0.1,
          carW * 0.14,
          carH * 0.12,
        ),
        const Radius.circular(2),
      ),
      tailLightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          carX + carW * 0.30,
          carY + carH * 0.1,
          carW * 0.14,
          carH * 0.12,
        ),
        const Radius.circular(2),
      ),
      tailLightPaint,
    );

    // 6. Floating Route Corridor Badge ("Ahmedabad → Rajkot")
    final badgeCenter = Offset(w * 0.28, h * 0.32);
    final badgeWidth = 148.0;
    final badgeHeight = 28.0;
    final badgeRect = Rect.fromCenter(
      center: badgeCenter,
      width: badgeWidth,
      height: badgeHeight,
    );

    final badgeBgPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.85)
      ..style = PaintingStyle.fill;
    final badgeBorderPaint = Paint()
      ..color = AppColors.mint.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(999),
    );
    canvas.drawRRect(badgeRRect, badgeBgPaint);
    canvas.drawRRect(badgeRRect, badgeBorderPaint);

    // Pulsing Mint Pin Dot
    canvas.drawCircle(
      Offset(badgeCenter.dx - 56, badgeCenter.dy),
      3.5,
      Paint()..color = AppColors.mint,
    );

    // Route Text on badge
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Ahmedabad  →  Rajkot',
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.ink,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - (textPainter.width / 2) + 6,
        badgeCenter.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _HighwaySunrisePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
