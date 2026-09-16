import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/distance_calculator.dart';
import '../domain/models/location_point.dart';

/// Progress evaluation output
class RouteProgressResult {
  final double distanceRemainingMeters;
  final double totalDistanceMeters;
  final double progressFraction; // 0.0 - 1.0
  final bool isOffRoute;
  final double deviationMeters;
  final double effectiveDeviationMeters;
  final int nearestSegmentIndex;

  double get distanceRemainingKm => distanceRemainingMeters / 1000.0;
  double get totalDistanceKm => totalDistanceMeters / 1000.0;
  double get progressPercentage => (progressFraction * 100.0).clamp(0.0, 100.0);

  const RouteProgressResult({
    required this.distanceRemainingMeters,
    required this.totalDistanceMeters,
    required this.progressFraction,
    required this.isOffRoute,
    required this.deviationMeters,
    required this.effectiveDeviationMeters,
    required this.nearestSegmentIndex,
  });
}

/// Route Progress and Spatial Off-Route Detection Service
class RouteProgressService {
  static const double kDefaultOffRouteThresholdMeters = 80.0;

  /// Evaluate driver position progress along an active polyline
  static RouteProgressResult evaluateProgress({
    required LocationPoint currentPosition,
    required List<LatLng> polylinePoints,
    required LatLng destination,
    double offRouteThresholdMeters = kDefaultOffRouteThresholdMeters,
  }) {
    if (polylinePoints.isEmpty) {
      final directDist = DistanceCalculator.haversineDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        destination.latitude,
        destination.longitude,
      );
      return RouteProgressResult(
        distanceRemainingMeters: directDist,
        totalDistanceMeters: directDist,
        progressFraction: 0.0,
        isOffRoute: false,
        deviationMeters: 0.0,
        effectiveDeviationMeters: 0.0,
        nearestSegmentIndex: 0,
      );
    }

    if (polylinePoints.length == 1) {
      final p = polylinePoints.first;
      final dist = DistanceCalculator.haversineDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        p.latitude,
        p.longitude,
      );
      return RouteProgressResult(
        distanceRemainingMeters: dist,
        totalDistanceMeters: 0.0,
        progressFraction: 1.0,
        isOffRoute: false,
        deviationMeters: dist,
        effectiveDeviationMeters: math.max(0.0, dist - currentPosition.accuracy),
        nearestSegmentIndex: 0,
      );
    }

    double minDistance = double.infinity;
    int nearestIndex = 0;
    double bestProjLat = polylinePoints.first.latitude;
    double bestProjLng = polylinePoints.first.longitude;

    for (int i = 0; i < polylinePoints.length - 1; i++) {
      final p1 = polylinePoints[i];
      final p2 = polylinePoints[i + 1];

      final proj = _projectOntoSegment(
        currentPosition.latitude,
        currentPosition.longitude,
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );

      if (proj.distanceMeters < minDistance) {
        minDistance = proj.distanceMeters;
        nearestIndex = i;
        bestProjLat = proj.projLat;
        bestProjLng = proj.projLng;
      }
    }

    // Effective deviation subtracts GPS accuracy uncertainty
    final effectiveDeviation = math.max(0.0, minDistance - currentPosition.accuracy);
    final isOffRoute = effectiveDeviation > offRouteThresholdMeters;

    // Remaining polyline distance: from projection point to next waypoint, then sum remaining segments
    double remainingDistance = DistanceCalculator.haversineDistance(
      bestProjLat,
      bestProjLng,
      polylinePoints[nearestIndex + 1].latitude,
      polylinePoints[nearestIndex + 1].longitude,
    );

    for (int i = nearestIndex + 1; i < polylinePoints.length - 1; i++) {
      remainingDistance += DistanceCalculator.haversineDistance(
        polylinePoints[i].latitude,
        polylinePoints[i].longitude,
        polylinePoints[i + 1].latitude,
        polylinePoints[i + 1].longitude,
      );
    }

    // Total polyline distance
    double totalDistance = 0.0;
    for (int i = 0; i < polylinePoints.length - 1; i++) {
      totalDistance += DistanceCalculator.haversineDistance(
        polylinePoints[i].latitude,
        polylinePoints[i].longitude,
        polylinePoints[i + 1].latitude,
        polylinePoints[i + 1].longitude,
      );
    }

    final progressFraction = totalDistance > 0.0
        ? (1.0 - (remainingDistance / totalDistance)).clamp(0.0, 1.0)
        : 0.0;

    return RouteProgressResult(
      distanceRemainingMeters: remainingDistance,
      totalDistanceMeters: totalDistance,
      progressFraction: progressFraction,
      isOffRoute: isOffRoute,
      deviationMeters: minDistance,
      effectiveDeviationMeters: effectiveDeviation,
      nearestSegmentIndex: nearestIndex,
    );
  }

  static _SegmentProjection _projectOntoSegment(
    double pLat,
    double pLng,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0.0 && dy == 0.0) {
      return _SegmentProjection(
        distanceMeters: DistanceCalculator.haversineDistance(pLat, pLng, x1, y1),
        projLat: x1,
        projLng: y1,
      );
    }

    final t = ((pLat - x1) * dx + (pLng - y1) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);

    final projLat = x1 + clampedT * dx;
    final projLng = y1 + clampedT * dy;

    final dist = DistanceCalculator.haversineDistance(pLat, pLng, projLat, projLng);
    return _SegmentProjection(
      distanceMeters: dist,
      projLat: projLat,
      projLng: projLng,
    );
  }
}

class _SegmentProjection {
  final double distanceMeters;
  final double projLat;
  final double projLng;

  const _SegmentProjection({
    required this.distanceMeters,
    required this.projLat,
    required this.projLng,
  });
}
