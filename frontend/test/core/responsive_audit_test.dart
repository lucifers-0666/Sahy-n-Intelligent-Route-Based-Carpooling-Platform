import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/home/presentation/screens/home_screen.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/rides/presentation/screens/search_results_screen.dart';
import 'package:sahyan/features/rides/presentation/widgets/route_match_breakdown_widget.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/widgets/auth_gate_dialog.dart';
import 'package:sahyan/shared/widgets/ride_card.dart';

void main() {
  final sampleVehicle = VehicleModel(
    id: 'veh-1',
    ownerId: 'drv-1',
    make: 'Hyundai',
    model: 'Creta',
    year: 2023,
    color: 'White',
    seatCapacity: 4,
    registrationNumber: 'GJ12AA1111',
    vehicleType: 'suv',
    status: 'active',
  );

  final sampleRide = RideModel(
    id: 'ride-1',
    driverId: 'drv-1',
    driverName: 'Vikram Joshi',
    driverRating: 4.8,
    isDriverVerified: true,
    vehicle: sampleVehicle,
    origin: const LocationModel(
      city: 'Bhuj',
      address: 'Bhuj Bus Station',
      latitude: 23.2420,
      longitude: 69.6669,
    ),
    destination: const LocationModel(
      city: 'Ahmedabad',
      address: 'Ahmedabad Railway Station',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    departureTime: '08:00 AM',
    estimatedArrival: '02:30 PM',
    availableSeats: 3,
    totalSeats: 4,
    contributionPerSeat: 450.0,
    status: RideStatus.scheduled,
    amenities: const [],
    dateTime: DateTime(2026, 9, 10, 8, 0),
  );

  final sampleMatch = const RouteMatchDetails(
    score: 94,
    grade: 'Excellent Match',
    factors: RouteMatchFactors(
      routeOverlap: 96,
      pickupDeviation: 92,
      destinationDeviation: 97,
      timeCompatibility: 90,
      driverReliability: 95,
      seatAvailability: 100,
    ),
    metrics: RouteMatchMetrics(
      routeOverlapPercentage: 96,
      pickupDistanceKm: 0.8,
      destinationDistanceKm: 0.5,
      departureDifferenceMinutes: 10,
    ),
    reasons: [
      'Very high route alignment (96%)',
      'Pickup is within 0.8 km of driver route',
      'Departure time aligns within 10 mins',
    ],
  );

  Widget createResponsiveApp({
    required Widget child,
    Size size = const Size(360, 640),
    double textScaleFactor = 1.0,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScaleFactor),
            viewInsets: viewInsets,
            padding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Responsive Layout Audit Tests', () {
    testWidgets(
      'Search Filters bottom sheet renders without overflow at 320dp width',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createResponsiveApp(
            size: const Size(320, 568),
            textScaleFactor: 1.5,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => const SearchFiltersBottomSheet(),
                    );
                  },
                  child: const Text('Open Filters'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Filters'));
        await tester.pumpAndSettle();

        expect(find.text('Search Filters'), findsOneWidget);
        expect(find.text('Pickup Deviation Radius'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Search Filters bottom sheet renders without overflow across viewports',
      (tester) async {
        const viewports = [
          Size(320, 568),
          Size(360, 640),
          Size(390, 844),
          Size(412, 915),
          Size(600, 960),
        ];

        for (final vp in viewports) {
          await tester.binding.setSurfaceSize(vp);

          await tester.pumpWidget(
            createResponsiveApp(
              size: vp,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => const SearchFiltersBottomSheet(),
                      );
                    },
                    child: const Text('Open Filters'),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Open Filters'));
          await tester.pumpAndSettle();

          expect(find.text('Search Filters'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Close bottom sheet for next viewport
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
        }

        await tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'Search Filters with active keyboard insets does not overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createResponsiveApp(
            size: const Size(360, 640),
            viewInsets: const EdgeInsets.only(bottom: 280),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => const SearchFiltersBottomSheet(),
                    );
                  },
                  child: const Text('Open Filters'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Filters'));
        await tester.pumpAndSettle();

        expect(find.text('Search Filters'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Home screen renders without overflow at 320dp with 1.5x font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createResponsiveApp(
            size: const Size(320, 568),
            textScaleFactor: 1.5,
            child: const HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Find a Shared Ride'), findsOneWidget);
        expect(find.text('Popular Routes in Gujarat'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AuthGateDialog renders without overflow at 320dp with 1.5x font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createResponsiveApp(
            size: const Size(320, 568),
            textScaleFactor: 1.5,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => AuthGateDialog.show(context),
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Account Required'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RouteMatchBreakdownWidget renders at 320dp with 1.5x font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createResponsiveApp(
            size: const Size(320, 568),
            textScaleFactor: 1.5,
            child: SingleChildScrollView(
              child: RouteMatchBreakdownWidget(match: sampleMatch),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('94% Match'), findsOneWidget);
        expect(find.text('Route Overlap'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RideCard renders without overflow at 320dp with 1.5x font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final result = RideSearchResult(
          ride: sampleRide,
          pickupDistanceKm: 0.8,
          destinationDistanceKm: 0.5,
          departureDifferenceMinutes: 10,
          availableSeats: 3,
          matchPreview: '94% Match',
          match: sampleMatch,
        );

        await tester.pumpWidget(
          createResponsiveApp(
            size: const Size(320, 568),
            textScaleFactor: 1.5,
            child: SingleChildScrollView(
              child: RideCard(
                ride: sampleRide,
                searchResult: result,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Vikram Joshi'), findsOneWidget);
        expect(find.text('Why this match?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
