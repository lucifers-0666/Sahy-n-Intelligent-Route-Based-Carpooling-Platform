import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/rides/data/ride_repository.dart';

import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_details_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/search_results_screen.dart';
import 'package:sahyan/features/rides/presentation/widgets/route_map_preview.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/widgets/auth_gate_dialog.dart';
import 'package:sahyan/shared/widgets/ride_card.dart';

class MockSearchRideRepository implements RideRepository {
  final List<RideSearchResult> resultsToReturn;

  MockSearchRideRepository({this.resultsToReturn = const []});

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
    return resultsToReturn;
  }

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
  }) async => throw UnimplementedError();

  @override
  Future<List<RideModel>> getMyRides({String? status}) async => [];

  @override
  Future<RideModel> getRideById(String id) async => throw UnimplementedError();

  @override
  Future<RideModel> cancelRide(String id) async => throw UnimplementedError();

  @override
  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
  }) async => throw UnimplementedError();
}

void main() {
  final testOrigin = LocationModel.fromCoordinates(
    name: 'Bhuj Jubilee Ground',
    latitude: 23.2420,
    longitude: 69.6669,
  );

  final testDestination = LocationModel.fromCoordinates(
    name: 'Ahmedabad Paldi',
    latitude: 23.0225,
    longitude: 72.5714,
  );

  final testVehicle = const VehicleModel(
    id: 'veh_01',
    ownerId: 'driver_01',
    registrationNumber: 'GJ12AA1111',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'White',
    seatCapacity: 4,
    status: 'active',
  );

  final testRide = RideModel(
    id: 'ride_test_01',
    driverId: 'driver_01',
    driverName: 'Harsh Dave',
    driverRating: 4.8,
    isDriverVerified: true,
    vehicle: testVehicle,
    origin: testOrigin,
    destination: testDestination,
    route: const RouteInfo(
      encodedPolyline: 'mock_polyline_encoded',
      distanceMeters: 380000,
      durationSeconds: 21600,
    ),
    dateTime: DateTime.now().add(const Duration(hours: 4)),
    departureTime: '08:30 AM',
    estimatedArrival: '02:30 PM',
    availableSeats: 3,
    totalSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 450.0,
    status: RideStatus.scheduled,
    pickupPolicy: PickupPolicy.nearby,
    amenities: const ['AC', 'Music', 'No Smoking'],
    notes: 'Leaving on time. Please reach pickup point 10 mins early.',
  );

  final testSearchResult = RideSearchResult(
    ride: testRide,
    pickupDistanceKm: 1.8,
    destinationDistanceKm: 2.1,
    departureDifferenceMinutes: 15,
    availableSeats: 3,
    matchPreview: 'Pickup within 1.8 km | 15 min departure difference',
  );

  Widget createTestApp({
    required Widget child,
    List<RideSearchResult> results = const [],
    bool isGuest = false,
    Size screenSize = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        userModeProvider.overrideWith((ref) {
          final notifier = UserModeNotifier();
          if (isGuest) {
            notifier.setGuestMode();
          }
          return notifier;
        }),
        rideApiRepositoryProvider.overrideWithValue(
          MockSearchRideRepository(resultsToReturn: results),
        ),
      ],

      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: child,
        ),
      ),
    );
  }

  group('Phase 6: Passenger Search Results UI Tests', () {
    testWidgets('Renders empty state with adjust button when no rides match', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const SearchResultsScreen(), results: []),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Planned Rides Found'), findsOneWidget);
      expect(find.text('Broaden Search (50 km)'), findsOneWidget);
    });

    testWidgets(
      'Renders candidate ride card with preliminary proximity badge',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SearchResultsScreen(),
            results: [testSearchResult],
          ),
        );
        await tester.pumpAndSettle();

        // Card must show proximity info and route
        expect(find.text('Pickup ~1.8 km'), findsOneWidget);
        expect(find.text('15m diff'), findsOneWidget);
        expect(find.text('Harsh Dave'), findsOneWidget);
        expect(find.text('₹450 / seat'), findsOneWidget);
        expect(find.text('3 seat(s) left'), findsOneWidget);
      },
    );

    testWidgets('Filter modal opens and shows radius and time options', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SearchResultsScreen(),
          results: [testSearchResult],
        ),
      );
      await tester.pumpAndSettle();

      // Tap tune icon in AppBar
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Search Filters'), findsOneWidget);
      expect(find.text('Pickup Deviation Radius'), findsOneWidget);
      expect(find.text('Departure Time Window'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });
  });

  group('Phase 6: Ride Details Screen Tests', () {
    testWidgets('Renders RouteMapPreview, driver, vehicle, and policy', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userModeProvider.overrideWith((ref) => UserModeNotifier()),
          selectedRideProvider.overrideWith((ref) => testRide),
          selectedSearchResultProvider.overrideWith((ref) => testSearchResult),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RideDetailsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must display RouteMapPreview
      expect(find.byType(RouteMapPreview), findsOneWidget);

      // Must display driver name
      expect(find.text('Harsh Dave'), findsOneWidget);

      // Must display vehicle details
      final vehicleFinder = find.textContaining('Honda City');
      await tester.ensureVisible(vehicleFinder);
      await tester.pumpAndSettle();
      expect(vehicleFinder, findsOneWidget);
      expect(find.textContaining('GJ12AA1111'), findsOneWidget);

      // Must display amenities and notes
      final amenitiesFinder = find.text('AC');
      await tester.ensureVisible(amenitiesFinder);
      await tester.pumpAndSettle();
      expect(amenitiesFinder, findsOneWidget);

      final notesFinder = find.text(
        'Leaving on time. Please reach pickup point 10 mins early.',
      );
      await tester.ensureVisible(notesFinder);
      await tester.pumpAndSettle();
      expect(notesFinder, findsOneWidget);

      // Must display Request Seat button
      expect(find.text('Request Seat'), findsOneWidget);
    });

    testWidgets('Guest user tapping Request Seat triggers AuthGateDialog', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userModeProvider.overrideWith((ref) {
            final notifier = UserModeNotifier();
            notifier.setGuestMode();
            return notifier;
          }),
          selectedRideProvider.overrideWith((ref) => testRide),
          selectedSearchResultProvider.overrideWith((ref) => testSearchResult),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RideDetailsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Request Seat as guest
      await tester.tap(find.text('Request Seat'));
      await tester.pumpAndSettle();

      // AuthGateDialog must be shown
      expect(find.byType(AuthGateDialog), findsOneWidget);
      expect(find.text('Sign In to Request Seat'), findsOneWidget);
    });
  });

  group('Phase 6: Responsiveness Tests (No Pixel Overflow)', () {
    for (final size in [
      const Size(320, 568), // Small screen (320dp width)
      const Size(360, 640), // Standard Android
      const Size(412, 915), // Modern larger Android
      const Size(600, 960), // Tablet layout
    ]) {
      testWidgets(
        'RideCard renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              screenSize: size,
              child: Scaffold(
                body: ListView(
                  children: [
                    RideCard(
                      ride: testRide,
                      searchResult: testSearchResult,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Harsh Dave'), findsOneWidget);
          expect(find.text('₹450 / seat'), findsOneWidget);
        },
      );
    }
  });
}
