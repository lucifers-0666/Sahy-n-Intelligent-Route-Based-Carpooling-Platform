import 'dart:async';
import '../../domain/gps_provider.dart';
import '../../domain/models/location_point.dart';

/// Mock GPS Provider for automated tests, preview environments, and web
class MockLocationProvider implements GpsProvider {
  final StreamController<LocationPoint> _controller = StreamController<LocationPoint>.broadcast();
  LocationPoint? _currentPoint;
  bool _serviceEnabled = true;
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.granted;

  MockLocationProvider({LocationPoint? initialPoint}) {
    _currentPoint = initialPoint ??
        LocationPoint(
          latitude: 23.0225,
          longitude: 72.5714,
          accuracy: 8.0,
          speed: 55.0,
          heading: 85.0,
          timestamp: DateTime.now(),
          provider: 'mock',
          isMock: true,
        );
  }

  void setServiceEnabled(bool enabled) {
    _serviceEnabled = enabled;
  }

  void setPermissionStatus(LocationPermissionStatus status) {
    _permissionStatus = status;
  }

  void emitLocation(LocationPoint point) {
    _currentPoint = point;
    if (!_controller.isClosed) {
      _controller.add(point);
    }
  }

  @override
  Stream<LocationPoint> get positionStream => _controller.stream;

  @override
  Future<LocationPoint?> getCurrentPosition() async => _currentPoint;

  @override
  Future<bool> isServiceEnabled() async => _serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async => _permissionStatus;

  @override
  Future<LocationPermissionStatus> requestPermission() async => _permissionStatus;

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
