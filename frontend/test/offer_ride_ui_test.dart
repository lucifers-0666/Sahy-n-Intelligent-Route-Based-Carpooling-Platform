import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/rides/data/ride_repository.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/screens/offer_ride_screen.dart';
import 'package:sahyan/features/vehicles/data/vehicle_repository.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/models/user_model.dart';

class MockVehicleRepository implements VehicleRepository {
  final List<VehicleModel> vehicles;

  MockVehicleRepository([this.vehicles = const []]);

  @override
  Future<List<VehicleModel>> getVehicles() async => vehicles;

  @override
  Future<VehicleModel> getVehicleById(String id) async => vehicles.first;

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
  }) async => {};

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
  }) async => vehicles.first;

  @override
  Future<Map<String, dynamic>> deleteVehicle(String id) async => {};
}

class MockRideRepository implements RideRepository {
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
    return RideModel(
      id: 'ride_new_123',
      driverId: 'driver_1',
      driverName: 'Test Driver',
      driverRating: 4.9,
      isDriverVerified: true,
      vehicle: const VehicleModel(
        id: 'veh_test_1',
        ownerId: 'driver_1',
        make: 'Honda',
        model: 'City',
        year: 2022,
        color: 'White',
        registrationNumber: 'GJ-12-CD-5678',
        seatCapacity: 4,
        vehicleType: 'sedan',
        status: 'active',
      ),
      origin: origin,
      destination: destination,
      route: route,
      dateTime: departureTime,
      departureTime: '10:00 AM',
      estimatedArrival: '04:00 PM',
      availableSeats: availableSeats,
      totalSeats: 4,
      contributionPerSeat: contributionPerSeat,
      status: RideStatus.scheduled,
      pickupPolicy: pickupPolicy == 'exact' ? PickupPolicy.exact : PickupPolicy.nearby,
      amenities: amenities,
      notes: notes,
    );
  }

  @override
  Future<List<RideModel>> getMyRides({String? status}) async => [];

  @override
  Future<RideModel> getRideById(String id) async {
    throw Exception('Not implemented');
  }

  @override
  Future<RideModel> cancelRide(String id) async {
    throw Exception('Not implemented');
  }

  @override
  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
  }) async {
    return const RouteInfo(
      encodedPolyline: 'w~dfD_bswM_route_encoded_bhuj_amd',
      distanceMeters: 332000,
      durationSeconds: 21600,
    );
  }
}

class MockSecureStorageService implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'fake_token';
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> saveUser(UserModel user) async {}
  @override
  Future<UserModel?> getUser() async => null;
  @override
  Future<void> deleteUser() async {}
  @override
  Future<void> clearSession() async {}
  @override
  Future<void> setCompletedOnboarding(bool completed) async {}
  @override
  Future<bool> hasCompletedOnboarding() async => true;
}

void main() {
  const testVehicle = VehicleModel(
    id: 'veh_test_1',
    ownerId: 'driver_1',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'White',
    registrationNumber: 'GJ-12-CD-5678',
    seatCapacity: 4,
    vehicleType: 'sedan',
    status: 'active',
  );

  Widget createWidgetUnderTest({
    List<VehicleModel> vehicles = const [testVehicle],
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(MockSecureStorageService()),
        vehicleRepositoryProvider.overrideWithValue(MockVehicleRepository(vehicles)),
        rideApiRepositoryProvider.overrideWithValue(MockRideRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
          child: const OfferRideScreen(),
        ),
      ),
    );
  }

  group('OfferRideScreen Multi-Step Rendering & Interaction', () {
    testWidgets('Renders screen title and step indicators', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Offer a Ride'), findsOneWidget);
      expect(find.text('Vehicle & Route'), findsOneWidget);
      expect(find.text('Schedule & Seats'), findsOneWidget);
      expect(find.text('Review & Publish'), findsOneWidget);
    });

    testWidgets('Empty vehicle state shows Add Vehicle prompt', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(vehicles: []));
      await tester.pumpAndSettle();

      expect(find.text('No vehicles registered yet'), findsOneWidget);
      expect(find.text('Add Vehicle'), findsOneWidget);
    });

    testWidgets('Selecting quick origin and destination chips populates fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 'Bhuj' origin chip
      final bhujChip = find.widgetWithText(ActionChip, 'Bhuj');
      expect(bhujChip, findsOneWidget);
      await tester.tap(bhujChip);
      await tester.pumpAndSettle();

      expect(find.text('Bhuj'), findsWidgets);

      // Tap 'Ahmedabad' destination chip
      final amdChip = find.widgetWithText(ActionChip, 'Ahmedabad');
      expect(amdChip, findsWidgets);
      await tester.tap(amdChip.last);
      await tester.pumpAndSettle();

      expect(find.text('Ahmedabad'), findsWidgets);
    });

    testWidgets('Navigating from Step 1 to Step 2 and adjusting seats', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Select origin and destination
      await tester.tap(find.widgetWithText(ActionChip, 'Bhuj'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Ahmedabad').last);
      await tester.pumpAndSettle();

      // Ensure Continue button is scrolled into view and tap
      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Now on Step 2
      expect(find.text('Departure Schedule'), findsOneWidget);
      expect(find.text('Available Seats'), findsOneWidget);
      expect(find.text('Vehicle limit: 4 seats'), findsOneWidget);

      // Increment seats
      final addSeatBtn = find.byIcon(Icons.add_circle_outline);
      expect(addSeatBtn, findsOneWidget);
      await tester.ensureVisible(addSeatBtn);
      await tester.pumpAndSettle();
      await tester.tap(addSeatBtn);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsWidgets);

      // Tap Continue to Step 3
      final step2ContinueBtn = find.text('Continue');
      await tester.ensureVisible(step2ContinueBtn);
      await tester.pumpAndSettle();
      await tester.tap(step2ContinueBtn);
      await tester.pumpAndSettle();

      // Now on Step 3
      expect(find.text('Amenities & Preferences'), findsOneWidget);
      expect(find.text('Journey Summary'), findsOneWidget);
      expect(find.text('Publish Ride'), findsOneWidget);
    });
  });

  group('Responsive Layout Testing Across Viewports & 1.5x Text Scaling', () {
    final viewports = [
      const Size(320.0, 568.0), // Compact mobile (iPhone SE 1st gen)
      const Size(360.0, 640.0), // Standard Android
      const Size(390.0, 844.0), // Modern iPhone 12/13/14
      const Size(412.0, 915.0), // Pixel 7/8 / Large Android
      const Size(600.0, 1024.0), // Tablet portrait
    ];

    for (final size in viewports) {
      testWidgets('OfferRideScreen renders without overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Offer a Ride'), findsOneWidget);
      });
    }

    testWidgets('OfferRideScreen renders without overflow under 1.5x text scaling', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(textScaleFactor: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Offer a Ride'), findsOneWidget);
    });
  });
}
