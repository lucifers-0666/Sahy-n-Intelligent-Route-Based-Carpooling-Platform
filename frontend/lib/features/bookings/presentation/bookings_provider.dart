import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingsRepositoryImpl(apiClient: apiClient);
});

// Selected filter for My Bookings screen: 'all', 'pending', 'cancelled'
final bookingStatusFilterProvider = StateProvider<String>((ref) => 'all');

class BookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final BookingsRepository repository;

  BookingsNotifier(this.repository) : super(const AsyncValue.data([]));

  Future<void> fetchMyBookings({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final filterStatus = (status == null || status == 'all') ? null : status;
      final bookings = await repository.getMyBookings(status: filterStatus);
      if (!mounted) return;
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<BookingModel> createBookingRequest({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  }) async {
    final booking = await repository.createBooking(
      rideId: rideId,
      requestedSeats: requestedSeats,
      passengerNote: passengerNote,
      pickup: pickup,
      drop: drop,
    );

    // Refresh list in background
    fetchMyBookings();
    return booking;
  }

  // Backwards compatibility method for older prototype
  Future<BookingModel> confirmBooking({
    required RideModel ride,
    required String passengerId,
    required String passengerName,
    required List<String> selectedSeats,
  }) async {
    return createBookingRequest(
      rideId: ride.id,
      requestedSeats: selectedSeats.length,
      pickup: ride.origin,
      drop: ride.destination,
    );
  }

  Future<BookingModel> cancelBooking(String bookingId) async {
    final updated = await repository.cancelBooking(bookingId);

    if (!mounted) return updated;

    // Update in-memory state
    state.whenData((bookings) {
      final updatedList = bookings.map((b) {
        if (b.id == bookingId) {
          return updated;
        }
        return b;
      }).toList();
      state = AsyncValue.data(updatedList);
    });

    return updated;
  }
}

final bookingsNotifierProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>((
      ref,
    ) {
      final repo = ref.watch(bookingsRepositoryProvider);
      final notifier = BookingsNotifier(repo);
      // Auto-fetch if authenticated
      final authState = ref.watch(authProvider);
      if (authState.isAuthenticated) {
        notifier.fetchMyBookings();
      }
      return notifier;
    });

final selectedBookingProvider = StateProvider<BookingModel?>((ref) => null);

// Backwards compatibility alias
final activeBookingProvider = selectedBookingProvider;

// Selected filter for Driver Requests screen: 'all', 'pending', 'accepted', 'rejected'
final driverRequestsFilterProvider = StateProvider<String>((ref) => 'all');

class DriverRequestsNotifier
    extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final BookingsRepository repository;

  DriverRequestsNotifier(this.repository) : super(const AsyncValue.data([]));

  Future<void> fetchDriverRequests({String? status, String? rideId}) async {
    state = const AsyncValue.loading();
    try {
      final filterStatus = (status == null || status == 'all') ? null : status;
      final requests = await repository.getDriverBookingRequests(
        status: filterStatus,
        rideId: rideId,
      );
      if (!mounted) return;
      state = AsyncValue.data(requests);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<BookingModel> acceptRequest(String bookingId) async {
    final updated = await repository.acceptBooking(bookingId);
    if (!mounted) return updated;

    state.whenData((requests) {
      final updatedList = requests.map((b) {
        if (b.id == bookingId) {
          return updated;
        }
        return b;
      }).toList();
      state = AsyncValue.data(updatedList);
    });

    return updated;
  }

  Future<BookingModel> rejectRequest(String bookingId) async {
    final updated = await repository.rejectBooking(bookingId);
    if (!mounted) return updated;

    state.whenData((requests) {
      final updatedList = requests.map((b) {
        if (b.id == bookingId) {
          return updated;
        }
        return b;
      }).toList();
      state = AsyncValue.data(updatedList);
    });

    return updated;
  }
}

final driverRequestsNotifierProvider =
    StateNotifierProvider<
      DriverRequestsNotifier,
      AsyncValue<List<BookingModel>>
    >((ref) {
      final repo = ref.watch(bookingsRepositoryProvider);
      final notifier = DriverRequestsNotifier(repo);
      final authState = ref.watch(authProvider);
      if (authState.isAuthenticated) {
        notifier.fetchDriverRequests();
      }
      return notifier;
    });

final selectedDriverRequestProvider = StateProvider<BookingModel?>(
  (ref) => null,
);
