import 'distance_calculator.dart';
import 'models/location_point.dart';

/// Configuration thresholds for location outlier filtering
class LocationFilterConfig {
  final double maxVehicleSpeedKmh;
  final double maxGpsJumpMeters;
  final int maxTimestampAgeSeconds;

  const LocationFilterConfig({
    this.maxVehicleSpeedKmh = 160.0,
    this.maxGpsJumpMeters = 2000.0,
    this.maxTimestampAgeSeconds = 60,
  });

  factory LocationFilterConfig.forVehicleType(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'motorcycle':
      case 'scooter':
      case 'electric_scooter':
        return const LocationFilterConfig(
          maxVehicleSpeedKmh: 130.0,
          maxGpsJumpMeters: 1000.0,
          maxTimestampAgeSeconds: 60,
        );
      case 'auto_rickshaw':
      case 'electric_auto_rickshaw':
        return const LocationFilterConfig(
          maxVehicleSpeedKmh: 80.0,
          maxGpsJumpMeters: 800.0,
          maxTimestampAgeSeconds: 60,
        );
      case 'suv':
      case 'muv':
      case 'crossover':
      case 'sedan':
      case 'hatchback':
      case 'ev':
      default:
        return const LocationFilterConfig(
          maxVehicleSpeedKmh: 160.0,
          maxGpsJumpMeters: 2000.0,
          maxTimestampAgeSeconds: 60,
        );
    }
  }
}

/// Outlier detector and spatial validator for GPS telematics fixes
class LocationFilter {
  final LocationFilterConfig config;

  const LocationFilter({this.config = const LocationFilterConfig()});

  /// Check if a single point's timestamp is physically reasonable
  bool isValidTimestamp(LocationPoint point) {
    final now = DateTime.now();
    final ageSeconds = now.difference(point.timestamp).inSeconds;
    // Discard points older than maxTimestampAgeSeconds or from future (> 30s)
    if (ageSeconds > config.maxTimestampAgeSeconds || ageSeconds < -30) {
      return false;
    }
    return true;
  }

  /// Check if consecutive coordinate fix is a physically impossible outlier jump
  bool isOutlier(LocationPoint previous, LocationPoint current) {
    final distMeters = DistanceCalculator.haversineDistance(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );

    // Absolute jump threshold
    if (distMeters > config.maxGpsJumpMeters) {
      return true;
    }

    final timeDeltaSec = current.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
    if (timeDeltaSec <= 0.0) {
      return distMeters > 30.0; // Stationary threshold for duplicate timestamp
    }

    final speedMps = distMeters / timeDeltaSec;
    final speedKmh = speedMps * 3.6;

    return speedKmh > config.maxVehicleSpeedKmh;
  }
}
