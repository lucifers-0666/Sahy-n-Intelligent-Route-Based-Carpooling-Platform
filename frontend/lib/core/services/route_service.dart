import 'dart:math' as math;

class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint(this.latitude, this.longitude);

  @override
  String toString() => 'LatLngPoint($latitude, $longitude)';
}

/// Service providing polyline decoding, distance calculations, and route utilities
class RouteService {
  /// Decode a Google Maps encoded polyline string into a list of LatLngPoint
  static List<LatLngPoint> decodePolyline(String encoded) {
    final List<LatLngPoint> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLngPoint(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Encode a list of LatLngPoints into a Google encoded polyline string
  static String encodePolyline(List<LatLngPoint> points) {
    final StringBuffer str = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      final int lat = (point.latitude * 1E5).round();
      final int lng = (point.longitude * 1E5).round();

      _encodeInt(lat - prevLat, str);
      _encodeInt(lng - prevLng, str);

      prevLat = lat;
      prevLng = lng;
    }

    return str.toString();
  }

  static void _encodeInt(int value, StringBuffer str) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      str.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    str.writeCharCode(v + 63);
  }

  /// Calculate Haversine distance in meters between two coordinates
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Format distance in meters to a human readable string
  static String formatDistance(double meters) {
    final km = meters / 1000.0;
    if (km >= 1) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  /// Format duration in seconds to a human readable string
  static String formatDuration(int seconds) {
    final int minutes = (seconds / 60).round();
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '$hours hr $remainingMinutes min';
    }
    return '$minutes min';
  }
}
