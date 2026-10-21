import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String? placeId;

  const LocationModel({
    String? name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.placeId,
  }) : name = name ?? address;

  factory LocationModel.fromCoordinates({
    required String name,
    required double latitude,
    required double longitude,
    String? placeId,
  }) {
    return LocationModel(
      name: name,
      address: name,
      city: name.contains(',') ? name.split(',').last.trim() : name,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
    );
  }

  static double _parseCoord(dynamic directVal, dynamic pointVal, int coordIndex) {
    if (directVal is num) return directVal.toDouble();
    if (directVal is String) {
      final parsed = double.tryParse(directVal);
      if (parsed != null) return parsed;
    }
    if (pointVal is Map && pointVal['coordinates'] is List) {
      final coords = pointVal['coordinates'] as List;
      if (coords.length > coordIndex) {
        final val = coords[coordIndex];
        if (val is num) return val.toDouble();
        if (val is String) {
          final parsed = double.tryParse(val);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0;
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String?;
    final rawAddress = json['address'] as String? ?? '';
    final rawCity = json['city'] as String? ?? '';
    final computedName =
        rawName ?? (rawAddress.isNotEmpty ? rawAddress : rawCity);

    return LocationModel(
      name: computedName,
      address: rawAddress.isNotEmpty ? rawAddress : computedName,
      city: rawCity.isNotEmpty
          ? rawCity
          : (computedName.contains(',')
                ? computedName.split(',').last.trim()
                : computedName),
      latitude: _parseCoord(json['latitude'], json['point'], 1),
      longitude: _parseCoord(json['longitude'], json['point'], 0),
      placeId: json['placeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      if (placeId != null) 'placeId': placeId,
    };
  }

  LocationModel copyWith({
    String? name,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? placeId,
  }) {
    return LocationModel(
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
    );
  }

  @override
  List<Object?> get props => [
    name,
    address,
    city,
    latitude,
    longitude,
    placeId,
  ];
}
