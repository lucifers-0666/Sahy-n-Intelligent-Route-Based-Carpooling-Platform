import 'models/location_point.dart';

/// Exhaustive GPS permission states
enum LocationPermissionStatus {
  unknown,
  requesting,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
  error,
}

/// Abstract Hardware / Mock GPS Provider Interface
abstract class GpsProvider {
  /// Stream of raw GPS updates from the device
  Stream<LocationPoint> get positionStream;

  /// Fetch a single current GPS coordinate fix
  Future<LocationPoint?> getCurrentPosition();

  /// Check if device location services (GPS hardware) are enabled
  Future<bool> isServiceEnabled();

  /// Check current application location permission state
  Future<LocationPermissionStatus> checkPermission();

  /// Request application location permission from user
  Future<LocationPermissionStatus> requestPermission();

  /// Dispose any active streams or listeners
  Future<void> dispose();
}
