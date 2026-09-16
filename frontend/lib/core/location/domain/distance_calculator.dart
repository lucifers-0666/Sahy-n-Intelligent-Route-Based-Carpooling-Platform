import 'dart:math' as math;

/// Standalone pure mathematical Haversine distance and bearing calculator
class DistanceCalculator {
  static const double kEarthRadiusMeters = 6371000.0;

  /// Calculate great-circle distance in meters between two coordinates using Haversine
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
    return kEarthRadiusMeters * c;
  }

  /// Calculate forward compass bearing in degrees (0.0 to 359.9) from point 1 to point 2
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    final double phi1 = _degreesToRadians(lat1);
    final double phi2 = _degreesToRadians(lat2);
    final double deltaLambda = _degreesToRadians(lon2 - lon1);

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final double theta = math.atan2(y, x);
    final double bearingDegrees = (_radiansToDegrees(theta) + 360.0) % 360.0;
    return bearingDegrees;
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);
  static double _radiansToDegrees(double radians) => radians * (180.0 / math.pi);
}
