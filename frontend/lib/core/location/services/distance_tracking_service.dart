import '../domain/distance_calculator.dart';
import '../domain/models/location_point.dart';

/// Cumulative GPS Tracked Distance Aggregator
///
/// Distinct from remaining road routing distance:
/// Tracks physical displacement along validated GPS fixes:
/// totalTrackedDistance += Haversine(P_prev, P_curr)
class DistanceTrackingService {
  double _totalTrackedDistanceMeters = 0.0;
  LocationPoint? _lastTrackedPoint;

  double get totalTrackedDistanceMeters => _totalTrackedDistanceMeters;
  double get totalTrackedDistanceKm => _totalTrackedDistanceMeters / 1000.0;
  LocationPoint? get lastTrackedPoint => _lastTrackedPoint;

  /// Reset distance accumulator on trip initialization
  void reset() {
    _totalTrackedDistanceMeters = 0.0;
    _lastTrackedPoint = null;
  }

  /// Add a preprocessed, validated coordinate fix to cumulative tracked distance
  /// Only adds distance if displacement exceeds stationary noise threshold (e.g. 2 meters)
  double addPoint(LocationPoint point) {
    if (_lastTrackedPoint != null) {
      final stepDistance = DistanceCalculator.haversineDistance(
        _lastTrackedPoint!.latitude,
        _lastTrackedPoint!.longitude,
        point.latitude,
        point.longitude,
      );

      // Filter out micro-jitter when stationary
      if (stepDistance >= 2.0) {
        _totalTrackedDistanceMeters += stepDistance;
        _lastTrackedPoint = point;
      }
    } else {
      _lastTrackedPoint = point;
    }

    return _totalTrackedDistanceMeters;
  }
}
