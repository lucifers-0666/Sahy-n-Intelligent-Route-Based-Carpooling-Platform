import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class MockBookingsRepository implements BookingsRepository {
  static final List<BookingModel> _mockBookings = [];

  @override
  Future<BookingModel> createBooking({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final total = requestedSeats * 250.0;

    final booking = BookingModel(
      id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
      rideId: rideId,
      passengerId: 'usr_mock_passenger',
      requestedSeats: requestedSeats,
      contributionPerSeat: 250.0,
      totalContribution: total,
      status: BookingStatus.pending,
      passengerNote: passengerNote ?? '',
      pickup:
          pickup ??
          LocationModel.fromCoordinates(
            name: 'Origin',
            latitude: 23.24,
            longitude: 69.66,
          ),
      drop:
          drop ??
          LocationModel.fromCoordinates(
            name: 'Destination',
            latitude: 23.02,
            longitude: 72.57,
          ),
      createdAt: DateTime.now(),
    );

    _mockBookings.insert(0, booking);
    return booking;
  }

  // Backwards compatibility method for old prototype confirm_pay_screen
  Future<BookingModel> confirmBooking({
    required RideModel ride,
    required String passengerId,
    required String passengerName,
    required List<String> selectedSeats,
  }) async {
    final booking = await createBooking(
      rideId: ride.id,
      requestedSeats: selectedSeats.length,
      pickup: ride.origin,
      drop: ride.destination,
    );
    return booking;
  }

  @override
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (status != null && status.isNotEmpty && status != 'all') {
      return _mockBookings.where((b) => b.status.name == status).toList();
    }
    return List.from(_mockBookings);
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockBookings.firstWhere(
      (b) => b.id == id,
      orElse: () => throw Exception('Booking not found'),
    );
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockBookings.indexWhere((b) => b.id == id);
    if (index == -1) throw Exception('Booking not found');

    final old = _mockBookings[index];
    final updated = BookingModel(
      id: old.id,
      rideId: old.rideId,
      ride: old.ride,
      passengerId: old.passengerId,
      passenger: old.passenger,
      requestedSeats: old.requestedSeats,
      contributionPerSeat: old.contributionPerSeat,
      totalContribution: old.totalContribution,
      status: BookingStatus.cancelled,
      passengerNote: old.passengerNote,
      pickup: old.pickup,
      drop: old.drop,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    _mockBookings[index] = updated;
    return updated;
  }
}
