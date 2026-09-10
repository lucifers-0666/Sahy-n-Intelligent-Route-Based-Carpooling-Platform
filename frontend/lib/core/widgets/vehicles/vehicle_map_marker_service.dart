import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../features/vehicles/domain/vehicle_type.dart';
import 'vehicle_painters.dart';

/// Data payload for a live vehicle position on the Google Map.
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

  LatLng get position => LatLng(latitude, longitude);

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

/// Service to generate and cache custom Google Maps BitmapDescriptors
/// for all 19 Sahyān vehicle categories with rotation and crisp road contrast.
class VehicleMapMarkerService {
  VehicleMapMarkerService._();
  static final VehicleMapMarkerService instance = VehicleMapMarkerService._();

  // Cache descriptors by key: "${type.code}_${quantizedHeading}_$isActive"
  final Map<String, BitmapDescriptor> _descriptorCache = {};

  /// Quantizes heading to nearest 5 degrees to keep marker cache fast and small.
  int _quantizeHeading(double heading) {
    final normalized = (heading % 360 + 360) % 360;
    return ((normalized / 5).round() * 5) % 360;
  }

  /// Generates or retrieves a cached BitmapDescriptor for the vehicle marker.
  Future<BitmapDescriptor> getVehicleMarkerBitmap({
    required VehicleType type,
    double heading = 0.0,
    bool isActive = true,
    double size = 96.0,
    Color primaryColor = AppColors.primary,
  }) async {
    final qHeading = _quantizeHeading(heading);
    final cacheKey = '${type.code}_${qHeading}_$isActive';

    if (_descriptorCache.containsKey(cacheKey)) {
      return _descriptorCache[cacheKey]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = VehicleMarkerPainter(
      type: type,
      primaryColor: primaryColor,
      isActive: isActive,
      heading: qHeading.toDouble(),
    );

    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    final uint8List = byteData.buffer.asUint8List();
    final descriptor = BitmapDescriptor.bytes(uint8List);
    _descriptorCache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Builds a complete Google Maps Marker object for a vehicle.
  Future<Marker> createVehicleMarker({
    required LiveVehicleMarkerData data,
    VoidCallback? onTap,
  }) async {
    final icon = await getVehicleMarkerBitmap(
      type: data.vehicleType,
      heading: data.heading,
      isActive: data.isActive,
    );

    return Marker(
      markerId: MarkerId('driver_vehicle_${data.driverId}'),
      position: data.position,
      icon: icon,
      anchor: const Offset(0.5, 0.5), // Center anchor for top-down directional vehicle
      flat: true, // Marker rotates with map tilt/compass
      rotation: 0.0, // Rotation is already rendered into custom icon bitmap
      infoWindow: InfoWindow(
        title: data.driverName ?? 'Sahyān Driver',
        snippet: data.vehiclePlate != null
            ? '${data.vehicleType.displayName} (${data.vehiclePlate})'
            : data.vehicleType.displayName,
      ),
      onTap: onTap,
    );
  }

  /// Clears cache when memory pressure or theme change occurs.
  void clearCache() {
    _descriptorCache.clear();
  }
}
