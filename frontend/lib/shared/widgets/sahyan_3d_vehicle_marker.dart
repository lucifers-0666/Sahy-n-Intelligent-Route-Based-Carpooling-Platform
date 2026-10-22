import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sahyan/app/theme/app_colors.dart';

/// 3D Isometric Vehicle Marker with vehicle-type specific custom 3D models:
/// 1. Motorcycle / Bike: Sleek sports commuter bike with dual helmet badges.
/// 2. Scooter / Scooty: Compact urban scooter with rear seat indicator and grab rail.
/// 3. Hatchback: Compact 4-seater with sporty two-box stance and roof spoiler.
/// 4. Sedan: Luxury 5-seater with elegant three-box chassis and extended trunk.
/// 5. SUV: Rugged 7-seater with flared wheel arches and metallic roof luggage rails.
/// 6. EV / Electric: Aerodynamic electric vehicle with luminous cyan battery glow.
class Sahyan3DVehicleMarker extends StatefulWidget {
  final String vehicleTypeCode;
  final double heading;
  final bool isStopped;
  final double speedKmh;
  final double size;

  const Sahyan3DVehicleMarker({
    super.key,
    this.vehicleTypeCode = 'sedan',
    required this.heading,
    this.isStopped = false,
    this.speedKmh = 0.0,
    this.size = 58.0,
  });

  @override
  State<Sahyan3DVehicleMarker> createState() => _Sahyan3DVehicleMarkerState();
}

class _Sahyan3DVehicleMarkerState extends State<Sahyan3DVehicleMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    if (widget.isStopped) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant Sahyan3DVehicleMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStopped != oldWidget.isStopped) {
      if (widget.isStopped) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing amber halo when vehicle is stopped or halted
              if (widget.isStopped)
                Container(
                  width: widget.size * (0.85 + _pulseAnimation.value * 0.35),
                  height: widget.size * (0.85 + _pulseAnimation.value * 0.35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF59E0B).withValues(
                      alpha: 0.25 * (1.0 - _pulseAnimation.value * 0.5),
                    ),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(
                        alpha: 0.8 * (1.0 - _pulseAnimation.value * 0.4),
                      ),
                      width: 2.0,
                    ),
                  ),
                ),

              // 3D Isometric vehicle rendered with forward heading rotation
              Transform.rotate(
                angle: widget.heading * math.pi / 180.0,
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(widget.size * 0.82, widget.size * 0.82),
                  painter: _IsometricVehiclePainter(
                    vehicleTypeCode: widget.vehicleTypeCode,
                    isStopped: widget.isStopped,
                    pulseValue: _pulseAnimation.value,
                  ),
                ),
              ),

              // Stop indicator badge overlay
              if (widget.isStopped)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      'STOP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter rendering distinct 3D isometric vehicle models for all 6 categories
class _IsometricVehiclePainter extends CustomPainter {
  final String vehicleTypeCode;
  final bool isStopped;
  final double pulseValue;

  _IsometricVehiclePainter({
    required this.vehicleTypeCode,
    required this.isStopped,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final type = vehicleTypeCode.toLowerCase().trim();

    if (type.contains('motorcycle') || type == 'bike' || type.contains('two_wheeler')) {
      _paintMotorcycle(canvas, size, center, w, h);
    } else if (type.contains('scooter') || type.contains('scooty') || type.contains('activa')) {
      _paintScooter(canvas, size, center, w, h);
    } else if (type.contains('hatchback') || type.contains('compact')) {
      _paintHatchback(canvas, size, center, w, h);
    } else if (type.contains('suv') || type.contains('muv') || type.contains('crossover')) {
      _paintSuv(canvas, size, center, w, h);
    } else if (type.contains('ev') || type.contains('electric')) {
      _paintEv(canvas, size, center, w, h);
    } else {
      // Default: Sedan
      _paintSedan(canvas, size, center, w, h);
    }
  }

  // ── 1. MOTORCYCLE / BIKE ──────────────────────────────────────────────────
  // Sports commuter bike with dual helmet badges (driver + pillion)
  void _paintMotorcycle(Canvas canvas, Size size, Offset center, double w, double h) {
    // Ground Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 2), width: w * 0.28, height: h * 0.88),
      shadowPaint,
    );

    // Forward Headlight Beam
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          (isStopped ? const Color(0xFFF59E0B) : const Color(0xFFFEF08A)).withValues(alpha: 0.50),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.40));
    final beamPath = Path()
      ..moveTo(center.dx - w * 0.08, center.dy - h * 0.34)
      ..lineTo(center.dx - w * 0.28, 0)
      ..lineTo(center.dx + w * 0.28, 0)
      ..lineTo(center.dx + w * 0.08, center.dy - h * 0.34)
      ..close();
    canvas.drawPath(beamPath, beamPath.getBounds().isEmpty ? Paint() : beamPaint);

    // Front & Rear Rubber Tires
    final tirePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.36), width: w * 0.09, height: h * 0.18),
        const Radius.circular(3),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.34), width: w * 0.11, height: h * 0.20),
        const Radius.circular(3),
      ),
      tirePaint,
    );

    // Handlebars with Mirror Stalks
    final barPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - w * 0.22, center.dy - h * 0.22),
      Offset(center.dx + w * 0.22, center.dy - h * 0.22),
      barPaint,
    );
    final mirrorPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawCircle(Offset(center.dx - w * 0.22, center.dy - h * 0.24), w * 0.032, mirrorPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.22, center.dy - h * 0.24), w * 0.032, mirrorPaint);

    // Main Streamlined Frame / Fuel Tank
    final frameColor = isStopped ? const Color(0xFFD97706) : const Color(0xFFEA580C); // Racing Orange
    final framePaint = Paint()..color = frameColor;
    final tankPath = Path()
      ..moveTo(center.dx - w * 0.09, center.dy - h * 0.26)
      ..lineTo(center.dx + w * 0.09, center.dy - h * 0.26)
      ..lineTo(center.dx + w * 0.12, center.dy - h * 0.05)
      ..lineTo(center.dx + w * 0.07, center.dy + h * 0.28)
      ..lineTo(center.dx - w * 0.07, center.dy + h * 0.28)
      ..lineTo(center.dx - w * 0.12, center.dy - h * 0.05)
      ..close();
    canvas.drawPath(tankPath, framePaint);

    // Crisp white border
    final outlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tankPath, outlinePaint);

    // Dual Helmet Badges: Rider Helmet (Front) & Pillion Helmet (Rear)
    // 1. Driver Helmet Badge
    final driverHelmetPaint = Paint()..color = Colors.white;
    final visorPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(center.dx, center.dy - h * 0.08), w * 0.085, driverHelmetPaint);
    canvas.drawCircle(
      Offset(center.dx, center.dy - h * 0.08),
      w * 0.085,
      Paint()
        ..color = const Color(0xFFEA580C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Dark Visor Strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.11), width: w * 0.11, height: h * 0.035),
        const Radius.circular(2),
      ),
      visorPaint,
    );

    // 2. Pillion Passenger Helmet Badge
    final pillionHelmetPaint = Paint()..color = const Color(0xFF10B981); // Emerald safety badge
    canvas.drawCircle(Offset(center.dx, center.dy + h * 0.14), w * 0.075, pillionHelmetPaint);
    canvas.drawCircle(
      Offset(center.dx, center.dy + h * 0.14),
      w * 0.075,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.115), width: w * 0.09, height: h * 0.030),
        const Radius.circular(2),
      ),
      visorPaint,
    );

    // Single bright LED headlight & Red taillight
    canvas.drawCircle(Offset(center.dx, center.dy - h * 0.28), w * 0.045, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx, center.dy + h * 0.28), w * 0.038, Paint()..color = const Color(0xFFEF4444));
  }

  // ── 2. SCOOTER / SCOOTY ───────────────────────────────────────────────────
  // Urban step-through scooter with chrome grab rail and rear seat indicator
  void _paintScooter(Canvas canvas, Size size, Offset center, double w, double h) {
    // Ground Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 2), width: w * 0.42, height: h * 0.82),
      shadowPaint,
    );

    // Headlamp Beam
    _paintHeadlampCone(canvas, center, w, h, w * 0.14, h * 0.24);

    // Front Apron Cowl (Wide front shield)
    final apronColor = isStopped ? const Color(0xFFB45309) : const Color(0xFFD97706); // Warm Amber/Teal
    final apronRect = Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.20), width: w * 0.36, height: h * 0.24);
    final apronRRect = RRect.fromRectAndRadius(apronRect, Radius.circular(w * 0.14));
    canvas.drawRRect(apronRRect, Paint()..color = apronColor);
    canvas.drawRRect(apronRRect, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // Swept Handlebars & Mirrors
    final barPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 2.2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - w * 0.22, center.dy - h * 0.26), Offset(center.dx + w * 0.22, center.dy - h * 0.26), barPaint);
    canvas.drawCircle(Offset(center.dx - w * 0.22, center.dy - h * 0.28), w * 0.035, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(Offset(center.dx + w * 0.22, center.dy - h * 0.28), w * 0.035, Paint()..color = const Color(0xFF94A3B8));

    // Step-through Floorboard
    final floorRect = Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.02), width: w * 0.24, height: h * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(floorRect, Radius.circular(w * 0.04)), Paint()..color = const Color(0xFF334155));

    // Long Scooter Seat Cushion
    final seatRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.14), width: w * 0.30, height: h * 0.30);
    final seatRRect = RRect.fromRectAndRadius(seatRect, Radius.circular(w * 0.08));
    canvas.drawRRect(seatRRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(seatRRect, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Rear Seat Pillion Indicator Stitch & Metallic Grab Rail
    canvas.drawLine(
      Offset(center.dx - w * 0.13, center.dy + h * 0.12),
      Offset(center.dx + w * 0.13, center.dy + h * 0.12),
      Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 1.5,
    );
    // Grab Rail (Chrome U-Bar at the back)
    final grabRailPath = Path()
      ..moveTo(center.dx - w * 0.15, center.dy + h * 0.24)
      ..quadraticBezierTo(center.dx, center.dy + h * 0.35, center.dx + w * 0.15, center.dy + h * 0.24);
    canvas.drawPath(grabRailPath, Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Headlight & Taillight
    canvas.drawCircle(Offset(center.dx, center.dy - h * 0.28), w * 0.05, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.30), width: w * 0.16, height: h * 0.04),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFEF4444),
    );
  }

  // ── 3. HATCHBACK ──────────────────────────────────────────────────────────
  // Compact 4-seater with sporty two-box stance and rear roof spoiler (Swift / i20 style)
  void _paintHatchback(Canvas canvas, Size size, Offset center, double w, double h) {
    _paintStandardGroundShadow(canvas, center, w * 0.52, h * 0.74);
    _paintHeadlampCone(canvas, center, w, h, w * 0.17, h * 0.26);

    final primary = isStopped ? const Color(0xFFB45309) : const Color(0xFF0284C7); // Sporty Sky Blue
    final roof = const Color(0xFF0369A1);

    // 2-Box Lower Body Chassis (Slightly shorter rear deck)
    final bodyRect = Rect.fromCenter(center: center, width: w * 0.52, height: h * 0.72);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.16));
    canvas.drawRRect(bodyRRect, Paint()..color = primary);
    _paintBodyBorder(canvas, bodyRRect);

    // Windshield Glass
    _paintCurvedWindshield(canvas, center, w * 0.38, h * 0.14, -h * 0.14);

    // Compact Cabin Roof
    final roofRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.02), width: w * 0.36, height: h * 0.24);
    canvas.drawRRect(RRect.fromRectAndRadius(roofRect, Radius.circular(w * 0.06)), Paint()..color = roof);

    // Steep Hatchback Rear Glass
    final rearGlassRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.18), width: w * 0.34, height: h * 0.08);
    _paintGlass(canvas, rearGlassRect);

    // Integrated Rear Roof Spoiler Bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.23), width: w * 0.36, height: h * 0.035),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF0F172A),
    );

    _paintHeadlights(canvas, center, w, h, w * 0.16, h * 0.31);
    _paintTaillights(canvas, center, w, h, w * 0.17, h * 0.31);
  }

  // ── 4. SEDAN ──────────────────────────────────────────────────────────────
  // Luxury 5-seater with elegant three-box silhouette, long hood and trunk
  void _paintSedan(Canvas canvas, Size size, Offset center, double w, double h) {
    _paintStandardGroundShadow(canvas, center, w * 0.52, h * 0.84);
    _paintHeadlampCone(canvas, center, w, h, w * 0.16, h * 0.28);

    final primary = isStopped ? const Color(0xFFB45309) : AppColors.deepEmerald; // Classic Emerald
    final roof = const Color(0xFF0F2E24);

    // 3-Box Lower Body Chassis (Long hood + extended trunk)
    final bodyRect = Rect.fromCenter(center: center, width: w * 0.50, height: h * 0.80);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.17));
    canvas.drawRRect(bodyRRect, Paint()..color = primary);
    _paintBodyBorder(canvas, bodyRRect);

    // Front Windshield
    _paintCurvedWindshield(canvas, center, w * 0.36, h * 0.14, -h * 0.16);

    // Elevated Roof Deck with Sunroof Glass
    final roofRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.02), width: w * 0.34, height: h * 0.26);
    canvas.drawRRect(RRect.fromRectAndRadius(roofRect, Radius.circular(w * 0.07)), Paint()..color = roof);
    // Tinted Sunroof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - h * 0.02), width: w * 0.20, height: h * 0.10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.7),
    );

    // Rear Windshield Glass
    final rearGlassRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.21), width: w * 0.32, height: h * 0.10);
    _paintGlass(canvas, rearGlassRect);

    // Extended Trunk / Boot Deck with Chrome Lid Accent
    canvas.drawLine(
      Offset(center.dx - w * 0.15, center.dy + h * 0.32),
      Offset(center.dx + w * 0.15, center.dy + h * 0.32),
      Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1.6,
    );

    _paintHeadlights(canvas, center, w, h, w * 0.16, h * 0.34);
    _paintTaillights(canvas, center, w, h, w * 0.16, h * 0.35);
  }

  // ── 5. SUV / MUV ──────────────────────────────────────────────────────────
  // Rugged 7-seater with flared wheel arches and metallic roof luggage rails
  void _paintSuv(Canvas canvas, Size size, Offset center, double w, double h) {
    _paintStandardGroundShadow(canvas, center, w * 0.60, h * 0.86);
    _paintHeadlampCone(canvas, center, w, h, w * 0.20, h * 0.30);

    final primary = isStopped ? const Color(0xFFB45309) : const Color(0xFF1E293B); // Rugged Midnight Slate
    final secondary = const Color(0xFF334155);

    // 4 Flared Muscular Wheel Arches (Corner Cladding)
    final claddingPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - w * 0.31, center.dy - h * 0.32, w * 0.09, h * 0.18), const Radius.circular(4)), claddingPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx + w * 0.22, center.dy - h * 0.32, w * 0.09, h * 0.18), const Radius.circular(4)), claddingPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - w * 0.31, center.dy + h * 0.14, w * 0.09, h * 0.18), const Radius.circular(4)), claddingPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx + w * 0.22, center.dy + h * 0.14, w * 0.09, h * 0.18), const Radius.circular(4)), claddingPaint);

    // Wide Muscular Lower Body Chassis
    final bodyRect = Rect.fromCenter(center: center, width: w * 0.56, height: h * 0.80);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.15));
    canvas.drawRRect(bodyRRect, Paint()..color = primary);
    _paintBodyBorder(canvas, bodyRRect);

    // Upright Wide Windshield
    _paintCurvedWindshield(canvas, center, w * 0.42, h * 0.15, -h * 0.16);

    // Tall Roof Deck
    final roofRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.03), width: w * 0.40, height: h * 0.30);
    canvas.drawRRect(RRect.fromRectAndRadius(roofRect, Radius.circular(w * 0.06)), Paint()..color = secondary);

    // Metallic Roof Luggage Rails (Longitudinal silver bars)
    final railPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 2.4..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - w * 0.19, center.dy - h * 0.10), Offset(center.dx - w * 0.19, center.dy + h * 0.18), railPaint);
    canvas.drawLine(Offset(center.dx + w * 0.19, center.dy - h * 0.10), Offset(center.dx + w * 0.19, center.dy + h * 0.18), railPaint);

    // Wide Rear Windshield
    final rearGlassRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.23), width: w * 0.36, height: h * 0.09);
    _paintGlass(canvas, rearGlassRect);

    // Imposing squared front grille & twin projectors
    _paintHeadlights(canvas, center, w, h, w * 0.19, h * 0.34);
    _paintTaillights(canvas, center, w, h, w * 0.20, h * 0.35);
  }

  // ── 6. EV / ELECTRIC ──────────────────────────────────────────────────────
  // Modern electric vehicle with luminous cyan battery glow & aerodynamic canopy
  void _paintEv(Canvas canvas, Size size, Offset center, double w, double h) {
    // Glowing Luminous Cyan Underbody Aura
    final cyanGlowPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.50 + pulseValue * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w * 0.62, height: h * 0.86),
        Radius.circular(w * 0.24),
      ),
      cyanGlowPaint,
    );

    // Standard directional shadow
    _paintStandardGroundShadow(canvas, center, w * 0.54, h * 0.80);

    // Forward Cyan Headlight Beam
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          (isStopped ? const Color(0xFFF59E0B) : const Color(0xFF22D3EE)).withValues(alpha: 0.55),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));
    final beamPath = Path()
      ..moveTo(center.dx - w * 0.18, center.dy - h * 0.28)
      ..lineTo(center.dx - w * 0.40, 0)
      ..lineTo(center.dx + w * 0.40, 0)
      ..lineTo(center.dx + w * 0.18, center.dy - h * 0.28)
      ..close();
    canvas.drawPath(beamPath, beamPaint);

    final primary = isStopped ? const Color(0xFFB45309) : const Color(0xFF047857); // Deep Emerald EV

    // Aerodynamic Teardrop Lower Body Chassis
    final bodyRect = Rect.fromCenter(center: center, width: w * 0.52, height: h * 0.78);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.20));
    canvas.drawRRect(bodyRRect, Paint()..color = primary);

    // Cyan High-Tech Border Outline
    final borderPaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bodyRRect, borderPaint);

    // Continuous Glass Canopy (Panoramic solar glass extending from front to rear)
    final glassShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0891B2).withValues(alpha: 0.90),
        const Color(0xFF164E63).withValues(alpha: 0.85),
      ],
    ).createShader(Rect.fromLTWH(center.dx - w * 0.20, center.dy - h * 0.26, w * 0.40, h * 0.52));

    final canopyRect = Rect.fromCenter(center: center, width: w * 0.36, height: h * 0.52);
    canvas.drawRRect(RRect.fromRectAndRadius(canopyRect, Radius.circular(w * 0.12)), Paint()..shader = glassShader);
    canvas.drawRRect(
      RRect.fromRectAndRadius(canopyRect, Radius.circular(w * 0.12)),
      Paint()..color = const Color(0xFF67E8F9)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );

    // Subtle Electric Bolt / Lightning Emblem on Roof
    final boltPath = Path()
      ..moveTo(center.dx + w * 0.02, center.dy - h * 0.04)
      ..lineTo(center.dx - w * 0.04, center.dy + h * 0.01)
      ..lineTo(center.dx - w * 0.01, center.dy + h * 0.01)
      ..lineTo(center.dx - w * 0.02, center.dy + h * 0.05)
      ..lineTo(center.dx + w * 0.04, center.dy)
      ..lineTo(center.dx + w * 0.01, center.dy)
      ..close();
    canvas.drawPath(boltPath, Paint()..color = const Color(0xFF22D3EE));

    // Full-Width Continuous Front LED Light Bar
    final ledBarPaint = Paint()..color = isStopped ? const Color(0xFFF59E0B) : const Color(0xFFE0F2FE)..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - w * 0.18, center.dy - h * 0.33), Offset(center.dx + w * 0.18, center.dy - h * 0.33), ledBarPaint);

    // Full-Width Rear LED Light Strip
    final rearBarPaint = Paint()..color = const Color(0xFFEF4444)..strokeWidth = 2.8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - w * 0.18, center.dy + h * 0.33), Offset(center.dx + w * 0.18, center.dy + h * 0.33), rearBarPaint);
  }

  // ── REUSABLE DRAWING PRIMITIVES ──────────────────────────────────────────

  void _paintStandardGroundShadow(Canvas canvas, Offset center, double width, double height) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 3.0), width: width, height: height),
        Radius.circular(width * 0.35),
      ),
      shadowPaint,
    );
  }

  void _paintHeadlampCone(Canvas canvas, Offset center, double w, double h, double startHalfWidth, double coneTop) {
    final lightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          (isStopped ? const Color(0xFFF59E0B) : const Color(0xFFFEF08A)).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));

    final beamPath = Path()
      ..moveTo(center.dx - startHalfWidth, center.dy - coneTop)
      ..lineTo(center.dx - w * 0.38, 0)
      ..lineTo(center.dx + w * 0.38, 0)
      ..lineTo(center.dx + startHalfWidth, center.dy - coneTop)
      ..close();
    canvas.drawPath(beamPath, lightPaint);
  }

  void _paintBodyBorder(Canvas canvas, RRect bodyRRect) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bodyRRect, borderPaint);
  }

  void _paintCurvedWindshield(Canvas canvas, Offset center, double width, double height, double dyOffset) {
    final rect = Rect.fromCenter(center: Offset(center.dx, center.dy + dyOffset), width: width, height: height);
    _paintGlass(canvas, rect);
  }

  void _paintGlass(Canvas canvas, Rect rect) {
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF93C5FD).withValues(alpha: 0.92),
          const Color(0xFF1E3A8A).withValues(alpha: 0.82),
        ],
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), glassPaint);
  }

  void _paintHeadlights(Canvas canvas, Offset center, double w, double h, double xOffset, double yOffset) {
    final lampPaint = Paint()..color = isStopped ? const Color(0xFFF59E0B) : Colors.white;
    canvas.drawCircle(Offset(center.dx - xOffset, center.dy - yOffset), w * 0.038, lampPaint);
    canvas.drawCircle(Offset(center.dx + xOffset, center.dy - yOffset), w * 0.038, lampPaint);
  }

  void _paintTaillights(Canvas canvas, Offset center, double w, double h, double xOffset, double yOffset) {
    final tailPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(Offset(center.dx - xOffset, center.dy + yOffset), w * 0.034, tailPaint);
    canvas.drawCircle(Offset(center.dx + xOffset, center.dy + yOffset), w * 0.034, tailPaint);
  }

  @override
  bool shouldRepaint(covariant _IsometricVehiclePainter oldDelegate) {
    return oldDelegate.vehicleTypeCode != vehicleTypeCode ||
        oldDelegate.isStopped != isStopped ||
        oldDelegate.pulseValue != pulseValue;
  }
}
