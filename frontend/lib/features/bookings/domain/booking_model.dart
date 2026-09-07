import 'package:equatable/equatable.dart';
import '../../../shared/models/location_model.dart';
import '../../../shared/models/ride_model.dart';
import '../../../shared/models/user_model.dart';

enum BookingStatus { pending, accepted, rejected, cancelled, completed }

class BookingModel extends Equatable {
  final String id;
  final String rideId;
  final RideModel? ride;
  final String passengerId;
  final UserModel? passenger;
  final int requestedSeats;
  final double contributionPerSeat;
  final double totalContribution;
  final BookingStatus status;
  final String passengerNote;
  final LocationModel pickup;
  final LocationModel drop;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.rideId,
    this.ride,
    required this.passengerId,
    this.passenger,
    required this.requestedSeats,
    required this.contributionPerSeat,
    required this.totalContribution,
    required this.status,
    this.passengerNote = '',
    required this.pickup,
    required this.drop,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == BookingStatus.pending;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isAccepted => status == BookingStatus.accepted;

  // Backwards compatibility getters
  int get seatCount => requestedSeats;
  double get totalAmount => totalContribution;
  double get contributionAmount => totalContribution;
  double get platformFee => 0.0;
  RideModel? get rideDetails => ride;
  List<String> get selectedSeats =>
      List.generate(requestedSeats, (i) => 'Seat ${i + 1}');
  String get passengerName => passenger?.name ?? 'Passenger';
  LocationModel get pickupLocation => pickup;
  LocationModel get dropLocation => drop;
  BookingStatus get bookingStatus => status;
  DateTime get requestedAt => createdAt;

  String get statusDisplayName {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Driver Approval';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.rejected:
        return 'Declined';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve ride reference / populated object
    String resolvedRideId = '';
    RideModel? resolvedRide;
    if (json['ride'] is Map<String, dynamic>) {
      resolvedRide = RideModel.fromJson(json['ride'] as Map<String, dynamic>);
      resolvedRideId = resolvedRide.id;
    } else if (json['ride'] is String) {
      resolvedRideId = json['ride'] as String;
    } else if (json['rideId'] != null) {
      resolvedRideId = json['rideId'].toString();
    } else if (json['rideDetails'] is Map<String, dynamic>) {
      resolvedRide = RideModel.fromJson(
        json['rideDetails'] as Map<String, dynamic>,
      );
      resolvedRideId = resolvedRide.id;
    }

    // 2. Resolve passenger reference / populated object
    String resolvedPassengerId = '';
    UserModel? resolvedPassenger;
    if (json['passenger'] is Map<String, dynamic>) {
      resolvedPassenger = UserModel.fromJson(
        json['passenger'] as Map<String, dynamic>,
      );
      resolvedPassengerId = resolvedPassenger.id;
    } else if (json['passenger'] is String) {
      resolvedPassengerId = json['passenger'] as String;
    } else if (json['passengerId'] != null) {
      resolvedPassengerId = json['passengerId'].toString();
    }

    // 3. Resolve status
    final rawStatus =
        (json['status'] ?? json['bookingStatus'])?.toString().toLowerCase() ??
        'pending';
    final parsedStatus = BookingStatus.values.firstWhere(
      (e) => e.name == rawStatus,
      orElse: () => BookingStatus.pending,
    );

    // 4. Resolve pickup & drop
    LocationModel resolvedPickup;
    if (json['pickup'] is Map<String, dynamic>) {
      resolvedPickup = LocationModel.fromJson(
        json['pickup'] as Map<String, dynamic>,
      );
    } else if (json['pickupLocation'] is Map<String, dynamic>) {
      resolvedPickup = LocationModel.fromJson(
        json['pickupLocation'] as Map<String, dynamic>,
      );
    } else if (resolvedRide != null) {
      resolvedPickup = resolvedRide.origin;
    } else {
      resolvedPickup = LocationModel.fromCoordinates(
        name: 'Origin',
        latitude: 0,
        longitude: 0,
      );
    }

    LocationModel resolvedDrop;
    if (json['drop'] is Map<String, dynamic>) {
      resolvedDrop = LocationModel.fromJson(
        json['drop'] as Map<String, dynamic>,
      );
    } else if (json['dropLocation'] is Map<String, dynamic>) {
      resolvedDrop = LocationModel.fromJson(
        json['dropLocation'] as Map<String, dynamic>,
      );
    } else if (resolvedRide != null) {
      resolvedDrop = resolvedRide.destination;
    } else {
      resolvedDrop = LocationModel.fromCoordinates(
        name: 'Destination',
        latitude: 0,
        longitude: 0,
      );
    }

    final int seats =
        (json['requestedSeats'] as num?)?.toInt() ??
        (json['seatCount'] as num?)?.toInt() ??
        1;

    final double perSeat =
        (json['contributionPerSeat'] as num?)?.toDouble() ??
        (resolvedRide != null ? resolvedRide.contributionPerSeat : 0.0);

    final double total =
        (json['totalContribution'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        (seats * perSeat);

    return BookingModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      rideId: resolvedRideId,
      ride: resolvedRide,
      passengerId: resolvedPassengerId,
      passenger: resolvedPassenger,
      requestedSeats: seats,
      contributionPerSeat: perSeat,
      totalContribution: total,
      status: parsedStatus,
      passengerNote: json['passengerNote']?.toString() ?? '',
      pickup: resolvedPickup,
      drop: resolvedDrop,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['requestedAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      if (ride != null) 'ride': ride!.toJson(),
      'passengerId': passengerId,
      if (passenger != null) 'passenger': passenger!.toJson(),
      'requestedSeats': requestedSeats,
      'contributionPerSeat': contributionPerSeat,
      'totalContribution': totalContribution,
      'status': status.name,
      'passengerNote': passengerNote,
      'pickup': pickup.toJson(),
      'drop': drop.toJson(),
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    rideId,
    ride,
    passengerId,
    passenger,
    requestedSeats,
    contributionPerSeat,
    totalContribution,
    status,
    passengerNote,
    pickup,
    drop,
    createdAt,
    updatedAt,
  ];
}
