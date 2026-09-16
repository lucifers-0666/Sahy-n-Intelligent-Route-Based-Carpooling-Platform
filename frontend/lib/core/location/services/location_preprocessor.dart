import '../domain/distance_calculator.dart';
import '../domain/location_accuracy_policy.dart';
import '../domain/location_filter.dart';
import '../domain/models/location_point.dart';

/// Preprocessing Pipeline for raw GPS coordinates
///
/// Steps:
/// 1. Timestamp Freshness Check
/// 2. Accuracy Validation
/// 3. Outlier / Speed Sanity Check
/// 4. Exponential Moving Average (EMA) Coordinate Smoothing
/// 5. Heading Normalization
class LocationPreprocessor {
  final LocationFilter filter;
  final double smoothingAlpha;

  LocationPoint? _lastAcceptedPoint;
  LocationPoint? _lastSmoothedPoint;

  LocationPreprocessor({
    this.filter = const LocationFilter(),
    this.smoothingAlpha = 0.65,
  });

  LocationPoint? get lastAcceptedPoint => _lastAcceptedPoint;
  LocationPoint? get lastSmoothedPoint => _lastSmoothedPoint;

  /// Reset internal preprocessor state on trip completion
  void reset() {
    _lastAcceptedPoint = null;
    _lastSmoothedPoint = null;
  }

  /// Process a raw GPS fix through the preprocessor pipeline
  /// Returns a normalized, smoothed [LocationPoint] or `null` if rejected as invalid/outlier
  LocationPoint? process(LocationPoint raw) {
    // 1. Timestamp Freshness Validation
    if (!filter.isValidTimestamp(raw)) {
      return null;
    }

    // 2. Accuracy Validation (Reject fixes > 100m completely)
    if (raw.accuracy > LocationAccuracyPolicy.kInvalidThresholdMeters) {
      return null;
    }

    // 3. Outlier & Physical Speed Sanity Check
    if (_lastAcceptedPoint != null) {
      if (filter.isOutlier(_lastAcceptedPoint!, raw)) {
        return null;
      }
    }

    // Accept point
    _lastAcceptedPoint = raw;

    // 4. Exponential Moving Average (EMA) Coordinate Smoothing
    double smoothedLat = raw.latitude;
    double smoothedLng = raw.longitude;
    double smoothedHeading = raw.heading;

    if (_lastSmoothedPoint != null) {
      smoothedLat = _lastSmoothedPoint!.latitude +
          smoothingAlpha * (raw.latitude - _lastSmoothedPoint!.latitude);
      smoothedLng = _lastSmoothedPoint!.longitude +
          smoothingAlpha * (raw.longitude - _lastSmoothedPoint!.longitude);

      // If raw heading is 0 or unavailable, calculate from movement vector
      if (raw.heading == 0.0) {
        final distMoved = DistanceCalculator.haversineDistance(
          _lastSmoothedPoint!.latitude,
          _lastSmoothedPoint!.longitude,
          smoothedLat,
          smoothedLng,
        );
        if (distMoved > 2.0) {
          smoothedHeading = DistanceCalculator.calculateBearing(
            _lastSmoothedPoint!.latitude,
            _lastSmoothedPoint!.longitude,
            smoothedLat,
            smoothedLng,
          );
        } else {
          smoothedHeading = _lastSmoothedPoint!.heading;
        }
      } else {
        // Smooth heading using shortest angular delta
        smoothedHeading = _smoothHeading(_lastSmoothedPoint!.heading, raw.heading, smoothingAlpha);
      }
    }

    final normalized = raw.copyWith(
      latitude: smoothedLat,
      longitude: smoothedLng,
      heading: smoothedHeading,
    );

    _lastSmoothedPoint = normalized;
    return normalized;
  }

  double _smoothHeading(double prev, double curr, double alpha) {
    double delta = (curr - prev + 360.0) % 360.0;
    if (delta > 180.0) delta -= 360.0;
    return (prev + alpha * delta + 360.0) % 360.0;
  }
}
