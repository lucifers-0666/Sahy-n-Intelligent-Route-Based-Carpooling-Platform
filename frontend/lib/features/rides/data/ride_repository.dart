import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

abstract class RideRepository {
  Future<RideModel> createRide({
    required String vehicleId,
    required LocationModel origin,
    required LocationModel destination,
    required RouteInfo route,
    required DateTime departureTime,
    DateTime? estimatedArrivalTime,
    required int availableSeats,
    required double contributionPerSeat,
    String pickupPolicy = 'nearby',
    List<String> amenities = const [],
    String? notes,
  });

  Future<List<RideModel>> getMyRides({String? status});

  Future<RideModel> getRideById(String id);

  Future<RideModel> cancelRide(String id);

  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
  });

  Future<List<RideSearchResult>> searchRides({
    LocationModel? origin,
    LocationModel? destination,
    String? originText,
    String? destinationText,
    DateTime? departureDate,
    int seats = 1,
    double maxPickupDistanceKm = 30,
    double maxDropDistanceKm = 30,
    int timeWindowHours = 4,
    String? pickupPolicy,
    double? minContribution,
    double? maxContribution,
  });
}

class RideRepositoryImpl implements RideRepository {
  final ApiClient apiClient;

  RideRepositoryImpl({required this.apiClient});

  @override
  Future<RideModel> createRide({
    required String vehicleId,
    required LocationModel origin,
    required LocationModel destination,
    required RouteInfo route,
    required DateTime departureTime,
    DateTime? estimatedArrivalTime,
    required int availableSeats,
    required double contributionPerSeat,
    String pickupPolicy = 'nearby',
    List<String> amenities = const [],
    String? notes,
  }) async {
    final payload = {
      'vehicleId': vehicleId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'route': route.toJson(),
      'departureTime': departureTime.toIso8601String(),
      if (estimatedArrivalTime != null)
        'estimatedArrivalTime': estimatedArrivalTime.toIso8601String(),
      'availableSeats': availableSeats,
      'contributionPerSeat': contributionPerSeat,
      'pickupPolicy': pickupPolicy,
      'amenities': amenities,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await apiClient.post('/rides', body: payload);

    if (response is Map<String, dynamic> && response['ride'] != null) {
      return RideModel.fromJson(response['ride'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to create ride. Invalid server response.');
  }

  @override
  Future<List<RideModel>> getMyRides({String? status}) async {
    final path = status != null ? '/rides/my?status=$status' : '/rides/my';
    final response = await apiClient.get(path);

    if (response is Map<String, dynamic> && response['rides'] is List) {
      final list = response['rides'] as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => RideModel.fromJson(json))
          .toList();
    }

    return [];
  }

  @override
  Future<RideModel> getRideById(String id) async {
    final response = await apiClient.get('/rides/$id');

    if (response is Map<String, dynamic> && response['ride'] != null) {
      return RideModel.fromJson(response['ride'] as Map<String, dynamic>);
    }

    throw ApiException('Ride not found.');
  }

  @override
  Future<RideModel> cancelRide(String id) async {
    final response = await apiClient.patch('/rides/$id/cancel', body: {});

    if (response is Map<String, dynamic> && response['ride'] != null) {
      return RideModel.fromJson(response['ride'] as Map<String, dynamic>);
    }

    throw ApiException('Failed to cancel ride.');
  }

  @override
  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
  }) async {
    try {
      final response = await apiClient.post(
        '/rides/calculate-route',
        body: {'origin': origin.toJson(), 'destination': destination.toJson()},
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return RouteInfo(
          encodedPolyline: response['encodedPolyline'] as String? ?? '',
          distanceMeters:
              (response['distanceMeters'] as num?)?.toDouble() ?? 0.0,
          durationSeconds: (response['durationSeconds'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {
      // Backend routing service is either offline or Google Maps key not yet set.
      // Compute direct baseline route for local development & preview.
    }

    // Baseline local route calculation (Haversine distance + estimated 60 km/h driving speed)
    final distanceMeters = RouteService.calculateDistanceMeters(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Add 20% road curvature factor over straight-line Haversine
    final adjustedDistanceMeters = distanceMeters * 1.20;
    // Average driving speed: 60 km/h (16.67 m/s)
    final durationSeconds = (adjustedDistanceMeters / 16.67).round();

    // Create polyline connecting origin and destination
    final encodedPolyline = RouteService.encodePolyline([
      LatLngPoint(origin.latitude, origin.longitude),
      LatLngPoint(
        (origin.latitude + destination.latitude) / 2 + 0.01,
        (origin.longitude + destination.longitude) / 2 + 0.01,
      ),
      LatLngPoint(destination.latitude, destination.longitude),
    ]);

    return RouteInfo(
      encodedPolyline: encodedPolyline,
      distanceMeters: adjustedDistanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Future<List<RideSearchResult>> searchRides({
    LocationModel? origin,
    LocationModel? destination,
    String? originText,
    String? destinationText,
    DateTime? departureDate,
    int seats = 1,
    double maxPickupDistanceKm = 30,
    double maxDropDistanceKm = 30,
    int timeWindowHours = 4,
    String? pickupPolicy,
    double? minContribution,
    double? maxContribution,
  }) async {
    final queryParams = <String, String>{
      'seats': seats.toString(),
      'maxPickupDistanceKm': maxPickupDistanceKm.toString(),
      'maxDropDistanceKm': maxDropDistanceKm.toString(),
      'timeWindowHours': timeWindowHours.toString(),
    };

    if (origin != null && origin.latitude != 0.0 && origin.longitude != 0.0) {
      queryParams['originLat'] = origin.latitude.toString();
      queryParams['originLng'] = origin.longitude.toString();
    }
    final oText =
        originText ??
        (origin?.name.isNotEmpty == true ? origin?.name : origin?.city);
    if (oText != null && oText.isNotEmpty) {
      queryParams['originText'] = oText;
    }

    if (destination != null &&
        destination.latitude != 0.0 &&
        destination.longitude != 0.0) {
      queryParams['destLat'] = destination.latitude.toString();
      queryParams['destLng'] = destination.longitude.toString();
    }
    final dText =
        destinationText ??
        (destination?.name.isNotEmpty == true
            ? destination?.name
            : destination?.city);
    if (dText != null && dText.isNotEmpty) {
      queryParams['destText'] = dText;
    }

    if (departureDate != null) {
      queryParams['departureDate'] = departureDate.toIso8601String();
    }

    if (pickupPolicy != null && pickupPolicy.isNotEmpty) {
      queryParams['pickupPolicy'] = pickupPolicy;
    }

    if (minContribution != null) {
      queryParams['minContribution'] = minContribution.toString();
    }

    if (maxContribution != null) {
      queryParams['maxContribution'] = maxContribution.toString();
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isNotEmpty
        ? '/rides/search?$queryString'
        : '/rides/search';
    final response = await apiClient.get(path);

    if (response is Map<String, dynamic> && response['results'] is List) {
      final list = response['results'] as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => RideSearchResult.fromJson(json))
          .toList();
    }

    return [];
  }
}
