import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class RouteMapPreview extends StatelessWidget {
  final LocationModel origin;
  final LocationModel destination;
  final RouteInfo? route;
  final bool isCalculating;
  final double height;

  const RouteMapPreview({
    super.key,
    required this.origin,
    required this.destination,
    this.route,
    this.isCalculating = false,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final polylinePoints = route != null && route!.encodedPolyline.isNotEmpty
        ? RouteService.decodePolyline(route!.encodedPolyline)
        : <LatLngPoint>[];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softForest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background grid simulation
          CustomPaint(
            size: Size.infinite,
            painter: _GridBackgroundPainter(),
          ),

          // Route polyline & marker rendering
          if (polylinePoints.isNotEmpty)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: CustomPaint(
                  painter: _RoutePolylinePainter(
                    points: polylinePoints,
                    originLat: origin.latitude,
                    originLng: origin.longitude,
                    destLat: destination.latitude,
                    destLng: destination.longitude,
                  ),
                ),
              ),
            )
          else
            Center(
              child: isCalculating
                  ? const CircularProgressIndicator(
                      color: AppColors.primaryForest,
                      strokeWidth: 2.5,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: AppColors.mutedSage,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Route calculation ready',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
            ),

          // Top location strip
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trip_origin, size: 12, color: AppColors.primaryForest),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            origin.name,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepForest,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, size: 10, color: AppColors.mutedSage),
                        ),
                        Flexible(
                          child: Text(
                            destination.name,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepForest,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom metrics badges
          if (route != null && !isCalculating)
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.deepForest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten, size: 13, color: AppColors.white),
                        const SizedBox(width: 4),
                        Text(
                          route!.formattedDistance,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 13, color: AppColors.primaryForest),
                        const SizedBox(width: 4),
                        Text(
                          route!.formattedDuration,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.deepForest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const double step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePolylinePainter extends CustomPainter {
  final List<LatLngPoint> points;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  _RoutePolylinePainter({
    required this.points,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Prevent divide-by-zero on flat routes
    final latSpan = math.max(0.001, maxLat - minLat);
    final lngSpan = math.max(0.001, maxLng - minLng);

    Offset toCanvasOffset(double lat, double lng) {
      final normX = (lng - minLng) / lngSpan;
      // Invert Y because latitude goes north (up), but canvas Y goes down
      final normY = 1.0 - ((lat - minLat) / latSpan);
      return Offset(normX * size.width, normY * size.height);
    }

    // 1. Draw Polyline casing / shadow
    final casingPaint = Paint()
      ..color = AppColors.deepForest.withValues(alpha: 0.15)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final polylinePaint = Paint()
      ..color = AppColors.primaryForest
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final firstOffset = toCanvasOffset(points.first.latitude, points.first.longitude);
    path.moveTo(firstOffset.dx, firstOffset.dy);

    for (int i = 1; i < points.length; i++) {
      final offset = toCanvasOffset(points[i].latitude, points[i].longitude);
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(path, casingPaint);
    canvas.drawPath(path, polylinePaint);

    // 2. Draw Origin Marker (A)
    final originOffset = toCanvasOffset(originLat, originLng);
    final originPaint = Paint()..color = const Color(0xFF2E6B4B);
    final originOuter = Paint()..color = AppColors.white;
    canvas.drawCircle(originOffset, 7.0, originOuter);
    canvas.drawCircle(originOffset, 5.0, originPaint);

    // 3. Draw Destination Marker (B)
    final destOffset = toCanvasOffset(destLat, destLng);
    final destPaint = Paint()..color = AppColors.deepForest;
    final destOuter = Paint()..color = AppColors.white;
    canvas.drawCircle(destOffset, 7.0, destOuter);
    canvas.drawCircle(destOffset, 5.0, destPaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePolylinePainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.originLat != originLat ||
        oldDelegate.destLat != destLat;
  }
}
