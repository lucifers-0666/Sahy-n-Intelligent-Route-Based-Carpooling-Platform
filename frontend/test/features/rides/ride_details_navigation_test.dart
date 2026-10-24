import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/rides/data/ride_repository.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_details_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class _FakeBookingsRepo extends Fake implements BookingsRepository {}

class _MockRideRepo extends Fake implements RideRepository {
  RideModel? mockRide;
  bool shouldThrow = false;

  @override
  Future<RideModel> getRideById(String id) async {
    if (shouldThrow) {
      throw Exception('Ride not found');
    }
    return mockRide ?? _sampleRide(id: id);
  }
}

RideModel _sampleRide({String id = 'ride_101'}) {
  return RideModel(
    id: id,
    driverId: 'drv_1',
    driverName: 'Rohit Patel',
    driverRating: 4.92,
    isDriverVerified: true,
    departureTime: '06:30 PM',
    estimatedArrival: '09:45 PM',
    dateTime: DateTime(2026, 10, 25, 18, 30),
    origin: const LocationModel(
      name: 'Ahmedabad',
      address: 'Prahlad Nagar, SG Highway, Ahmedabad',
      city: 'Ahmedabad',
      latitude: 23.0125,
      longitude: 72.5020,
    ),
    destination: const LocationModel(
      name: 'Rajkot',
      address: 'Kalawad Road, Rajkot',
      city: 'Rajkot',
      latitude: 22.2850,
      longitude: 70.7725,
    ),
    route: const RouteInfo(
      encodedPolyline: '',
      distanceMeters: 215000,
      durationSeconds: 11700,
    ),
    vehicle: const VehicleModel(
      id: 'veh_1',
      ownerId: 'drv_1',
      make: 'Honda',
      model: 'City ZX',
      year: 2023,
      color: 'White',
      registrationNumber: 'GJ 01 AB 1234',
      seatCapacity: 4,
      vehicleType: 'sedan',
      status: 'active',
    ),
    availableSeats: 3,
    totalSeats: 4,
    bookedSeats: 1,
    contributionPerSeat: 520.0,
    status: RideStatus.scheduled,
    amenities: const ['AC', 'Music', 'No Smoking'],
  );
}

void main() {
  group('RideDetailsScreen Navigation & Loading Tests', () {
    testWidgets('Renders ride details directly when initialRide is supplied', (tester) async {
      final ride = _sampleRide();

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RideDetailsScreen(initialRide: ride),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ride Overview'), findsOneWidget);
      expect(find.text('Rohit Patel'), findsOneWidget);
      expect(find.text('Request Seat'), findsOneWidget);
      expect(find.textContaining('Honda City ZX'), findsOneWidget);
    });

    testWidgets('Fetches ride by ID via rideByIdProvider when rideId is supplied', (tester) async {
      final mockRepo = _MockRideRepo();

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rideApiRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: RideDetailsScreen(rideId: 'ride_101'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ride Overview'), findsOneWidget);
      expect(find.text('Rohit Patel'), findsOneWidget);
      expect(find.textContaining('Honda City ZX'), findsOneWidget);
    });

    testWidgets('Shows pending review status banner when user has a pending booking for this ride', (tester) async {
      final ride = _sampleRide();
      final pendingBooking = BookingModel(
        id: 'bk_1',
        rideId: ride.id,
        passengerId: 'usr_1',
        requestedSeats: 1,
        contributionPerSeat: 520.0,
        totalContribution: 520.0,
        status: BookingStatus.pending,
        pickup: ride.origin,
        drop: ride.destination,
        createdAt: DateTime.now(),
      );

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsNotifierProvider.overrideWith((ref) {
              final notifier = BookingsNotifier(_FakeBookingsRepo());
              notifier.state = AsyncValue.data([pendingBooking]);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: RideDetailsScreen(initialRide: ride),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Under Review (Pending Driver Approval)'), findsOneWidget);
      expect(find.text('Request Seat'), findsNothing);
    });

    testWidgets('Shows error view with retry button if ride fetch fails', (tester) async {
      final mockRepo = _MockRideRepo()..shouldThrow = true;

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rideApiRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: RideDetailsScreen(rideId: 'ride_invalid'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load ride details'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
