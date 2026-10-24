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
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/models/user_model.dart';

import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async => {};

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async => {};

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async => {};

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async => {};

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async => {};

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async => {};

  @override
  Future<UserModel> getProfile() async => const UserModel(
        id: 'driver_1',
        name: 'Test Driver',
        phone: '+919876543210',
        email: 'testdriver@sahyan.com',
        city: 'Ahmedabad',
        verificationStatus: UserVerificationStatus.verified,
        rating: 4.9,
        totalRides: 14,
        canDrive: true,
        driverOnboardingStatus: 'approved',
      );
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier([AuthState? initialState])
      : super(
          repository: MockAuthRepository(),
          storageService: MockSecureStorageService(),
          apiClient: ApiClient(),
        ) {
    state = initialState ??
        const AuthState(
          status: AuthStatus.authenticated,
          user: UserModel(
            id: 'driver_1',
            name: 'Test Driver',
            phone: '+919876543210',
            email: 'testdriver@sahyan.com',
            city: 'Ahmedabad',
            verificationStatus: UserVerificationStatus.verified,
            rating: 4.9,
            totalRides: 14,
            canDrive: true,
            driverOnboardingStatus: 'approved',
          ),
          token: 'fake_jwt',
        );
  }

  @override
  Future<void> checkAuthStatus() async {}
}

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
      pickupPolicy: pickupPolicy == 'exact'
          ? PickupPolicy.exact
          : PickupPolicy.nearby,
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
  Future<RideModel> startBoarding(String id) async {
    throw Exception('Not implemented');
  }

  @override
  Future<RideModel> startTrip(String id) async {
    throw Exception('Not implemented');
  }

  @override
  Future<RideModel> completeTrip(String id) async {
    throw Exception('Not implemented');
  }

  @override
  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
    List<LocationModel> waypoints = const [],
  }) async {
    return const RouteInfo(
      encodedPolyline: 'w~dfD_bswM_route_encoded_bhuj_amd',
      distanceMeters: 332000,
      durationSeconds: 21600,
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
  }) async => [];
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
    AuthState? authState,
  }) {
    return ProviderScope(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(
          MockSecureStorageService(),
        ),
        authProvider.overrideWith(
          (ref) => TestAuthNotifier(authState),
        ),
        vehicleRepositoryProvider.overrideWithValue(
          MockVehicleRepository(vehicles),
        ),
        rideApiRepositoryProvider.overrideWithValue(MockRideRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: const OfferRideScreen(),
          ),
        ),
      ),
    );
  }

  group('OfferRideScreen Multi-Step Rendering & Interaction', () {
    testWidgets('Unauthenticated guest renders Sign In Required card', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: const AuthState(status: AuthStatus.unauthenticated),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In Required'), findsOneWidget);
      expect(
        find.text(
          'Sign in or register to select your registered vehicle and publish rides.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign In to Continue'), findsOneWidget);
    });

    testWidgets('Renders screen title and step indicators', (tester) async {
      tester.view.physicalSize = const Size(600.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Offer a Ride'), findsOneWidget);
      expect(find.text('Vehicle & Route'), findsOneWidget);
      expect(find.text('Schedule & Seats'), findsOneWidget);
      expect(find.text('Review & Publish'), findsOneWidget);
    });

    testWidgets('Narrow viewport displays compact step indicator', (tester) async {
      tester.view.physicalSize = const Size(360.0, 640.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Vehicle & Route'), findsOneWidget);
    });

    testWidgets('Empty vehicle state shows Add Vehicle prompt', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(vehicles: []));
      await tester.pumpAndSettle();

      expect(find.text('No vehicles registered yet'), findsOneWidget);
      expect(find.text('Add Vehicle'), findsOneWidget);
    });

    testWidgets(
      'Selecting quick origin and destination chips populates fields',
      (tester) async {
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
      },
    );

    testWidgets('Navigating from Step 1 to Step 2 and adjusting seats', (
      tester,
    ) async {
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

    testWidgets('AppBar back button steps back through the wizard steps', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify back button is present in AppBar
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      // Select origin and destination to advance to Step 2
      await tester.tap(find.widgetWithText(ActionChip, 'Bhuj'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Ahmedabad').last);
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify on Step 2
      expect(find.text('Departure Schedule'), findsOneWidget);

      // Tap AppBar back button
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify returned to Step 1
      expect(find.text('1. Choose Your Vehicle'), findsOneWidget);
    });

    testWidgets('Unified transit route rail card displays dedicated icons, labels and stopover pill', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify Origin Row elements
      expect(find.text('Origin Location (From)'), findsOneWidget);
      expect(find.text('Search pickup point or current GPS'), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsWidgets);

      // Verify Destination Row elements
      expect(find.text('Destination Location (To)'), findsOneWidget);
      expect(find.text('Search dropoff city or hub'), findsOneWidget);
      expect(find.byIcon(Icons.flag_circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsWidgets);

      // Verify Inline Stopover Divider & Pill
      expect(find.text('Add Stopover / Toll'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
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
      testWidgets(
        'OfferRideScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Offer a Ride'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'OfferRideScreen renders without overflow under 1.5x text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(390.0, 844.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createWidgetUnderTest(textScaleFactor: 1.5));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Offer a Ride'), findsOneWidget);
      },
    );
  });
}
