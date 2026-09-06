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
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
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
