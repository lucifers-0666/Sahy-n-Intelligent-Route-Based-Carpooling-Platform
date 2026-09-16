import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/gps_provider.dart';
import '../../domain/models/location_point.dart';

/// Concrete GpsProvider implementation backed by the device's Geolocator hardware service
class GeolocatorProvider implements GpsProvider {
  StreamController<LocationPoint>? _streamController;
  StreamSubscription<Position>? _positionSubscription;

  static const LocationSettings _defaultSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // meters
  );

  @override
  Stream<LocationPoint> get positionStream {
    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<LocationPoint>.broadcast(
        onListen: _startListening,
        onCancel: _stopListening,
      );
    }
    return _streamController!.stream;
  }

  void _startListening() {
    if (kIsWeb) return;

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _defaultSettings,
    ).listen(
      (Position pos) {
        if (_streamController != null && !_streamController!.isClosed) {
          _streamController!.add(_positionToLocationPoint(pos));
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          debugPrint('[GeolocatorProvider] Position stream error: $error');
        }
      },
      cancelOnError: false,
    );
  }

  void _stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  Future<LocationPoint?> getCurrentPosition() async {
    if (kIsWeb) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _defaultSettings,
      );
      return _positionToLocationPoint(pos);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeolocatorProvider] getCurrentPosition error: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> isServiceEnabled() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    if (kIsWeb) return LocationPermissionStatus.unavailable;
    try {
      final perm = await Geolocator.checkPermission();
      return _mapPermission(perm);
    } catch (_) {
      return LocationPermissionStatus.error;
    }
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    if (kIsWeb) return LocationPermissionStatus.unavailable;
    try {
      final perm = await Geolocator.requestPermission();
      return _mapPermission(perm);
    } catch (_) {
      return LocationPermissionStatus.error;
    }
  }

  LocationPermissionStatus _mapPermission(LocationPermission perm) {
    switch (perm) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  LocationPoint _positionToLocationPoint(Position pos) {
    return LocationPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      speed: pos.speed >= 0 ? pos.speed * 3.6 : 0.0, // m/s -> km/h
      heading: pos.heading >= 0 ? pos.heading : 0.0,
      timestamp: pos.timestamp,
      provider: 'geolocator',
      isMock: pos.isMocked,
      speedAccuracy: pos.speedAccuracy,
      headingAccuracy: pos.headingAccuracy,
    );
  }

  @override
  Future<void> dispose() async {
    _stopListening();
    if (_streamController != null && !_streamController!.isClosed) {
      await _streamController!.close();
    }
    _streamController = null;
  }
}
