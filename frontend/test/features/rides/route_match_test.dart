import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/rides/presentation/widgets/route_match_breakdown_widget.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
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
      timeCompatibility: 95,
      driverReliability: 90,
      seatAvailability: 100,
    ),
    metrics: RouteMatchMetrics(
      routeOverlapPercentage: 96,
      pickupDistanceKm: 1.2,
      destinationDistanceKm: 0.8,
      departureDifferenceMinutes: 10,
    ),
    reasons: [
      '96% of your route overlaps',
      'Pickup is only 1.2 km away',
      'Departure is 10 min from your preferred time',
      'Top-rated driver (4.8 rating)',
    ],
  );

  final sampleSearchResult = RideSearchResult(
    ride: sampleRide,
    pickupDistanceKm: 1.2,
    destinationDistanceKm: 0.8,
    departureDifferenceMinutes: 10,
    availableSeats: 3,
    matchPreview: '94% Match | Excellent Match',
    match: sampleMatch,
  );

  Widget createTestWidget(
    Widget child, {
    double width = 390,
    double height = 844,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets(
    'RideCard displays match percentage, grade, and reason highlight',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RideCard(
            ride: sampleRide,
            searchResult: sampleSearchResult,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 94% Match badge is rendered
      expect(find.text('94% Match'), findsOneWidget);
      expect(find.text('Excellent Match'), findsOneWidget);

      // Verify Top Reason is highlighted in the compact preview
      expect(find.text('96% of your route overlaps'), findsOneWidget);

      // Verify "Why this match?" action exists
      expect(find.text('Why this match?'), findsOneWidget);
    },
  );

  testWidgets(
    'RouteMatchBreakdownWidget renders all factors, progress bars, and explainable reasons',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(RouteMatchBreakdownWidget(match: sampleMatch)),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('94% Match'), findsOneWidget);
      expect(find.text('Excellent Match'), findsOneWidget);

      // Check reasons
      expect(find.text('Why this ride matches you:'), findsOneWidget);
      expect(find.text('96% of your route overlaps'), findsOneWidget);
      expect(find.text('Pickup is only 1.2 km away'), findsOneWidget);
      expect(
        find.text('Departure is 10 min from your preferred time'),
        findsOneWidget,
      );
      expect(find.text('Top-rated driver (4.8 rating)'), findsOneWidget);

      // Check all 6 factor labels
      expect(find.text('Route Overlap'), findsOneWidget);
      expect(find.text('Pickup Deviation'), findsOneWidget);
      expect(find.text('Destination Deviation'), findsOneWidget);
      expect(find.text('Time Compatibility'), findsOneWidget);
      expect(find.text('Driver Reliability'), findsOneWidget);
      expect(find.text('Seat Availability'), findsOneWidget);

      // Check progress bars exist
      expect(find.byType(LinearProgressIndicator), findsNWidgets(6));
    },
  );

  testWidgets('Tapping Why this match? opens bottom sheet with analysis', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        RideCard(
          ride: sampleRide,
          searchResult: sampleSearchResult,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Why this match?"
    await tester.tap(find.text('Why this match?'));
    await tester.pumpAndSettle();

    // Bottom sheet should open with Route Match Analysis title
    expect(find.text('Route Match Analysis'), findsOneWidget);
    expect(find.text('Scoring Factor Breakdown'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Tap close button to close
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Route Match Analysis'), findsNothing);
  });

  testWidgets(
    'Responsive layouts work without RenderFlex overflow at 320dp width and 1.5x font scale',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Column(
            children: [
              RideCard(
                ride: sampleRide,
                searchResult: sampleSearchResult,
                onTap: () {},
              ),
              RouteMatchBreakdownWidget(match: sampleMatch),
            ],
          ),
          width: 320,
          height: 700,
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      // Should render with 0 errors / 0 overflows
      expect(tester.takeException(), isNull);
      expect(find.text('94% Match'), findsWidgets);
    },
  );

  testWidgets('RideCard gracefully falls back when match object is null', (
    tester,
  ) async {
    final legacyResult = RideSearchResult(
      ride: sampleRide,
      pickupDistanceKm: 2.5,
      destinationDistanceKm: 1.0,
      departureDifferenceMinutes: 15,
      availableSeats: 3,
      matchPreview: 'Direct Route',
      match: null,
    );

    await tester.pumpWidget(
      createTestWidget(
        RideCard(ride: sampleRide, searchResult: legacyResult, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Match badges are not present
    expect(find.text('94% Match'), findsNothing);
    expect(find.text('Why this match?'), findsNothing);

    // Legacy proximity badge is shown
    expect(find.text('Pickup ~2.5 km'), findsOneWidget);
    expect(find.text('15m diff'), findsOneWidget);
  });
}
