import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/rides/data/ride_repository.dart';

import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

import 'package:sahyan/features/rides/domain/ride_search_result.dart';

// Live backend API repository for rides
final rideApiRepositoryProvider = Provider<RideRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RideRepositoryImpl(apiClient: apiClient);
});

// Backward compatibility alias
final ridesRepositoryProvider = rideApiRepositoryProvider;

// --- Search Query State ---
class RideSearchQuery {
  final LocationModel? originLocation;
  final LocationModel? destinationLocation;
  final String origin;
  final String destination;
  final DateTime date;
  final TimeOfDay? time;
  final int seats;
  final double maxPickupDistanceKm;
  final double maxDropDistanceKm;
  final int timeWindowHours;
  final String? pickupPolicy;
  final double? minContribution;
  final double? maxContribution;

  RideSearchQuery({
    this.originLocation,
    this.destinationLocation,
    required this.origin,
    required this.destination,
    required this.date,
    this.time,
    this.seats = 1,
    this.maxPickupDistanceKm = 30.0,
    this.maxDropDistanceKm = 30.0,
    this.timeWindowHours = 4,
    this.pickupPolicy,
    this.minContribution,
    this.maxContribution,
  });

  RideSearchQuery copyWith({
    LocationModel? originLocation,
    LocationModel? destinationLocation,
    String? origin,
    String? destination,
    DateTime? date,
    TimeOfDay? time,
    int? seats,
    double? maxPickupDistanceKm,
    double? maxDropDistanceKm,
    int? timeWindowHours,
    String? pickupPolicy,
    double? minContribution,
    double? maxContribution,
  }) {
    return RideSearchQuery(
      originLocation: originLocation ?? this.originLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      time: time ?? this.time,
      seats: seats ?? this.seats,
      maxPickupDistanceKm: maxPickupDistanceKm ?? this.maxPickupDistanceKm,
      maxDropDistanceKm: maxDropDistanceKm ?? this.maxDropDistanceKm,
      timeWindowHours: timeWindowHours ?? this.timeWindowHours,
      pickupPolicy: pickupPolicy ?? this.pickupPolicy,
      minContribution: minContribution ?? this.minContribution,
      maxContribution: maxContribution ?? this.maxContribution,
    );
  }
}

final rideSearchQueryProvider = StateProvider<RideSearchQuery>((ref) {
  return RideSearchQuery(
    origin: 'Ahmedabad',
    destination: 'Rajkot',
    date: DateTime.now(),
    seats: 1,
  );
});

final searchRidesProvider = FutureProvider.autoDispose<List<RideSearchResult>>((
  ref,
) async {
  final repo = ref.watch(rideApiRepositoryProvider);
  final query = ref.watch(rideSearchQueryProvider);

  DateTime departureDateTime = query.date;
  if (query.time != null) {
    departureDateTime = DateTime(
      query.date.year,
      query.date.month,
      query.date.day,
      query.time!.hour,
      query.time!.minute,
    );
  }

  return await repo.searchRides(
    origin: query.originLocation,
    destination: query.destinationLocation,
    originText: query.origin,
    destinationText: query.destination,
    departureDate: departureDateTime,
    seats: query.seats,
    maxPickupDistanceKm: query.maxPickupDistanceKm,
    maxDropDistanceKm: query.maxDropDistanceKm,
    timeWindowHours: query.timeWindowHours,
    pickupPolicy: query.pickupPolicy,
    minContribution: query.minContribution,
    maxContribution: query.maxContribution,
  );
});

final selectedRideProvider = StateProvider<RideModel?>((ref) => null);
final selectedSearchResultProvider = StateProvider<RideSearchResult?>(
  (ref) => null,
);
final selectedSeatsProvider = StateProvider<List<String>>((ref) => ['A1']);

// --- Driver's My Rides State ---
class MyRidesNotifier extends AsyncNotifier<List<RideModel>> {
  @override
  Future<List<RideModel>> build() async {
    final repo = ref.read(rideApiRepositoryProvider);
    return await repo.getMyRides();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(rideApiRepositoryProvider);
      return await repo.getMyRides();
    });
  }

  Future<void> cancelRide(String id) async {
    final repo = ref.read(rideApiRepositoryProvider);
    final cancelledRide = await repo.cancelRide(id);

    final current = state.value ?? [];
    state = AsyncData(
      current.map((r) => r.id == id ? cancelledRide : r).toList(),
    );
  }
}

final myRidesProvider = AsyncNotifierProvider<MyRidesNotifier, List<RideModel>>(
  () {
    return MyRidesNotifier();
  },
);

// --- Offer Ride Draft State ---
class OfferRideState {
  final VehicleModel? selectedVehicle;
  final LocationModel? origin;
  final LocationModel? destination;
  final RouteInfo? route;
  final bool isCalculatingRoute;
  final DateTime departureDate;
  final TimeOfDay departureTime;
  final int availableSeats;
  final double contributionPerSeat;
  final PickupPolicy pickupPolicy;
  final List<String> amenities;
  final String notes;
  final bool isSubmitting;
  final String? errorMessage;

  OfferRideState({
    this.selectedVehicle,
    this.origin,
    this.destination,
    this.route,
    this.isCalculatingRoute = false,
    DateTime? departureDate,
    TimeOfDay? departureTime,
    this.availableSeats = 1,
    this.contributionPerSeat = 350.0,
    this.pickupPolicy = PickupPolicy.nearby,
    this.amenities = const ['AC', 'Music'],
    this.notes = '',
    this.isSubmitting = false,
    this.errorMessage,
  }) : departureDate =
           departureDate ?? DateTime.now().add(const Duration(hours: 4)),
       departureTime =
           departureTime ??
           TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 4)));

  OfferRideState copyWith({
    VehicleModel? selectedVehicle,
    LocationModel? origin,
    LocationModel? destination,
    RouteInfo? route,
    bool? isCalculatingRoute,
    DateTime? departureDate,
    TimeOfDay? departureTime,
    int? availableSeats,
    double? contributionPerSeat,
    PickupPolicy? pickupPolicy,
    List<String>? amenities,
    String? notes,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OfferRideState(
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      route: route ?? this.route,
      isCalculatingRoute: isCalculatingRoute ?? this.isCalculatingRoute,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      contributionPerSeat: contributionPerSeat ?? this.contributionPerSeat,
      pickupPolicy: pickupPolicy ?? this.pickupPolicy,
      amenities: amenities ?? this.amenities,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OfferRideNotifier extends StateNotifier<OfferRideState> {
  final Ref ref;

  OfferRideNotifier(this.ref) : super(OfferRideState());

  void setVehicle(VehicleModel vehicle) {
    int maxSeats = vehicle.seatCapacity;
    int currentSeats = state.availableSeats;
    if (currentSeats > maxSeats) {
      currentSeats = maxSeats;
    }
    state = state.copyWith(
      selectedVehicle: vehicle,
      availableSeats: currentSeats > 0 ? currentSeats : 1,
      clearError: true,
    );
  }

  void setOrigin(LocationModel origin) {
    state = state.copyWith(origin: origin, clearError: true);
    if (state.destination != null) {
      calculateRoute();
    }
  }

  void setDestination(LocationModel destination) {
    state = state.copyWith(destination: destination, clearError: true);
    if (state.origin != null) {
      calculateRoute();
    }
  }

  Future<void> calculateRoute() async {
    final origin = state.origin;
    final destination = state.destination;

    if (origin == null || destination == null) return;

    state = state.copyWith(isCalculatingRoute: true, clearError: true);

    try {
      final repo = ref.read(rideApiRepositoryProvider);
      final route = await repo.calculateRoute(
        origin: origin,
        destination: destination,
      );
      state = state.copyWith(route: route, isCalculatingRoute: false);
    } catch (e) {
      state = state.copyWith(
        isCalculatingRoute: false,
        errorMessage: 'Route calculation failed: ${e.toString()}',
      );
    }
  }

  void setDepartureDate(DateTime date) {
    state = state.copyWith(departureDate: date, clearError: true);
  }

  void setDepartureTime(TimeOfDay time) {
    state = state.copyWith(departureTime: time, clearError: true);
  }

  void setAvailableSeats(int seats) {
    state = state.copyWith(availableSeats: seats, clearError: true);
  }

  void setContribution(double amount) {
    state = state.copyWith(contributionPerSeat: amount, clearError: true);
  }

  void setPickupPolicy(PickupPolicy policy) {
    state = state.copyWith(pickupPolicy: policy, clearError: true);
  }

  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(amenities: current, clearError: true);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes, clearError: true);
  }

  Future<RideModel> publishRide() async {
    final vehicle = state.selectedVehicle;
    final origin = state.origin;
    final destination = state.destination;
    final route = state.route;

    if (vehicle == null) {
      throw Exception('Please select a vehicle.');
    }
    if (origin == null) {
      throw Exception('Please specify an origin location.');
    }
    if (destination == null) {
      throw Exception('Please specify a destination location.');
    }
    if (route == null) {
      throw Exception('Route calculation is required.');
    }

    final depDateTime = DateTime(
      state.departureDate.year,
      state.departureDate.month,
      state.departureDate.day,
      state.departureTime.hour,
      state.departureTime.minute,
    );

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final repo = ref.read(rideApiRepositoryProvider);
      final createdRide = await repo.createRide(
        vehicleId: vehicle.id,
        origin: origin,
        destination: destination,
        route: route,
        departureTime: depDateTime,
        availableSeats: state.availableSeats,
        contributionPerSeat: state.contributionPerSeat,
        pickupPolicy: state.pickupPolicy.name,
        amenities: state.amenities,
        notes: state.notes.isNotEmpty ? state.notes : null,
      );

      // Refresh My Rides list
      ref.read(myRidesProvider.notifier).refresh();

      state = state.copyWith(isSubmitting: false);
      return createdRide;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  void reset() {
    state = OfferRideState();
  }
}

final offerRideProvider =
    StateNotifierProvider<OfferRideNotifier, OfferRideState>((ref) {
      return OfferRideNotifier(ref);
    });
