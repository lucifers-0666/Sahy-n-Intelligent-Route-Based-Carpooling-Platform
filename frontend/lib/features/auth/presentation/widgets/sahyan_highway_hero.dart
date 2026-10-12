import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';

/// Original premium mobility illustration for Sahyān.
///
/// Depicts a Gujarat-inspired express highway corridor at sunrise dawn:
/// - Contemporary crossover carpool vehicle carrying two adult passengers
/// - Scenic Saurashtra hills, acacia tree silhouettes, and windmills along the horizon
/// - Forest green and emerald brand tones with warm horizon glow
/// - Frosted Gujarat corridor indicator: "Ahmedabad → Rajkot"
/// - High-resolution asset integration with robust procedural fallback
class SahyanHighwaySunriseHero extends StatelessWidget {
  final double height;
  final bool isDark;

  const SahyanHighwaySunriseHero({
    super.key,
    this.height = 340.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Primary High-Resolution Original Artwork
            Image.asset(
              'assets/branding/sahyan_highway_hero.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.2),
              errorBuilder: (context, error, stackTrace) {
                // Seamless procedural vector fallback if asset is unavailable or in headless tests
                return CustomPaint(
                  painter: _HighwaySunrisePainter(isDark: isDark),
                  size: Size(double.infinity, height),
                );
              },
            ),

            // 2. Ambient Theme Tint (balances dark mode contrast)
            if (isDark) Container(color: Colors.black.withValues(alpha: 0.24)),

            // 3. Top Gradient Vignette for Status Bar & Badge Legibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: math.max(topPadding + 70.0, 110.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : const Color(0xFF072B22))
                          .withValues(alpha: isDark ? 0.65 : 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // 4. Bottom Blend Gradient into Frosted Sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 72.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? AppColors.darkBg : AppColors.canvasLight)
                          .withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // 5. Floating Route Corridor Badge ("Ahmedabad → Rajkot")
            Positioned(
              top: topPadding + 14.0,
              left: 20.0,
              child: _RouteCorridorBadge(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted Glass Route Corridor Badge
class _RouteCorridorBadge extends StatelessWidget {
  final bool isDark;

  const _RouteCorridorBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : Colors.white).withValues(
              alpha: isDark ? 0.45 : 0.88,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.mint.withValues(alpha: isDark ? 0.4 : 0.5),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Ahmedabad  →  Rajkot',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.ink,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Procedural vector fallback illustration
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
                const Color(0xFF5A3515), // Twilight Warmth
              ]
            : [
                const Color(0xFF0B5D4B), // Brand Forest Dawn
                const Color(0xFF1E8268), // Fresh Morning Emerald
                const Color(0xFFFBD38D), // Warm Amber Glow at Horizon
              ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Horizon Glow Diffusion (Warm ambient morning light, no blank white circle)
    final horizonCenter = Offset(w * 0.72, h * 0.44);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFFF5A524) : const Color(0xFFFFF1C2))
              .withValues(alpha: isDark ? 0.55 : 0.75),
          (isDark ? const Color(0xFF0B5D4B) : const Color(0xFFFBD38D))
              .withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: horizonCenter, radius: h * 0.42));

    canvas.drawCircle(horizonCenter, h * 0.42, glowPaint);

    // 3. Distant Saurashtra Hills / Ridge Silhouettes
    final hillPath1 = Path()
      ..moveTo(0, h * 0.48)
      ..quadraticBezierTo(w * 0.26, h * 0.43, w * 0.50, h * 0.47)
      ..quadraticBezierTo(w * 0.74, h * 0.51, w, h * 0.46)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint1 = Paint()
      ..color = (isDark ? const Color(0xFF093127) : const Color(0xFF0E634F))
          .withValues(alpha: 0.85);
    canvas.drawPath(hillPath1, hillPaint1);

    final hillPath2 = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.32, h * 0.49, w * 0.60, h * 0.54)
      ..quadraticBezierTo(w * 0.84, h * 0.50, w, h * 0.53)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint2 = Paint()
      ..color = isDark ? const Color(0xFF06231C) : const Color(0xFF084839);
    canvas.drawPath(hillPath2, hillPaint2);

    // Distant Windmill Silhouettes
    final windmillPaint = Paint()
      ..color = (isDark ? AppColors.mint : Colors.white).withValues(alpha: 0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _drawWindmill(canvas, Offset(w * 0.22, h * 0.41), windmillPaint);
    _drawWindmill(canvas, Offset(w * 0.32, h * 0.43), windmillPaint);

    // 4. Highway Perspective Ribbon
    final horizonY = h * 0.51;
    final vanishingX = w * 0.52;

    final roadPath = Path()
      ..moveTo(vanishingX - (w * 0.04), horizonY)
      ..lineTo(vanishingX + (w * 0.04), horizonY)
      ..lineTo(w * 0.94, h)
      ..lineTo(w * 0.06, h)
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
      Offset(w * 0.06, h),
      shoulderPaint,
    );
    canvas.drawLine(
      Offset(vanishingX + (w * 0.04), horizonY),
      Offset(w * 0.94, h),
      shoulderPaint,
    );

    // Dashed Center Divider Line
    final centerDashPaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const steps = 6;
    for (int i = 0; i < steps; i++) {
      final t1 = i / steps;
      final t2 = (i + 0.6) / steps;
      final y1 = horizonY + (h - horizonY) * math.pow(t1, 1.6);
      final y2 = horizonY + (h - horizonY) * math.pow(t2, 1.6);
      final x1 = vanishingX + (w * 0.01) * t1;
      final x2 = vanishingX + (w * 0.01) * t2;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), centerDashPaint);
    }

    // 5. Shared Carpool Vehicle (Positioned high at 0.58 so visible above sheet)
    final carY = h * 0.58;
    final carX = w * 0.42;
    final carW = w * 0.24;
    final carH = h * 0.12;

    // Soft car shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(carX, carY + (carH * 0.45)),
        width: carW * 1.1,
        height: carH * 0.35,
      ),
      shadowPaint,
    );

    // Car Body
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

    // Rear Windshield Glass
    final windowPath = Path()
      ..moveTo(carX - carW * 0.32, carY - carH * 0.05)
      ..lineTo(carX - carW * 0.14, carY - carH * 0.36)
      ..lineTo(carX + carW * 0.14, carY - carH * 0.36)
      ..lineTo(carX + carW * 0.32, carY - carH * 0.05)
      ..close();

    final windowPaint = Paint()..color = const Color(0xFF072B22);
    canvas.drawPath(windowPath, windowPaint);

    // Passenger Silhouettes (2 Adult Riders travelling together)
    final passengerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(
      Offset(carX - carW * 0.12, carY - carH * 0.18),
      carW * 0.055,
      passengerPaint,
    );
    canvas.drawCircle(
      Offset(carX + carW * 0.12, carY - carH * 0.18),
      carW * 0.055,
      passengerPaint,
    );

    // Modern Tail Lights
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
  }

  void _drawWindmill(Canvas canvas, Offset base, Paint paint) {
    canvas.drawLine(base, Offset(base.dx, base.dy - 16), paint);
    canvas.drawLine(
      Offset(base.dx - 6, base.dy - 16),
      Offset(base.dx + 6, base.dy - 16),
      paint,
    );
    canvas.drawLine(
      Offset(base.dx, base.dy - 22),
      Offset(base.dx, base.dy - 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HighwaySunrisePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
