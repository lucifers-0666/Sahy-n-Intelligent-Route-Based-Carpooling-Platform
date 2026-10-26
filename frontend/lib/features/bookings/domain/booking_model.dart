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
  final String? pin;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentTransactionId;
  final String? disputeStatus;
  final bool boardingPinLocked;
  final DateTime? boardedAt;
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
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.paymentTransactionId,
    this.disputeStatus,
    this.boardingPinLocked = false,
    this.boardedAt,
    this.passengerNote = '',
    required this.pickup,
    required this.drop,
    this.pin,
    required this.createdAt,
    this.updatedAt,
  });

  String get securityPin {
    if (pin != null && pin!.isNotEmpty) return pin!;
    if (id.isNotEmpty) {
      return (id.hashCode.abs() % 9000 + 1000).toString();
    }
    return '4821';
  }

  bool get isPending => status == BookingStatus.pending;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isAccepted => status == BookingStatus.accepted;
  bool get isRejected => status == BookingStatus.rejected;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isPaid =>
      paymentStatus == 'paid' || paymentStatus == 'escrow_released';

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
        return 'Booking Accepted';
      case BookingStatus.rejected:
        return 'Request Rejected';
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
    if (json['ride'] is Map) {
      resolvedRide = RideModel.fromJson(Map<String, dynamic>.from(json['ride'] as Map));
      resolvedRideId = resolvedRide.id.isNotEmpty
          ? resolvedRide.id
          : ((json['ride'] as Map)['_id']?.toString() ??
              (json['ride'] as Map)['id']?.toString() ??
              '');
    } else if (json['ride'] is String) {
      resolvedRideId = json['ride'] as String;
    }

    if (resolvedRideId.isEmpty && json['rideId'] != null) {
      resolvedRideId = json['rideId'].toString();
    }

    if (resolvedRide == null && json['rideDetails'] is Map) {
      resolvedRide = RideModel.fromJson(
        Map<String, dynamic>.from(json['rideDetails'] as Map),
      );
      if (resolvedRideId.isEmpty) {
        resolvedRideId = resolvedRide.id;
      }
    }

    if (resolvedRideId.isEmpty && resolvedRide != null) {
      resolvedRideId = resolvedRide.id;
    }

    // 2. Resolve passenger reference / populated object
    String resolvedPassengerId = '';
    UserModel? resolvedPassenger;
    if (json['passenger'] is Map) {
      resolvedPassenger = UserModel.fromJson(
        Map<String, dynamic>.from(json['passenger'] as Map),
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
    if (json['pickup'] is Map) {
      resolvedPickup = LocationModel.fromJson(
        Map<String, dynamic>.from(json['pickup'] as Map),
      );
    } else if (json['pickupLocation'] is Map) {
      resolvedPickup = LocationModel.fromJson(
        Map<String, dynamic>.from(json['pickupLocation'] as Map),
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
    if (json['drop'] is Map) {
      resolvedDrop = LocationModel.fromJson(
        Map<String, dynamic>.from(json['drop'] as Map),
      );
    } else if (json['dropLocation'] is Map) {
      resolvedDrop = LocationModel.fromJson(
        Map<String, dynamic>.from(json['dropLocation'] as Map),
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
        (json['seatsRequested'] as num?)?.toInt() ??
        (json['seats'] as num?)?.toInt() ??
        (json['seatCount'] as num?)?.toInt() ??
        1;

    final double perSeat =
        (json['contributionPerSeat'] as num?)?.toDouble() ??
        (resolvedRide != null ? resolvedRide.contributionPerSeat : 0.0);

    final double total =
        (json['totalContribution'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        (json['fare'] as num?)?.toDouble() ??
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
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      paymentStatus:
          (json['paymentStatus'] ?? json['payment_status'])?.toString() ??
          'pending',
      paymentTransactionId:
          (json['paymentTransactionId'] ?? json['payment_transaction_id'])
              ?.toString(),
      disputeStatus: (json['dispute'] is Map)
          ? (json['dispute'] as Map)['status']?.toString()
          : json['disputeStatus']?.toString(),
      boardingPinLocked: json['boardingPinLocked'] == true,
      boardedAt: DateTime.tryParse(json['boardedAt']?.toString() ?? ''),
      passengerNote: json['passengerNote']?.toString() ?? '',
      pickup: resolvedPickup,
      drop: resolvedDrop,
      pin: (json['boardingPin'] ??
              json['pin'] ??
              json['securityPin'] ??
              json['pickupPin'])
          ?.toString(),
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
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (paymentTransactionId != null)
        'paymentTransactionId': paymentTransactionId,
      if (disputeStatus != null) 'disputeStatus': disputeStatus,
      'boardingPinLocked': boardingPinLocked,
      if (boardedAt != null) 'boardedAt': boardedAt!.toIso8601String(),
      'passengerNote': passengerNote,
      'pickup': pickup.toJson(),
      'drop': drop.toJson(),
      if (pin != null) 'pin': pin,
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
    paymentMethod,
    paymentStatus,
    paymentTransactionId,
    disputeStatus,
    boardingPinLocked,
    boardedAt,
    passengerNote,
    pickup,
    drop,
    pin,
    createdAt,
    updatedAt,
  ];
}
