import 'dart:async';
import 'package:flutter/foundation.dart';
import '../location/data/providers/geolocator_provider.dart';
import '../location/domain/gps_provider.dart';
import '../location/domain/location_filter.dart';
import '../location/domain/models/location_point.dart';
import '../location/services/distance_tracking_service.dart';
import '../location/services/location_cache_service.dart';
import '../location/services/location_preprocessor.dart';
import '../network/socket_client.dart';

/// Production-grade Foreground GPS Streaming and Telematics Service for Drivers
///
/// Lifecycle:
/// 1. Call [startStreaming] when the driver starts trip boarding or activates trip.
/// 2. Telemetry flows: GpsProvider -> LocationPreprocessor (Accuracy, Outlier, EMA Smoothing)
///    -> DistanceTrackingService (Cumulative GPS Tracked Distance)
///    -> SocketClient (JWT Authenticated Telematics).
/// 3. Call [stopStreaming] when driver completes or cancels the trip.
class DriverLocationService {
  DriverLocationService._internal();
  static final DriverLocationService instance = DriverLocationService._internal();

  GpsProvider _provider = GeolocatorProvider();
  StreamSubscription<LocationPoint>? _positionSub;
  String? _activeRideId;
  bool _isStreaming = false;

  LocationPreprocessor _preprocessor = LocationPreprocessor();
  final DistanceTrackingService _distanceTracker = DistanceTrackingService();
  final LocationCacheService _cacheService = LocationCacheService.instance;

  bool get isStreaming => _isStreaming;
  String? get activeRideId => _activeRideId;
  double get trackedDistanceMeters => _distanceTracker.totalTrackedDistanceMeters;
  double get trackedDistanceKm => _distanceTracker.totalTrackedDistanceKm;

  /// Custom provider injection for automated testing and preview environments
  void setProviderForTesting(GpsProvider provider) {
    _provider = provider;
  }

  // ── Start Streaming ───────────────────────────────────────────────────────

  /// Request permission and begin streaming preprocessed GPS telematics for [rideId]
  Future<bool> startStreaming(String rideId, {String? vehicleType, GpsProvider? provider}) async {
    if (_isStreaming) await stopStreaming();

    if (provider != null) {
      _provider = provider;
    } else {
      _provider = GeolocatorProvider();
    }

    _preprocessor = LocationPreprocessor(
      filter: LocationFilter(config: LocationFilterConfig.forVehicleType(vehicleType)),
    );
    _distanceTracker.reset();

    // Check device location service status
    final serviceEnabled = await _provider.isServiceEnabled();
    if (!serviceEnabled && !kIsWeb) {
      debugPrint('[DriverLocationService] Device location services are disabled.');
      return false;
    }

    // Permission check
    try {
      var status = await _provider.checkPermission();
      if (status == LocationPermissionStatus.denied) {
        status = await _provider.requestPermission();
      }

      if (status != LocationPermissionStatus.granted && !kIsWeb) {
        debugPrint('[DriverLocationService] Location permission denied: $status');
        return false;
      }
    } catch (e) {
      debugPrint('[DriverLocationService] Permission check error: $e');
      return false;
    }

    _activeRideId = rideId;
    _isStreaming = true;

    try {
      _positionSub = _provider.positionStream.listen(
        _onRawPosition,
        onError: (Object e) {
          debugPrint('[DriverLocationService] Position stream error: $e');
        },
        cancelOnError: false,
      );

      debugPrint('[DriverLocationService] Telematics streaming active for ride: $rideId');
      return true;
    } catch (e) {
      debugPrint('[DriverLocationService] Failed to start position stream: $e');
      _isStreaming = false;
      return false;
    }
  }

  // ── Stop Streaming ────────────────────────────────────────────────────────

  Future<void> stopStreaming() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _isStreaming = false;
    _preprocessor.reset();
    _distanceTracker.reset();
    debugPrint('[DriverLocationService] GPS streaming stopped for ride: $_activeRideId');
    _activeRideId = null;
  }

  // ── Internal Pipeline ─────────────────────────────────────────────────────

  void _onRawPosition(LocationPoint raw) {
    if (_activeRideId == null) return;

    // Execute Preprocessing Pipeline
    final normalized = _preprocessor.process(raw);
    if (normalized == null) {
      if (kDebugMode) {
        debugPrint('[DriverLocationService] GPS fix dropped by preprocessor pipeline.');
      }
      return;
    }

    // Accumulate validated cumulative GPS tracked distance
    _distanceTracker.addPoint(normalized);

    // Update in-memory local cache
    _cacheService.saveLocation(normalized);

    // Transmit compact telematics payload
    final payload = DriverLocationPayload(
      rideId: _activeRideId!,
      latitude: normalized.latitude,
      longitude: normalized.longitude,
      accuracy: normalized.accuracy,
      heading: normalized.heading,
      speed: normalized.speed,
      timestamp: normalized.timestamp,
    );

    SocketClient.instance.emitDriverLocation(payload);

    if (kDebugMode) {
      debugPrint(
        '[DriverLocationService] GPS: ${normalized.latitude.toStringAsFixed(5)}, '
        '${normalized.longitude.toStringAsFixed(5)} | '
        'acc:${normalized.accuracy.toStringAsFixed(1)}m | '
        'hdg:${normalized.heading.toStringAsFixed(1)}° | '
        'spd:${normalized.speed.toStringAsFixed(1)}km/h | '
        'dist:${_distanceTracker.totalTrackedDistanceKm.toStringAsFixed(2)}km',
      );
    }
  }
}
