import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';

enum RideStatus { scheduled, boarding, active, completed, cancelled }

enum PickupPolicy { exact, nearby }

class RouteInfo extends Equatable {
  final String encodedPolyline;
  final double distanceMeters;
  final int durationSeconds;

  const RouteInfo({
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60.0).round();

  String get formattedDistance {
    if (distanceKm >= 1) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toStringAsFixed(0)} m';
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      encodedPolyline: json['encodedPolyline'] as String? ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encodedPolyline': encodedPolyline,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
    };
  }

  @override
  List<Object?> get props => [encodedPolyline, distanceMeters, durationSeconds];
}

class RideModel extends Equatable {
  final String id;
  final String driverId;
  final String driverName;
  final double driverRating;
  final String? driverPhoto;
  final bool isDriverVerified;
  final VehicleModel vehicle;
  final LocationModel origin;
  final LocationModel destination;
  final RouteInfo? route;
  final DateTime dateTime;
  final String departureTime;
  final String estimatedArrival;
  final int availableSeats;
  final int totalSeats;
  final int bookedSeats;
  final double contributionPerSeat;
  final int matchPercentage;
  final double _fallbackDistanceKm;
  final int _fallbackDurationMins;
  final RideStatus status;
  final PickupPolicy pickupPolicy;
  final List<String> amenities;
  final String? notes;

  const RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    this.driverPhoto,
    required this.isDriverVerified,
    required this.vehicle,
    required this.origin,
    required this.destination,
    this.route,
    required this.dateTime,
    required this.departureTime,
    required this.estimatedArrival,
    required this.availableSeats,
    required this.totalSeats,
    this.bookedSeats = 0,
    required this.contributionPerSeat,
    this.matchPercentage = 100,
    double routeDistanceKm = 0.0,
    int durationMins = 0,
    required this.status,
    this.pickupPolicy = PickupPolicy.nearby,
    required this.amenities,
    this.notes,
  }) : _fallbackDistanceKm = routeDistanceKm,
       _fallbackDurationMins = durationMins;

  double get routeDistanceKm =>
      route != null ? route!.distanceKm : _fallbackDistanceKm;

  int get durationMins =>
      route != null ? route!.durationMinutes : _fallbackDurationMins;

  factory RideModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve Driver details
    String driverId = '';
    String driverName = 'Driver';
    double driverRating = 4.8;
    String? driverPhoto;
    bool isDriverVerified = false;

    if (json['driver'] is Map<String, dynamic>) {
      final d = json['driver'] as Map<String, dynamic>;
      driverId = d['id'] ?? d['_id'] ?? '';
      driverName = d['name'] ?? d['fullName'] ?? 'Driver';
      driverRating = (d['rating'] as num?)?.toDouble() ?? 4.8;
      driverPhoto = d['profileImage'] ?? d['profilePhoto'];
      isDriverVerified = d['isVerified'] ?? d['isPhoneVerified'] ?? false;
    } else {
      driverId =
          json['driverId'] ?? (json['driver'] is String ? json['driver'] : '');
      driverName = json['driverName'] ?? 'Driver';
      driverRating = (json['driverRating'] as num?)?.toDouble() ?? 4.8;
      driverPhoto = json['driverPhoto'];
      isDriverVerified = json['isDriverVerified'] ?? false;
    }

    // 2. Resolve Vehicle
    VehicleModel vehicle;
    if (json['vehicle'] is Map<String, dynamic>) {
      vehicle = VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>);
    } else {
      vehicle = const VehicleModel(
        id: '',
        ownerId: '',
        make: 'Vehicle',
        model: '',
        year: 2022,
        color: '',
        registrationNumber: '',
        seatCapacity: 4,
        vehicleType: 'sedan',
        status: 'active',
      );
    }

    // 3. Resolve Route
    RouteInfo? routeInfo;
    if (json['route'] is Map<String, dynamic>) {
      routeInfo = RouteInfo.fromJson(json['route'] as Map<String, dynamic>);
    }

    // 4. Resolve Dates & Times
    DateTime parsedDateTime = DateTime.now();
    if (json['departureTime'] != null) {
      final tryDate = DateTime.tryParse(json['departureTime'].toString());
      if (tryDate != null) {
        parsedDateTime = tryDate;
      }
    } else if (json['dateTime'] != null) {
      parsedDateTime =
          DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now();
    }

    String depTimeStr = '';
    if (json['departureTime'] != null &&
        json['departureTime'].toString().contains(':') &&
        !json['departureTime'].toString().contains('T')) {
      depTimeStr = json['departureTime'].toString();
    } else {
      depTimeStr = DateFormat('hh:mm a').format(parsedDateTime);
    }

    String arrTimeStr = '';
    if (json['estimatedArrivalTime'] != null) {
      final tryArr = DateTime.tryParse(json['estimatedArrivalTime'].toString());
      if (tryArr != null) {
        arrTimeStr = DateFormat('hh:mm a').format(tryArr);
      } else {
        arrTimeStr = json['estimatedArrivalTime'].toString();
      }
    } else if (json['estimatedArrival'] != null) {
      arrTimeStr = json['estimatedArrival'].toString();
    } else if (routeInfo != null) {
      final arr = parsedDateTime.add(
        Duration(seconds: routeInfo.durationSeconds),
      );
      arrTimeStr = DateFormat('hh:mm a').format(arr);
    }

    // 5. Resolve Status
    final rawStatus = json['status'] as String? ?? 'scheduled';
    RideStatus rideStatus;
    switch (rawStatus) {
      case 'boarding':
        rideStatus = RideStatus.boarding;
        break;
      case 'inProgress':
      case 'active':
        rideStatus = RideStatus.active;
        break;
      case 'completed':
        rideStatus = RideStatus.completed;
        break;
      case 'cancelled':
        rideStatus = RideStatus.cancelled;
        break;
      case 'scheduled':
      default:
        rideStatus = RideStatus.scheduled;
    }

    // 6. Resolve Pickup Policy
    final rawPolicy = json['pickupPolicy'] as String? ?? 'nearby';
    final pickupPolicy = rawPolicy == 'exact'
        ? PickupPolicy.exact
        : PickupPolicy.nearby;

    return RideModel(
      id: json['id'] ?? json['_id'] ?? '',
      driverId: driverId,
      driverName: driverName,
      driverRating: driverRating,
      driverPhoto: driverPhoto,
      isDriverVerified: isDriverVerified,
      vehicle: vehicle,
      origin: LocationModel.fromJson(json['origin'] ?? {}),
      destination: LocationModel.fromJson(json['destination'] ?? {}),
      route: routeInfo,
      dateTime: parsedDateTime,
      departureTime: depTimeStr,
      estimatedArrival: arrTimeStr,
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 1,
      totalSeats: (json['totalSeats'] as num?)?.toInt() ?? vehicle.seatCapacity,
      bookedSeats: (json['bookedSeats'] as num?)?.toInt() ?? 0,
      contributionPerSeat:
          (json['contributionPerSeat'] as num?)?.toDouble() ?? 0.0,
      matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 100,
      routeDistanceKm:
          (json['routeDistanceKm'] as num?)?.toDouble() ??
          routeInfo?.distanceKm ??
          0.0,
      durationMins:
          (json['durationMins'] as num?)?.toInt() ??
          routeInfo?.durationMinutes ??
          0,
      status: rideStatus,
      pickupPolicy: pickupPolicy,
      amenities: List<String>.from(json['amenities'] ?? []),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'driverPhoto': driverPhoto,
      'isDriverVerified': isDriverVerified,
      'vehicle': vehicle.toJson(),
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      if (route != null) 'route': route!.toJson(),
      'dateTime': dateTime.toIso8601String(),
      'departureTime': departureTime,
      'estimatedArrival': estimatedArrival,
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'contributionPerSeat': contributionPerSeat,
      'matchPercentage': matchPercentage,
      'routeDistanceKm': routeDistanceKm,
      'durationMins': durationMins,
      'status': status.name,
      'pickupPolicy': pickupPolicy.name,
      'amenities': amenities,
      if (notes != null) 'notes': notes,
    };
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    double? driverRating,
    String? driverPhoto,
    bool? isDriverVerified,
    VehicleModel? vehicle,
    LocationModel? origin,
    LocationModel? destination,
    RouteInfo? route,
    DateTime? dateTime,
    String? departureTime,
    String? estimatedArrival,
    int? availableSeats,
    int? totalSeats,
    int? bookedSeats,
    double? contributionPerSeat,
    int? matchPercentage,
    double? routeDistanceKm,
    int? durationMins,
    RideStatus? status,
    PickupPolicy? pickupPolicy,
    List<String>? amenities,
    String? notes,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      isDriverVerified: isDriverVerified ?? this.isDriverVerified,
      vehicle: vehicle ?? this.vehicle,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      route: route ?? this.route,
      dateTime: dateTime ?? this.dateTime,
      departureTime: departureTime ?? this.departureTime,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      contributionPerSeat: contributionPerSeat ?? this.contributionPerSeat,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      durationMins: durationMins ?? this.durationMins,
      status: status ?? this.status,
      pickupPolicy: pickupPolicy ?? this.pickupPolicy,
      amenities: amenities ?? this.amenities,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    driverName,
    driverRating,
    driverPhoto,
    isDriverVerified,
    vehicle,
    origin,
    destination,
    route,
    dateTime,
    departureTime,
    estimatedArrival,
    availableSeats,
    totalSeats,
    bookedSeats,
    contributionPerSeat,
    matchPercentage,
    routeDistanceKm,
    durationMins,
    status,
    pickupPolicy,
    amenities,
    notes,
  ];
}
