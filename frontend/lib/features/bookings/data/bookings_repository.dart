import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/shared/models/location_model.dart';

abstract class BookingsRepository {
  Future<BookingModel> createBooking({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  });

  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  });

  Future<BookingModel> getBookingById(String id);

  Future<BookingModel> cancelBooking(String id);

  Future<List<BookingModel>> getDriverBookingRequests({
    String? status,
    String? rideId,
    int page = 1,
    int limit = 50,
  });

  Future<BookingModel> acceptBooking(String id);

  Future<BookingModel> rejectBooking(String id);
}

class BookingsRepositoryImpl implements BookingsRepository {
  final ApiClient apiClient;

  BookingsRepositoryImpl({required this.apiClient});

  @override
  Future<BookingModel> createBooking({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  }) async {
    final payload = {
      'rideId': rideId,
      'requestedSeats': requestedSeats,
      if (passengerNote != null && passengerNote.trim().isNotEmpty)
        'passengerNote': passengerNote.trim(),
      if (pickup != null) 'pickup': pickup.toJson(),
      if (drop != null) 'drop': drop.toJson(),
    };

    final response = await apiClient.post('/bookings', body: payload);

    if (response is Map<String, dynamic> && response['data'] != null) {
      return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to create booking. Invalid server response.');
  }

  @override
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String>[];
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=$status');
    }
    queryParams.add('page=$page');
    queryParams.add('limit=$limit');

    final queryString = queryParams.join('&');
    final response = await apiClient.get('/bookings/my?$queryString');

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => BookingModel.fromJson(json))
          .toList();
    }

    return [];
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    final response = await apiClient.get('/bookings/$id');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Booking not found or invalid server response.');
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    final response = await apiClient.patch('/bookings/$id/cancel');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to cancel booking. Invalid server response.');
  }

  @override
  Future<List<BookingModel>> getDriverBookingRequests({
    String? status,
    String? rideId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String>[];
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=$status');
    }
    if (rideId != null && rideId.isNotEmpty) {
      queryParams.add('rideId=$rideId');
    }
    queryParams.add('page=$page');
    queryParams.add('limit=$limit');

    final queryString = queryParams.join('&');
    final response = await apiClient.get(
      '/bookings/driver/requests?$queryString',
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => BookingModel.fromJson(json))
          .toList();
    }

    return [];
  }

  @override
  Future<BookingModel> acceptBooking(String id) async {
    final response = await apiClient.patch('/bookings/$id/accept');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to accept booking. Invalid server response.');
  }

  @override
  Future<BookingModel> rejectBooking(String id) async {
    final response = await apiClient.patch('/bookings/$id/reject');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to reject booking. Invalid server response.');
  }
}
