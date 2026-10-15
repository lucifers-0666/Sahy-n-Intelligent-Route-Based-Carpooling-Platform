import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/data/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VehicleRepositoryImpl(apiClient: apiClient);
});

class VehiclesNotifier extends AsyncNotifier<List<VehicleModel>> {
  @override
  Future<List<VehicleModel>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.token == null) {
      return const [];
    }
    final repository = ref.read(vehicleRepositoryProvider);
    return await repository.getVehicles();
  }

  Future<VehicleModel> addVehicle({
    required String registrationNumber,
    required String vehicleType,
    required String make,
    required String model,
    required int year,
    required String color,
    required int seatCapacity,
    String? vehicleImage,
  }) async {
    final repository = ref.read(vehicleRepositoryProvider);
    final result = await repository.createVehicle(
      registrationNumber: registrationNumber,
      vehicleType: vehicleType,
      make: make,
      model: model,
      year: year,
      color: color,
      seatCapacity: seatCapacity,
      vehicleImage: vehicleImage,
    );

    final newVehicle = result['vehicle'] as VehicleModel;
    final userData = result['user'];

    // Update state with new vehicle
    final currentList = state.value ?? [];
    state = AsyncData([newVehicle, ...currentList]);

    // Update authenticated user capability in Riverpod state
    if (userData is Map<String, dynamic>) {
      final updatedUser = UserModel.fromJson(userData);
      ref.read(authProvider.notifier).updateUser(updatedUser);
    } else {
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(
              currentUser.copyWith(
                canDrive: true,
                driverOnboardingStatus: 'approved',
              ),
            );
      }
    }

    return newVehicle;
  }

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
    final repository = ref.read(vehicleRepositoryProvider);
    final updated = await repository.updateVehicle(
      id: id,
      registrationNumber: registrationNumber,
      vehicleType: vehicleType,
      make: make,
      model: model,
      year: year,
      color: color,
      seatCapacity: seatCapacity,
      vehicleImage: vehicleImage,
      status: status,
    );

    final currentList = state.value ?? [];
    state = AsyncData(
      currentList.map((v) => v.id == id ? updated : v).toList(),
    );

    return updated;
  }

  Future<void> deleteVehicle(String id) async {
    final repository = ref.read(vehicleRepositoryProvider);
    final result = await repository.deleteVehicle(id);

    final currentList = state.value ?? [];
    final updatedList = currentList.where((v) => v.id != id).toList();
    state = AsyncData(updatedList);

    // If no vehicles remain, update driver eligibility
    final userData = result['user'];
    if (userData is Map<String, dynamic>) {
      final updatedUser = UserModel.fromJson(userData);
      ref.read(authProvider.notifier).updateUser(updatedUser);
    } else if (updatedList.isEmpty) {
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(
              currentUser.copyWith(
                canDrive: false,
                driverOnboardingStatus: 'not_started',
              ),
            );
      }
    }
  }

  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.token == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(vehicleRepositoryProvider);
      return await repository.getVehicles();
    });
  }
}

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<VehicleModel>>(() {
      return VehiclesNotifier();
    });
