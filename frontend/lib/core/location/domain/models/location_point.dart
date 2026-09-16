import 'package:flutter/foundation.dart';

/// Strongly typed GPS telematics location model
@immutable
class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed; // km/h
  final double heading; // 0.0 - 359.9 degrees
  final DateTime timestamp;
  final String provider;
  final bool isMock;
  final double? verticalAccuracy;
  final double? speedAccuracy;
  final double? headingAccuracy;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy = 10.0,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.timestamp,
    this.provider = 'gps',
    this.isMock = false,
    this.verticalAccuracy,
    this.speedAccuracy,
    this.headingAccuracy,
  });

  factory LocationPoint.fromMap(Map<dynamic, dynamic> map) {
    return LocationPoint(
      latitude: (map['latitude'] as num?)?.toDouble() ?? (map['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? (map['lng'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 10.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      provider: map['provider']?.toString() ?? 'gps',
      isMock: map['isMock'] == true,
      verticalAccuracy: (map['verticalAccuracy'] as num?)?.toDouble(),
      speedAccuracy: (map['speedAccuracy'] as num?)?.toDouble(),
      headingAccuracy: (map['headingAccuracy'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
        'provider': provider,
        'isMock': isMock,
        if (verticalAccuracy != null) 'verticalAccuracy': verticalAccuracy,
        if (speedAccuracy != null) 'speedAccuracy': speedAccuracy,
        if (headingAccuracy != null) 'headingAccuracy': headingAccuracy,
      };

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? provider,
    bool? isMock,
    double? verticalAccuracy,
    double? speedAccuracy,
    double? headingAccuracy,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      provider: provider ?? this.provider,
      isMock: isMock ?? this.isMock,
      verticalAccuracy: verticalAccuracy ?? this.verticalAccuracy,
      speedAccuracy: speedAccuracy ?? this.speedAccuracy,
      headingAccuracy: headingAccuracy ?? this.headingAccuracy,
    );
  }

  @override
  String toString() =>
      'LocationPoint(lat: ${latitude.toStringAsFixed(5)}, lng: ${longitude.toStringAsFixed(5)}, '
      'acc: ${accuracy.toStringAsFixed(1)}m, spd: ${speed.toStringAsFixed(1)}km/h, '
      'hdg: ${heading.toStringAsFixed(1)}°)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(latitude, longitude, timestamp);
}
