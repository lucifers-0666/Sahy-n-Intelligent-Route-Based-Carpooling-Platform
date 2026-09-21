import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/geolocator_provider.dart';
import '../domain/gps_provider.dart';
import '../domain/models/location_point.dart';
import '../domain/models/selected_location.dart';

@immutable
class UserLocationState {
  final LocationPoint? currentLocation;
  final LocationPermissionStatus permissionStatus;
  final bool isServiceEnabled;
  final bool isLoading;
  final String? errorMessage;

  const UserLocationState({
    this.currentLocation,
    this.permissionStatus = LocationPermissionStatus.unknown,
    this.isServiceEnabled = true,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasLocation => currentLocation != null;
  bool get hasPermission => permissionStatus == LocationPermissionStatus.granted;

  SelectedLocation? toSelectedLocation({String defaultName = 'Current Location'}) {
    if (currentLocation == null) return null;
    return SelectedLocation(
      name: defaultName,
      address: 'Lat: ${currentLocation!.latitude.toStringAsFixed(4)}, Lng: ${currentLocation!.longitude.toStringAsFixed(4)}',
      latitude: currentLocation!.latitude,
      longitude: currentLocation!.longitude,
    );
  }

  UserLocationState copyWith({
    LocationPoint? currentLocation,
    LocationPermissionStatus? permissionStatus,
    bool? isServiceEnabled,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  final GpsProvider _gpsProvider;
  StreamSubscription<LocationPoint>? _streamSubscription;

  UserLocationNotifier({GpsProvider? gpsProvider})
      : _gpsProvider = gpsProvider ?? GeolocatorProvider(),
        super(const UserLocationState());

  /// Fetch the latest current GPS coordinate fix from phone hardware
  Future<LocationPoint?> refreshLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final serviceEnabled = await _gpsProvider.isServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isServiceEnabled: false,
          isLoading: false,
          errorMessage: 'Location services are disabled on this device.',
        );
        return null;
      }

      var permission = await _gpsProvider.checkPermission();
      if (permission == LocationPermissionStatus.denied ||
          permission == LocationPermissionStatus.unknown) {
        permission = await _gpsProvider.requestPermission();
      }

      if (permission != LocationPermissionStatus.granted) {
        final errorMsg = permission == LocationPermissionStatus.deniedForever
            ? 'Location permission is permanently denied. Please enable it in system settings.'
            : 'Location permission was denied.';
        state = state.copyWith(
          permissionStatus: permission,
          isServiceEnabled: true,
          isLoading: false,
          errorMessage: errorMsg,
        );
        return null;
      }

      final position = await _gpsProvider.getCurrentPosition();
      if (position != null) {
        state = state.copyWith(
          currentLocation: position,
          permissionStatus: permission,
          isServiceEnabled: true,
          isLoading: false,
          clearError: true,
        );
        return position;
      } else {
        state = state.copyWith(
          permissionStatus: permission,
          isServiceEnabled: true,
          isLoading: false,
          errorMessage: 'Unable to acquire GPS fix. Please verify location settings.',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Location error: $e',
      );
      return null;
    }
  }

  /// Explicitly request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final status = await _gpsProvider.requestPermission();
      state = state.copyWith(permissionStatus: status);
      if (status == LocationPermissionStatus.granted) {
        await refreshLocation();
      }
      return status;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Permission request failed: $e');
      return LocationPermissionStatus.error;
    }
  }

  /// Start continuous location updates for live tracking
  void startContinuousTracking() {
    _streamSubscription?.cancel();
    _streamSubscription = _gpsProvider.positionStream.listen(
      (point) {
        state = state.copyWith(
          currentLocation: point,
          clearError: true,
        );
      },
      onError: (error) {
        state = state.copyWith(errorMessage: 'Position stream error: $error');
      },
    );
  }

  /// Stop continuous location updates
  void stopContinuousTracking() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  @override
  void dispose() {
    stopContinuousTracking();
    super.dispose();
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});
