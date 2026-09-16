import 'dart:async';
import '../domain/gps_provider.dart';
import '../domain/models/location_point.dart';

/// Structured result returned by GpsDiagnosticService
class GpsDiagnosticResult {
  final bool locationServicesEnabled;
  final LocationPermissionStatus permissionStatus;
  final bool hasPosition;
  final LocationPoint? lastPosition;
  final double? accuracyMeters;
  final DateTime? timestamp;
  final bool speedAvailable;
  final bool headingAvailable;
  final String? errorCode;
  final String statusSummary;

  const GpsDiagnosticResult({
    required this.locationServicesEnabled,
    required this.permissionStatus,
    required this.hasPosition,
    this.lastPosition,
    this.accuracyMeters,
    this.timestamp,
    this.speedAvailable = false,
    this.headingAvailable = false,
    this.errorCode,
    required this.statusSummary,
  });

  bool get isHealthy =>
      locationServicesEnabled &&
      permissionStatus == LocationPermissionStatus.granted &&
      hasPosition &&
      (accuracyMeters ?? 100.0) <= 50.0;
}

/// Service executing structured hardware GPS diagnostics
class GpsDiagnosticService {
  final GpsProvider provider;

  const GpsDiagnosticService(this.provider);

  /// Run a comprehensive health check on GPS positioning capabilities
  Future<GpsDiagnosticResult> runDiagnostics() async {
    // 1. Service check
    final servicesEnabled = await provider.isServiceEnabled();
    if (!servicesEnabled) {
      return const GpsDiagnosticResult(
        locationServicesEnabled: false,
        permissionStatus: LocationPermissionStatus.serviceDisabled,
        hasPosition: false,
        errorCode: 'LOCATION_SERVICES_DISABLED',
        statusSummary: 'Device location services are disabled in system settings.',
      );
    }

    // 2. Permission check
    final permission = await provider.checkPermission();
    if (permission != LocationPermissionStatus.granted) {
      return GpsDiagnosticResult(
        locationServicesEnabled: true,
        permissionStatus: permission,
        hasPosition: false,
        errorCode: 'PERMISSION_${permission.name.toUpperCase()}',
        statusSummary: 'Location permission is not granted (${permission.name}).',
      );
    }

    // 3. Acquire first coordinate fix
    try {
      final pos = await provider.getCurrentPosition();
      if (pos == null) {
        return const GpsDiagnosticResult(
          locationServicesEnabled: true,
          permissionStatus: LocationPermissionStatus.granted,
          hasPosition: false,
          errorCode: 'POSITION_UNAVAILABLE',
          statusSummary: 'Unable to acquire initial GPS fix from provider.',
        );
      }

      final speedAvailable = pos.speed > 0.0 || pos.speedAccuracy != null;
      final headingAvailable = pos.heading > 0.0 || pos.headingAccuracy != null;

      return GpsDiagnosticResult(
        locationServicesEnabled: true,
        permissionStatus: LocationPermissionStatus.granted,
        hasPosition: true,
        lastPosition: pos,
        accuracyMeters: pos.accuracy,
        timestamp: pos.timestamp,
        speedAvailable: speedAvailable,
        headingAvailable: headingAvailable,
        statusSummary: 'GPS provider healthy. Accuracy: ${pos.accuracy.toStringAsFixed(1)}m.',
      );
    } catch (e) {
      return GpsDiagnosticResult(
        locationServicesEnabled: true,
        permissionStatus: LocationPermissionStatus.granted,
        hasPosition: false,
        errorCode: 'DIAGNOSTIC_ERROR',
        statusSummary: 'Diagnostic exception: $e',
      );
    }
  }
}
