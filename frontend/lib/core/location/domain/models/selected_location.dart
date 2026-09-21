import 'package:flutter/foundation.dart';

/// Structured location model for selection, pickup, and destination
@immutable
class SelectedLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;

  const SelectedLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  factory SelectedLocation.fromJson(Map<String, dynamic> json) {
    return SelectedLocation(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      placeId: json['placeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    if (placeId != null) 'placeId': placeId,
  };

  SelectedLocation copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
  }) {
    return SelectedLocation(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
    );
  }

  @override
  String toString() => 'SelectedLocation($name, $latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          name == other.name;

  @override
  int get hashCode => Object.hash(name, latitude, longitude);
}
