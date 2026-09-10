import 'package:equatable/equatable.dart';
import 'vehicle_type.dart';

class VehicleModel extends Equatable {
  final String id;
  final String ownerId;
  final String registrationNumber;
  final String vehicleType;
  final String make;
  final String model;
  final int year;
  final String color;
  final int seatCapacity;
  final String status;
  final String? vehicleImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleModel({
    required this.id,
    required this.ownerId,
    required this.registrationNumber,
    required this.vehicleType,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.seatCapacity,
    this.status = 'active',
    this.vehicleImage,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => '$make $model';
  String get fullName =>
      color.isNotEmpty ? '$make $model ($color)' : '$make $model';

  VehicleType get type => VehicleTypeExtension.fromString(vehicleType);

  String get typeDisplay => type.displayName;

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      ownerId: json['owner']?.toString() ?? json['ownerId']?.toString() ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? 'sedan',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      color: json['color'] ?? '',
      seatCapacity: (json['seatCapacity'] as num?)?.toInt() ?? 4,
      status: json['status'] ?? 'active',
      vehicleImage: json['vehicleImage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': ownerId,
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'seatCapacity': seatCapacity,
      'status': status,
      if (vehicleImage != null) 'vehicleImage': vehicleImage,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? ownerId,
    String? registrationNumber,
    String? vehicleType,
    String? make,
    String? model,
    int? year,
    String? color,
    int? seatCapacity,
    String? status,
    String? vehicleImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      status: status ?? this.status,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    registrationNumber,
    vehicleType,
    make,
    model,
    year,
    color,
    seatCapacity,
    status,
    vehicleImage,
  ];
}
