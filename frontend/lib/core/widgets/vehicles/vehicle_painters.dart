import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../features/vehicles/domain/vehicle_type.dart';

/// Renders a crisp, stylish side/profile illustration of a vehicle.
/// Used in UI cards, detail sheets, and vehicle selectors.
class VehicleIllustrationPainter extends CustomPainter {
  final VehicleType type;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final bool isSelected;

  const VehicleIllustrationPainter({
    required this.type,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryLight,
    this.accentColor = AppColors.accent,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background soft glow if selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(16),
        ),
        glowPaint,
      );
    }

    final bodyPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final wheelPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;

    final hubcapPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    switch (type.categoryGroup) {
      case VehicleCategoryGroup.twoWheeler:
        _paintTwoWheeler(canvas, w, h, bodyPaint, wheelPaint, hubcapPaint, accentPaint);
        break;
      case VehicleCategoryGroup.threeWheeler:
        _paintThreeWheeler(canvas, w, h, bodyPaint, windowPaint, wheelPaint, hubcapPaint, accentPaint);
        break;
      case VehicleCategoryGroup.utility:
        _paintUtilityVehicle(canvas, w, h, bodyPaint, windowPaint, wheelPaint, hubcapPaint, accentPaint);
        break;
      case VehicleCategoryGroup.car:
        _paintCar(canvas, w, h, bodyPaint, windowPaint, wheelPaint, hubcapPaint, accentPaint);
        break;
    }

    // EV badge
    if (type.isElectric) {
      _paintEvBadge(canvas, w, h);
    }
  }

  void _paintCar(
    Canvas canvas,
    double w,
    double h,
    Paint body,
    Paint window,
    Paint wheel,
    Paint hubcap,
    Paint accent,
  ) {
    final bodyPath = Path();
    final windowPath = Path();

    final groundY = h * 0.78;
    final wheelRadius = h * 0.16;
    final frontWheelX = w * 0.76;
    final rearWheelX = w * 0.24;

    switch (type) {
      case VehicleType.hatchback:
        // Compact 2-box hatchback profile
        bodyPath.moveTo(w * 0.08, groundY - 4);
        bodyPath.lineTo(w * 0.08, h * 0.42); // blunt rear
        bodyPath.quadraticBezierTo(w * 0.12, h * 0.32, w * 0.25, h * 0.30); // roof start
        bodyPath.lineTo(w * 0.58, h * 0.30); // flat roof
        bodyPath.quadraticBezierTo(w * 0.72, h * 0.34, w * 0.88, h * 0.52); // steep windshield & bonnet
        bodyPath.quadraticBezierTo(w * 0.94, h * 0.58, w * 0.92, groundY - 4); // nose
        bodyPath.close();

        // Windows
        windowPath.moveTo(w * 0.26, h * 0.34);
        windowPath.lineTo(w * 0.54, h * 0.34);
        windowPath.lineTo(w * 0.70, h * 0.50);
        windowPath.lineTo(w * 0.24, h * 0.50);
        windowPath.close();
        break;

      case VehicleType.suv:
        // Rugged, tall, upright roof with roof rail
        bodyPath.moveTo(w * 0.06, groundY - 6);
        bodyPath.lineTo(w * 0.06, h * 0.32); // high vertical rear
        bodyPath.quadraticBezierTo(w * 0.10, h * 0.24, w * 0.20, h * 0.22);
        bodyPath.lineTo(w * 0.65, h * 0.22); // tall high roof
        bodyPath.lineTo(w * 0.82, h * 0.46); // windshield
        bodyPath.lineTo(w * 0.95, h * 0.50); // muscular high hood
        bodyPath.quadraticBezierTo(w * 0.96, h * 0.58, w * 0.94, groundY - 6);
        bodyPath.close();

        // Roof rails
        final railPaint = Paint()
          ..color = const Color(0xFF374151)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(w * 0.22, h * 0.18), Offset(w * 0.62, h * 0.18), railPaint);

        // Windows
        windowPath.moveTo(w * 0.20, h * 0.26);
        windowPath.lineTo(w * 0.62, h * 0.26);
        windowPath.lineTo(w * 0.77, h * 0.45);
        windowPath.lineTo(w * 0.18, h * 0.45);
        windowPath.close();
        break;

      case VehicleType.muv:
        // Long 3-row family vehicle
        bodyPath.moveTo(w * 0.05, groundY - 5);
        bodyPath.lineTo(w * 0.05, h * 0.32);
        bodyPath.lineTo(w * 0.68, h * 0.26);
        bodyPath.lineTo(w * 0.86, h * 0.50);
        bodyPath.lineTo(w * 0.96, h * 0.54);
        bodyPath.lineTo(w * 0.95, groundY - 5);
        bodyPath.close();

        windowPath.moveTo(w * 0.16, h * 0.30);
        windowPath.lineTo(w * 0.66, h * 0.29);
        windowPath.lineTo(w * 0.80, h * 0.48);
        windowPath.lineTo(w * 0.14, h * 0.48);
        windowPath.close();
        break;

      case VehicleType.luxurySedan:
        // Sleek elongated luxury profile
        bodyPath.moveTo(w * 0.04, groundY - 4);
        bodyPath.lineTo(w * 0.12, h * 0.50); // low rear trunk
        bodyPath.quadraticBezierTo(w * 0.24, h * 0.30, w * 0.44, h * 0.28);
        bodyPath.lineTo(w * 0.62, h * 0.28);
        bodyPath.quadraticBezierTo(w * 0.78, h * 0.34, w * 0.88, h * 0.52);
        bodyPath.lineTo(w * 0.97, h * 0.56); // long hood
        bodyPath.quadraticBezierTo(w * 0.98, h * 0.62, w * 0.95, groundY - 4);
        bodyPath.close();

        windowPath.moveTo(w * 0.26, h * 0.32);
        windowPath.lineTo(w * 0.60, h * 0.32);
        windowPath.lineTo(w * 0.76, h * 0.48);
        windowPath.lineTo(w * 0.20, h * 0.48);
        windowPath.close();
        break;

      case VehicleType.crossover:
        // Sporty, slightly raised crossover
        bodyPath.moveTo(w * 0.06, groundY - 6);
        bodyPath.lineTo(w * 0.08, h * 0.38);
        bodyPath.quadraticBezierTo(w * 0.20, h * 0.26, w * 0.56, h * 0.26);
        bodyPath.lineTo(w * 0.78, h * 0.48);
        bodyPath.lineTo(w * 0.94, h * 0.52);
        bodyPath.quadraticBezierTo(w * 0.96, h * 0.60, w * 0.93, groundY - 6);
        bodyPath.close();

        windowPath.moveTo(w * 0.22, h * 0.30);
        windowPath.lineTo(w * 0.54, h * 0.30);
        windowPath.lineTo(w * 0.72, h * 0.47);
        windowPath.lineTo(w * 0.18, h * 0.47);
        windowPath.close();
        break;

      case VehicleType.electricCar:
        // Aerodynamic aerodynamic EV shape
        bodyPath.moveTo(w * 0.05, groundY - 4);
        bodyPath.lineTo(w * 0.12, h * 0.46);
        bodyPath.quadraticBezierTo(w * 0.30, h * 0.26, w * 0.58, h * 0.26);
        bodyPath.quadraticBezierTo(w * 0.76, h * 0.32, w * 0.90, h * 0.54);
        bodyPath.lineTo(w * 0.95, h * 0.58);
        bodyPath.quadraticBezierTo(w * 0.96, h * 0.64, w * 0.93, groundY - 4);
        bodyPath.close();

        windowPath.moveTo(w * 0.24, h * 0.29);
        windowPath.lineTo(w * 0.56, h * 0.29);
        windowPath.lineTo(w * 0.76, h * 0.48);
        windowPath.lineTo(w * 0.18, h * 0.48);
        windowPath.close();
        break;

      case VehicleType.sedan:
      default:
        // Classic 3-box notchback sedan
        bodyPath.moveTo(w * 0.06, groundY - 4);
        bodyPath.lineTo(w * 0.14, h * 0.48); // trunk
        bodyPath.quadraticBezierTo(w * 0.22, h * 0.34, w * 0.40, h * 0.32); // rear windshield
        bodyPath.lineTo(w * 0.62, h * 0.32); // roof
        bodyPath.quadraticBezierTo(w * 0.74, h * 0.36, w * 0.84, h * 0.52); // front windshield
        bodyPath.lineTo(w * 0.95, h * 0.54); // hood
        bodyPath.quadraticBezierTo(w * 0.96, h * 0.62, w * 0.93, groundY - 4);
        bodyPath.close();

        windowPath.moveTo(w * 0.24, h * 0.36);
        windowPath.lineTo(w * 0.60, h * 0.36);
        windowPath.lineTo(w * 0.74, h * 0.50);
        windowPath.lineTo(w * 0.20, h * 0.50);
        windowPath.close();
        break;
    }

    // Draw chassis body
    canvas.drawPath(bodyPath, body);

    // Draw windows
    canvas.drawPath(windowPath, window);

    // Window frame divider
    final framePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.46, h * 0.32),
      Offset(w * 0.46, h * 0.50),
      framePaint,
    );

    // Headlight & Taillight
    final headlight = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.90, h * 0.54, w * 0.04, h * 0.08),
        const Radius.circular(3),
      ),
      headlight,
    );

    final taillight = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.48, w * 0.03, h * 0.08),
        const Radius.circular(2),
      ),
      taillight,
    );

    // Wheels
    _drawWheel(canvas, Offset(rearWheelX, groundY), wheelRadius, wheel, hubcap);
    _drawWheel(canvas, Offset(frontWheelX, groundY), wheelRadius, wheel, hubcap);
  }

  void _paintTwoWheeler(
    Canvas canvas,
    double w,
    double h,
    Paint body,
    Paint wheel,
    Paint hubcap,
    Paint accent,
  ) {
    final groundY = h * 0.78;
    final wheelRadius = h * 0.18;
    final frontWheelX = w * 0.76;
    final rearWheelX = w * 0.24;

    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final isBicycle = type == VehicleType.bicycle || type == VehicleType.electricBicycle;
    final isScooter = type == VehicleType.scooter || type == VehicleType.electricScooter;

    if (isBicycle) {
      // Bicycle Diamond Frame
      final frame = Path();
      final bb = Offset(w * 0.46, groundY - 4); // bottom bracket
      final seat = Offset(w * 0.40, h * 0.36); // seat post top
      final handle = Offset(w * 0.66, h * 0.28); // headset top

      frame.moveTo(rearWheelX, groundY);
      frame.lineTo(bb.dx, bb.dy);
      frame.lineTo(seat.dx, seat.dy);
      frame.lineTo(rearWheelX, groundY); // rear triangle
      frame.moveTo(bb.dx, bb.dy);
      frame.lineTo(handle.dx, handle.dy);
      frame.lineTo(frontWheelX, groundY); // front fork
      frame.moveTo(seat.dx, seat.dy);
      frame.lineTo(handle.dx, handle.dy); // top tube

      canvas.drawPath(frame, strokePaint..strokeWidth = 3.5);

      // Handlebar
      canvas.drawLine(
        Offset(handle.dx - 8, handle.dy - 6),
        Offset(handle.dx + 8, handle.dy - 6),
        strokePaint..strokeWidth = 4,
      );

      // Saddle
      final saddlePaint = Paint()..color = const Color(0xFF1F2937);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(seat.dx, seat.dy - 6), width: 22, height: 7),
          const Radius.circular(3),
        ),
        saddlePaint,
      );

      // Battery pack for e-bicycle
      if (type == VehicleType.electricBicycle) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.46, h * 0.46, 16, 8),
            const Radius.circular(2),
          ),
          accent,
        );
      }
    } else if (isScooter) {
      // Step-through scooter body
      final scooterPath = Path();
      scooterPath.moveTo(rearWheelX - 8, groundY - 6);
      scooterPath.quadraticBezierTo(w * 0.16, h * 0.40, w * 0.36, h * 0.40); // rear cowl
      scooterPath.lineTo(w * 0.50, groundY - 8); // floorboard
      scooterPath.lineTo(w * 0.68, groundY - 8);
      scooterPath.lineTo(w * 0.72, h * 0.30); // front apron
      scooterPath.lineTo(frontWheelX + 6, groundY - 4);
      scooterPath.close();

      canvas.drawPath(scooterPath, body);

      // Seat
      final seatPaint = Paint()..color = const Color(0xFF111827);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.35, w * 0.26, h * 0.09),
          const Radius.circular(4),
        ),
        seatPaint,
      );

      // Handlebar
      canvas.drawLine(
        Offset(w * 0.68, h * 0.26),
        Offset(w * 0.74, h * 0.24),
        strokePaint..strokeWidth = 4,
      );
    } else {
      // Motorcycle (Tank, seat, engine block, fork)
      final tankPath = Path();
      tankPath.moveTo(w * 0.38, h * 0.42);
      tankPath.quadraticBezierTo(w * 0.52, h * 0.32, w * 0.62, h * 0.36);
      tankPath.lineTo(w * 0.60, h * 0.52);
      tankPath.lineTo(w * 0.42, h * 0.52);
      tankPath.close();
      canvas.drawPath(tankPath, body);

      // Engine block
      final enginePaint = Paint()..color = const Color(0xFF4B5563);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.40, h * 0.52, w * 0.20, h * 0.20),
          const Radius.circular(4),
        ),
        enginePaint,
      );

      // Seat
      final seatPaint = Paint()..color = const Color(0xFF1F2937);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.20, h * 0.40, w * 0.22, h * 0.08),
          const Radius.circular(4),
        ),
        seatPaint,
      );

      // Front fork
      canvas.drawLine(
        Offset(w * 0.64, h * 0.30),
        Offset(frontWheelX, groundY),
        strokePaint..strokeWidth = 4,
      );

      // Handlebar & Headlight
      canvas.drawCircle(Offset(w * 0.70, h * 0.38), 5, Paint()..color = const Color(0xFFFBBF24));
    }

    // Spokes/wheels for two-wheelers
    _drawWheel(canvas, Offset(rearWheelX, groundY), wheelRadius, wheel, hubcap);
    _drawWheel(canvas, Offset(frontWheelX, groundY), wheelRadius, wheel, hubcap);
  }

  void _paintThreeWheeler(
    Canvas canvas,
    double w,
    double h,
    Paint body,
    Paint window,
    Paint wheel,
    Paint hubcap,
    Paint accent,
  ) {
    final groundY = h * 0.78;
    final wheelRadius = h * 0.16;
    final frontWheelX = w * 0.78;
    final rearWheelX = w * 0.24;

    // Classic Indian Auto Rickshaw Silhouette
    final cabPath = Path();
    cabPath.moveTo(w * 0.12, groundY - 6);
    cabPath.lineTo(w * 0.12, h * 0.34);
    cabPath.quadraticBezierTo(w * 0.16, h * 0.24, w * 0.32, h * 0.22); // yellow/green hood roof
    cabPath.lineTo(w * 0.64, h * 0.22);
    cabPath.quadraticBezierTo(w * 0.74, h * 0.28, w * 0.82, h * 0.50); // windshield slope
    cabPath.lineTo(frontWheelX + 6, groundY - 6);
    cabPath.close();

    // Body paint (Sahyān Forest or Electric Green)
    final isEv = type == VehicleType.electricAutoRickshaw;
    final roofPaint = Paint()..color = isEv ? const Color(0xFF0F766E) : const Color(0xFFD97706);
    canvas.drawPath(cabPath, roofPaint);

    // Lower chassis
    final lowerChassis = Rect.fromLTWH(w * 0.12, h * 0.52, w * 0.62, h * 0.22);
    canvas.drawRect(lowerChassis, body);

    // Open passenger window
    final windowRect = Rect.fromLTWH(w * 0.26, h * 0.28, w * 0.24, h * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );

    // Front windshield
    final frontGlass = Path();
    frontGlass.moveTo(w * 0.54, h * 0.26);
    frontGlass.lineTo(w * 0.64, h * 0.26);
    frontGlass.lineTo(w * 0.76, h * 0.48);
    frontGlass.lineTo(w * 0.54, h * 0.48);
    frontGlass.close();
    canvas.drawPath(frontGlass, window);

    // Wheels
    _drawWheel(canvas, Offset(rearWheelX, groundY), wheelRadius, wheel, hubcap);
    _drawWheel(canvas, Offset(frontWheelX, groundY), wheelRadius, wheel, hubcap);
  }

  void _paintUtilityVehicle(
    Canvas canvas,
    double w,
    double h,
    Paint body,
    Paint window,
    Paint wheel,
    Paint hubcap,
    Paint accent,
  ) {
    final groundY = h * 0.78;
    final wheelRadius = h * 0.16;
    final frontWheelX = w * 0.76;
    final rearWheelX = w * 0.24;

    final bodyPath = Path();
    final windowPath = Path();

    switch (type) {
      case VehicleType.pickupTruck:
        // Cab + open payload bed
        bodyPath.moveTo(w * 0.05, groundY - 6);
        bodyPath.lineTo(w * 0.05, h * 0.50); // rear tailgate
        bodyPath.lineTo(w * 0.45, h * 0.50); // cargo bed line
        bodyPath.lineTo(w * 0.45, h * 0.26); // cab rear
        bodyPath.lineTo(w * 0.70, h * 0.26); // cab roof
        bodyPath.lineTo(w * 0.84, h * 0.48); // windshield
        bodyPath.lineTo(w * 0.96, h * 0.52); // front hood
        bodyPath.quadraticBezierTo(w * 0.96, h * 0.62, w * 0.94, groundY - 6);
        bodyPath.close();

        windowPath.moveTo(w * 0.48, h * 0.30);
        windowPath.lineTo(w * 0.68, h * 0.30);
        windowPath.lineTo(w * 0.78, h * 0.46);
        windowPath.lineTo(w * 0.48, h * 0.46);
        windowPath.close();
        break;

      case VehicleType.tempo:
        // Small Commercial Vehicle (Cab forward + utility box)
        bodyPath.moveTo(w * 0.06, groundY - 6);
        bodyPath.lineTo(w * 0.06, h * 0.36);
        bodyPath.lineTo(w * 0.60, h * 0.36); // utility cage
        bodyPath.lineTo(w * 0.60, h * 0.26); // cab roof
        bodyPath.lineTo(w * 0.86, h * 0.26);
        bodyPath.lineTo(w * 0.94, h * 0.54);
        bodyPath.lineTo(w * 0.94, groundY - 6);
        bodyPath.close();

        windowPath.moveTo(w * 0.64, h * 0.30);
        windowPath.lineTo(w * 0.84, h * 0.30);
        windowPath.lineTo(w * 0.90, h * 0.48);
        windowPath.lineTo(w * 0.64, h * 0.48);
        windowPath.close();
        break;

      case VehicleType.miniBus:
        // Large tall multi-window commuter bus
        bodyPath.moveTo(w * 0.04, groundY - 6);
        bodyPath.lineTo(w * 0.04, h * 0.22);
        bodyPath.lineTo(w * 0.92, h * 0.22);
        bodyPath.quadraticBezierTo(w * 0.96, h * 0.26, w * 0.96, h * 0.56);
        bodyPath.lineTo(w * 0.95, groundY - 6);
        bodyPath.close();

        // 3 Windows
        for (int i = 0; i < 3; i++) {
          final winRect = Rect.fromLTWH(w * (0.16 + (i * 0.24)), h * 0.28, w * 0.18, h * 0.22);
          windowPath.addRRect(RRect.fromRectAndRadius(winRect, const Radius.circular(2)));
        }
        break;

      case VehicleType.miniVan:
      case VehicleType.van:
      default:
        // Passenger Van
        bodyPath.moveTo(w * 0.05, groundY - 6);
        bodyPath.lineTo(w * 0.05, h * 0.24);
        bodyPath.lineTo(w * 0.72, h * 0.24);
        bodyPath.lineTo(w * 0.90, h * 0.52);
        bodyPath.lineTo(w * 0.95, h * 0.56);
        bodyPath.lineTo(w * 0.94, groundY - 6);
        bodyPath.close();

        // Dual windows
        windowPath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.24, h * 0.20), const Radius.circular(2)));
        windowPath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.48, h * 0.30, w * 0.28, h * 0.20), const Radius.circular(2)));
        break;
    }

    canvas.drawPath(bodyPath, body);
    canvas.drawPath(windowPath, window);

    _drawWheel(canvas, Offset(rearWheelX, groundY), wheelRadius, wheel, hubcap);
    _drawWheel(canvas, Offset(frontWheelX, groundY), wheelRadius, wheel, hubcap);
  }

  void _drawWheel(Canvas canvas, Offset center, double radius, Paint tire, Paint rim) {
    canvas.drawCircle(center, radius, tire);
    canvas.drawCircle(center, radius * 0.55, rim);
    canvas.drawCircle(center, radius * 0.22, tire);
  }

  void _paintEvBadge(Canvas canvas, double w, double h) {
    final badgePaint = Paint()..color = const Color(0xFF10B981);
    final badgeRect = Rect.fromLTWH(w * 0.78, h * 0.08, 16, 16);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)), badgePaint);

    final bolt = Path();
    bolt.moveTo(w * 0.78 + 9, h * 0.08 + 3);
    bolt.lineTo(w * 0.78 + 6, h * 0.08 + 8);
    bolt.lineTo(w * 0.78 + 8, h * 0.08 + 8);
    bolt.lineTo(w * 0.78 + 7, h * 0.08 + 13);
    bolt.lineTo(w * 0.78 + 11, h * 0.08 + 7);
    bolt.lineTo(w * 0.78 + 9, h * 0.08 + 7);
    bolt.close();
    canvas.drawPath(bolt, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant VehicleIllustrationPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isSelected != isSelected;
  }
}

/// Renders a top-down / angled directional marker optimized for Google Maps.
/// Distinct silhouette, high-contrast white border, directional pointer, and active ring.
class VehicleMarkerPainter extends CustomPainter {
  final VehicleType type;
  final Color primaryColor;
  final bool isActive;
  final double heading; // 0..360 degrees

  const VehicleMarkerPainter({
    required this.type,
    this.primaryColor = AppColors.primary,
    this.isActive = true,
    this.heading = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Save and rotate canvas by heading around center
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((heading * math.pi) / 180.0);
    canvas.translate(-center.dx, -center.dy);

    // Active status subtle radar ring
    if (isActive) {
      final pulsePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, w * 0.48, pulsePaint);

      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, w * 0.44, ringPaint);
    }

    // High contrast container so vehicle silhouette pops on roads and terrain
    final containerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Marker shadow
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w * 0.62, height: h * 0.78),
        Radius.circular(w * 0.20),
      ));
    canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.35), 4, true);
    canvas.drawPath(shadowPath, containerPaint);

    // Border around white pill
    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(shadowPath, borderPaint);

    // Top-down silhouette
    final carPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final glassPaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;

    switch (type.categoryGroup) {
      case VehicleCategoryGroup.twoWheeler:
        _drawTopDownTwoWheeler(canvas, center, w, h, carPaint);
        break;
      case VehicleCategoryGroup.threeWheeler:
        _drawTopDownThreeWheeler(canvas, center, w, h, carPaint, glassPaint);
        break;
      case VehicleCategoryGroup.utility:
        _drawTopDownUtility(canvas, center, w, h, carPaint, glassPaint);
        break;
      case VehicleCategoryGroup.car:
        _drawTopDownCar(canvas, center, w, h, carPaint, glassPaint);
        break;
    }

    // Forward Direction Triangle Pointer
    final dirPaint = Paint()..color = primaryColor;
    final dirPath = Path();
    dirPath.moveTo(center.dx, center.dy - (h * 0.37));
    dirPath.lineTo(center.dx - 4, center.dy - (h * 0.31));
    dirPath.lineTo(center.dx + 4, center.dy - (h * 0.31));
    dirPath.close();
    canvas.drawPath(dirPath, dirPaint);

    canvas.restore();
  }

  void _drawTopDownCar(Canvas canvas, Offset c, double w, double h, Paint paint, Paint glass) {
    final cw = w * 0.36;
    final ch = h * 0.60;
    final carRect = Rect.fromCenter(center: c, width: cw, height: ch);

    // Body
    canvas.drawRRect(RRect.fromRectAndRadius(carRect, Radius.circular(cw * 0.35)), paint);

    // Front windshield
    final frontGlass = Rect.fromCenter(center: Offset(c.dx, c.dy - (ch * 0.20)), width: cw * 0.70, height: ch * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(frontGlass, const Radius.circular(2)), glass);

    // Rear windshield
    final rearGlass = Rect.fromCenter(center: Offset(c.dx, c.dy + (ch * 0.22)), width: cw * 0.65, height: ch * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(rearGlass, const Radius.circular(2)), glass);
  }

  void _drawTopDownTwoWheeler(Canvas canvas, Offset c, double w, double h, Paint paint) {
    // Slim silhouette with front handlebar and wheels
    final tirePaint = Paint()..color = const Color(0xFF1F2937);
    // Front wheel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy - (h * 0.22)), width: 5, height: 14),
        const Radius.circular(2),
      ),
      tirePaint,
    );
    // Rear wheel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + (h * 0.22)), width: 5, height: 14),
        const Radius.circular(2),
      ),
      tirePaint,
    );

    // Body spine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 9, height: h * 0.34),
        const Radius.circular(4),
      ),
      paint,
    );

    // Handlebar
    final handlePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - 12, c.dy - (h * 0.14)),
      Offset(c.dx + 12, c.dy - (h * 0.14)),
      handlePaint,
    );
  }

  void _drawTopDownThreeWheeler(Canvas canvas, Offset c, double w, double h, Paint paint, Paint glass) {
    // Delta shape: single front, wide dual rear
    final autoPath = Path();
    autoPath.moveTo(c.dx, c.dy - (h * 0.26)); // narrow front
    autoPath.lineTo(c.dx + (w * 0.19), c.dy + (h * 0.22)); // wide rear right
    autoPath.quadraticBezierTo(c.dx, c.dy + (h * 0.26), c.dx - (w * 0.19), c.dy + (h * 0.22)); // rear curved
    autoPath.close();

    canvas.drawPath(autoPath, paint);

    // Front windshield
    final frontGlass = Rect.fromCenter(center: Offset(c.dx, c.dy - (h * 0.10)), width: w * 0.24, height: h * 0.10);
    canvas.drawRRect(RRect.fromRectAndRadius(frontGlass, const Radius.circular(2)), glass);
  }

  void _drawTopDownUtility(Canvas canvas, Offset c, double w, double h, Paint paint, Paint glass) {
    final cw = w * 0.40;
    final ch = h * 0.64;
    final bodyRect = Rect.fromCenter(center: c, width: cw, height: ch);

    // Rectangular commercial body
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)), paint);

    // Cab windshield
    final cabGlass = Rect.fromCenter(center: Offset(c.dx, c.dy - (ch * 0.25)), width: cw * 0.78, height: ch * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(cabGlass, const Radius.circular(2)), glass);
  }

  @override
  bool shouldRepaint(covariant VehicleMarkerPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isActive != isActive ||
        oldDelegate.heading != heading;
  }
}
