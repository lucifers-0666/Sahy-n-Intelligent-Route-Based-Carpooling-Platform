import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../network/socket_client.dart';

/// Foreground GPS streaming service for the driver.
///
/// Lifecycle:
///   1. Call [startStreaming] when the driver activates a trip.
///   2. The service requests location permission, then subscribes to
///      [Geolocator.getPositionStream] and emits each fix to Socket.IO.
///   3. Call [stopStreaming] when the driver ends the trip.
///
/// On web or desktop (where geolocator is unavailable) the service
/// gracefully returns without error — the simulation fallback in
/// LiveRideTrackingScreen remains active on non-native platforms.
class DriverLocationService {
  DriverLocationService._internal();
  static final DriverLocationService instance = DriverLocationService._internal();

  StreamSubscription<Position>? _positionSub;
  String? _activeRideId;
  bool _isStreaming = false;

  bool get isStreaming => _isStreaming;

  // ── Settings ──────────────────────────────────────────────────────────────

  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // metres
    // NOTE: timeLimit is not supported in LocationSettings constructor;
    // use interval inside AndroidSettings / AppleSettings if needed.
  );

  // ── Start Streaming ───────────────────────────────────────────────────────

  /// Request permission and begin streaming GPS fixes for [rideId].
  /// Returns `true` if streaming started successfully.
  Future<bool> startStreaming(String rideId) async {
    if (_isStreaming) await stopStreaming();

    // Web / desktop: geolocator is not supported.
    if (kIsWeb) {
      debugPrint('[DriverLocationService] Web platform — GPS streaming not supported.');
      return false;
    }

    // Permission check
    try {
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        debugPrint('[DriverLocationService] Location permission denied.');
        return false;
      }
    } catch (e) {
      debugPrint('[DriverLocationService] Permission error: $e');
      return false;
    }

    _activeRideId = rideId;
    _isStreaming = true;

    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (Position position) {
          _onPosition(position);
        },
        onError: (Object e) {
          debugPrint('[DriverLocationService] Position stream error: $e');
          // Attempt to restart on recoverable errors
        },
        cancelOnError: false,
      );

      debugPrint('[DriverLocationService] Streaming GPS for ride: $rideId');
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
    debugPrint('[DriverLocationService] GPS streaming stopped for ride: $_activeRideId');
    _activeRideId = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onPosition(Position position) {
    if (_activeRideId == null) return;

    final payload = DriverLocationPayload(
      rideId: _activeRideId!,
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading >= 0 ? position.heading : 0.0,
      speed: position.speed * 3.6, // m/s → km/h
      timestamp: DateTime.now(),
    );

    SocketClient.instance.emitDriverLocation(payload);

    if (kDebugMode) {
      debugPrint(
        '[DriverLocationService] GPS: ${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)} | '
        'hdg:${payload.heading.toStringAsFixed(1)}° | '
        'spd:${payload.speed.toStringAsFixed(1)}km/h',
      );
    }
  }

  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[DriverLocationService] Permission permanently denied. Open settings.');
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
