import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';

abstract class VehicleRepository {
  Future<List<VehicleModel>> getVehicles();
  Future<VehicleModel> getVehicleById(String id);
  Future<Map<String, dynamic>> createVehicle({
    required String registrationNumber,
    required String vehicleType,
    required String make,
    required String model,
    required int year,
    required String color,
    required int seatCapacity,
    String? vehicleImage,
  });
  Future<VehicleModel> updateVehicle({
    required String id,
    String? registrationNumber,
    String? vehicleType,
    String? make,
    String? model,
    int? year,
    String? color,
    int? seatCapacity,
    String? vehicleImage,
    String? status,
  });
  Future<Map<String, dynamic>> deleteVehicle(String id);
}

class VehicleRepositoryImpl implements VehicleRepository {
  final ApiClient apiClient;

  VehicleRepositoryImpl({required this.apiClient});

  @override
  Future<List<VehicleModel>> getVehicles() async {
    final response = await apiClient.get('/vehicles');
    if (response is Map<String, dynamic>) {
      final dynamic rawList = response['vehicles'] ??
          (response['data'] is Map ? response['data']['vehicles'] : null) ??
          (response['data'] is List ? response['data'] : null);
      if (rawList is List<dynamic>) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((json) => VehicleModel.fromJson(json))
            .toList();
      }
    }
    return [];
  }

  @override
  Future<VehicleModel> getVehicleById(String id) async {
    final response = await apiClient.get('/vehicles/$id');
    if (response is Map<String, dynamic> && response.containsKey('vehicle')) {
      return VehicleModel.fromJson(response['vehicle'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to retrieve vehicle details.');
  }

  @override
  Future<Map<String, dynamic>> createVehicle({
    required String registrationNumber,
    required String vehicleType,
    required String make,
    required String model,
    required int year,
    required String color,
    required int seatCapacity,
    String? vehicleImage,
  }) async {
    final response = await apiClient.post(
      '/vehicles',
      body: {
        'registrationNumber': registrationNumber,
        'vehicleType': vehicleType,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'seatCapacity': seatCapacity,
        if (vehicleImage != null && vehicleImage.isNotEmpty)
          'vehicleImage': vehicleImage,
      },
    );

    if (response is Map<String, dynamic> && response.containsKey('vehicle')) {
      final vehicle = VehicleModel.fromJson(
        response['vehicle'] as Map<String, dynamic>,
      );
      return {'vehicle': vehicle, 'user': response['user']};
    }
    throw ApiException(
      response is Map && response.containsKey('message')
          ? response['message'].toString()
          : 'Failed to create vehicle.',
    );
  }

  @override
  Future<VehicleModel> updateVehicle({
    required String id,
    String? registrationNumber,
    String? vehicleType,
    String? make,
    String? model,
    int? year,
    String? color,
    int? seatCapacity,
    String? vehicleImage,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (registrationNumber != null) {
      body['registrationNumber'] = registrationNumber;
    }
    if (vehicleType != null) {
      body['vehicleType'] = vehicleType;
    }
    if (make != null) {
      body['make'] = make;
    }
    if (model != null) {
      body['model'] = model;
    }
    if (year != null) {
      body['year'] = year;
    }
    if (color != null) {
      body['color'] = color;
    }
    if (seatCapacity != null) {
      body['seatCapacity'] = seatCapacity;
    }
    if (vehicleImage != null) {
      body['vehicleImage'] = vehicleImage;
    }
    if (status != null) {
      body['status'] = status;
    }

    final response = await apiClient.put('/vehicles/$id', body: body);
    if (response is Map<String, dynamic> && response.containsKey('vehicle')) {
      return VehicleModel.fromJson(response['vehicle'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update vehicle details.');
  }

  @override
  Future<Map<String, dynamic>> deleteVehicle(String id) async {
    final response = await apiClient.delete('/vehicles/$id');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }
}
