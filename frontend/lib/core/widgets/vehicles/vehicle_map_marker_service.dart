import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import '../../../../app/theme/app_colors.dart';
import '../../../features/vehicles/domain/vehicle_type.dart';
import 'vehicle_painters.dart';

/// Data payload for a live vehicle position on the Sahyān Map.
class LiveVehicleMarkerData {
  final String driverId;
  final String rideId;
  final VehicleType vehicleType;
  final double latitude;
  final double longitude;
  final double heading; // 0 to 360 degrees
  final double speed; // km/h
  final DateTime updatedAt;
  final bool isActive;
  final String? driverName;
  final String? vehiclePlate;

  const LiveVehicleMarkerData({
    required this.driverId,
    required this.rideId,
    required this.vehicleType,
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 0.0,
    required this.updatedAt,
    this.isActive = true,
    this.driverName,
    this.vehiclePlate,
  });

  ll.LatLng get position => ll.LatLng(latitude, longitude);

  LiveVehicleMarkerData copyWith({
    String? driverId,
    String? rideId,
    VehicleType? vehicleType,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    DateTime? updatedAt,
    bool? isActive,
    String? driverName,
    String? vehiclePlate,
  }) {
    return LiveVehicleMarkerData(
      driverId: driverId ?? this.driverId,
      rideId: rideId ?? this.rideId,
      vehicleType: vehicleType ?? this.vehicleType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    );
  }
}

/// Service to generate vehicle markers for FlutterMap / OpenStreetMap.
class VehicleMapMarkerService {
  VehicleMapMarkerService._();
  static final VehicleMapMarkerService instance = VehicleMapMarkerService._();

  /// Builds a complete FlutterMap Marker object for a vehicle.
  fmap.Marker createVehicleMarker({
    required LiveVehicleMarkerData data,
    double size = 48.0,
    VoidCallback? onTap,
  }) {
    return fmap.Marker(
      point: data.position,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          size: Size(size, size),
          painter: VehicleMarkerPainter(
            type: data.vehicleType,
            primaryColor: AppColors.primary,
            isActive: data.isActive,
            heading: data.heading,
          ),
        ),
      ),
    );
  }

  void clearCache() {}
}
