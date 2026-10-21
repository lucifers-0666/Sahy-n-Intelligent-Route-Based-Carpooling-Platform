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
    final dist = json['distanceMeters'];
    final dur = json['durationSeconds'];
    return RouteInfo(
      encodedPolyline: json['encodedPolyline']?.toString() ?? '',
      distanceMeters: dist is num
          ? dist.toDouble()
          : (double.tryParse(dist?.toString() ?? '') ?? 0.0),
      durationSeconds: dur is num
          ? dur.toInt()
          : (int.tryParse(dur?.toString() ?? '') ?? 0),
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
  final List<LocationModel> stopovers;
  final List<String> breakDisclosures;

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
    this.stopovers = const [],
    this.breakDisclosures = const [],
  }) : _fallbackDistanceKm = routeDistanceKm,
       _fallbackDurationMins = durationMins;

  double get routeDistanceKm =>
      route != null ? route!.distanceKm : _fallbackDistanceKm;

  int get durationMins =>
      route != null ? route!.durationMinutes : _fallbackDurationMins;

  bool get isScheduled => status == RideStatus.scheduled;
  bool get isBoarding => status == RideStatus.boarding;
  bool get isActive => status == RideStatus.active;
  bool get isCompleted => status == RideStatus.completed;
  bool get isCancelled => status == RideStatus.cancelled;

  String get statusDisplayName {
    switch (status) {
      case RideStatus.scheduled:
        return 'Scheduled';
      case RideStatus.boarding:
        return 'Boarding';
      case RideStatus.active:
        return 'Trip in Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  static double _parseRating(dynamic raw) {
    if (raw == null) return 4.8;
    if (raw is num) return raw.toDouble();
    if (raw is Map) {
      final avg = raw['average'] ?? raw['rating'] ?? raw['score'];
      if (avg is num) return avg.toDouble();
      if (avg is String) return double.tryParse(avg) ?? 4.8;
    }
    if (raw is String) return double.tryParse(raw) ?? 4.8;
    return 4.8;
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve Driver details
    String driverId = '';
    String driverName = 'Driver';
    double driverRating = 4.8;
    String? driverPhoto;
    bool isDriverVerified = false;

    if (json['driver'] is Map) {
      final d = json['driver'] as Map;
      driverId = d['id']?.toString() ?? d['_id']?.toString() ?? '';
      driverName = d['name']?.toString() ?? d['fullName']?.toString() ?? 'Driver';
      driverRating = _parseRating(d['rating']);
      driverPhoto = d['profileImage']?.toString() ?? d['profilePhoto']?.toString();
      isDriverVerified = d['isVerified'] == true ||
          d['isPhoneVerified'] == true ||
          d['isIdentityVerified'] == true;
    } else {
      driverId = json['driverId']?.toString() ??
          (json['driver'] is String ? json['driver'] as String : '');
      driverName = json['driverName']?.toString() ?? 'Driver';
      driverRating = _parseRating(json['driverRating']);
      driverPhoto = json['driverPhoto']?.toString();
      isDriverVerified = json['isDriverVerified'] == true;
    }

    // 2. Resolve Vehicle
    VehicleModel vehicle;
    if (json['vehicle'] is Map) {
      vehicle = VehicleModel.fromJson(
        Map<String, dynamic>.from(json['vehicle'] as Map),
      );
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
    if (json['route'] is Map) {
      routeInfo = RouteInfo.fromJson(
        Map<String, dynamic>.from(json['route'] as Map),
      );
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
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      driverId: driverId,
      driverName: driverName,
      driverRating: driverRating,
      driverPhoto: driverPhoto,
      isDriverVerified: isDriverVerified,
      vehicle: vehicle,
      origin: LocationModel.fromJson(
        json['origin'] is Map
            ? Map<String, dynamic>.from(json['origin'] as Map)
            : {},
      ),
      destination: LocationModel.fromJson(
        json['destination'] is Map
            ? Map<String, dynamic>.from(json['destination'] as Map)
            : {},
      ),
      route: routeInfo,
      dateTime: parsedDateTime,
      departureTime: depTimeStr,
      estimatedArrival: arrTimeStr,
      availableSeats: _parseInt(json['availableSeats'], 1),
      totalSeats: _parseInt(json['totalSeats'], vehicle.seatCapacity),
      bookedSeats: _parseInt(json['bookedSeats'], 0),
      contributionPerSeat: _parseDouble(
        json['contributionPerSeat'] ?? json['pricePerSeat'],
        0.0,
      ),
      matchPercentage: _parseInt(json['matchPercentage'], 100),
      routeDistanceKm: _parseDouble(
        json['routeDistanceKm'],
        routeInfo?.distanceKm ?? 0.0,
      ),
      durationMins: _parseInt(
        json['durationMins'],
        routeInfo?.durationMinutes ?? 0,
      ),
      status: rideStatus,
      pickupPolicy: pickupPolicy,
      amenities: (json['amenities'] is List)
          ? (json['amenities'] as List).map((a) => a.toString()).toList()
          : const [],
      notes: json['notes'] as String?,
      stopovers: (json['stopovers'] is List)
          ? (json['stopovers'] as List)
              .whereType<Map>()
              .map((s) => LocationModel.fromJson(Map<String, dynamic>.from(s)))
              .toList()
          : const [],
      breakDisclosures: (json['breakDisclosures'] is List)
          ? (json['breakDisclosures'] as List)
              .map((b) => b.toString())
              .toList()
          : const [],
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
      'stopovers': stopovers.map((s) => s.toJson()).toList(),
      'breakDisclosures': breakDisclosures,
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
    List<LocationModel>? stopovers,
    List<String>? breakDisclosures,
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
      stopovers: stopovers ?? this.stopovers,
      breakDisclosures: breakDisclosures ?? this.breakDisclosures,
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
    stopovers,
    breakDisclosures,
  ];
}
