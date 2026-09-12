import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/core/widgets/sahyan_match_score_badge.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_map_marker_service.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';

void main() {
  group('Vehicle Taxonomy and Domain Model Tests', () {
    test('Verify all 19 vehicle categories exist', () {
      expect(VehicleType.values.length, 19);

      // Cars (7)
      expect(VehicleType.values.contains(VehicleType.sedan), true);
      expect(VehicleType.values.contains(VehicleType.hatchback), true);
      expect(VehicleType.values.contains(VehicleType.suv), true);
      expect(VehicleType.values.contains(VehicleType.muv), true);
      expect(VehicleType.values.contains(VehicleType.crossover), true);
      expect(VehicleType.values.contains(VehicleType.luxurySedan), true);
      expect(VehicleType.values.contains(VehicleType.electricCar), true);

      // Two-wheelers (5)
      expect(VehicleType.values.contains(VehicleType.motorcycle), true);
      expect(VehicleType.values.contains(VehicleType.scooter), true);
      expect(VehicleType.values.contains(VehicleType.electricScooter), true);
      expect(VehicleType.values.contains(VehicleType.bicycle), true);
      expect(VehicleType.values.contains(VehicleType.electricBicycle), true);

      // Three-wheelers (2)
      expect(VehicleType.values.contains(VehicleType.autoRickshaw), true);
      expect(VehicleType.values.contains(VehicleType.electricAutoRickshaw), true);

      // Larger / utility vehicles (5)
      expect(VehicleType.values.contains(VehicleType.van), true);
      expect(VehicleType.values.contains(VehicleType.miniVan), true);
      expect(VehicleType.values.contains(VehicleType.pickupTruck), true);
      expect(VehicleType.values.contains(VehicleType.tempo), true);
      expect(VehicleType.values.contains(VehicleType.miniBus), true);
    });

    test('Verify category grouping', () {
      expect(VehicleType.sedan.categoryGroup, VehicleCategoryGroup.car);
      expect(VehicleType.motorcycle.categoryGroup, VehicleCategoryGroup.twoWheeler);
      expect(VehicleType.autoRickshaw.categoryGroup, VehicleCategoryGroup.threeWheeler);
      expect(VehicleType.van.categoryGroup, VehicleCategoryGroup.utility);
    });

    test('Verify electric vehicle detection', () {
      expect(VehicleType.electricCar.isElectric, true);
      expect(VehicleType.electricScooter.isElectric, true);
      expect(VehicleType.electricBicycle.isElectric, true);
      expect(VehicleType.electricAutoRickshaw.isElectric, true);
      expect(VehicleType.sedan.isElectric, false);
      expect(VehicleType.motorcycle.isElectric, false);
    });

    test('Verify default seat capacities', () {
      expect(VehicleType.sedan.defaultSeatCapacity, 4);
      expect(VehicleType.suv.defaultSeatCapacity, 6);
      expect(VehicleType.muv.defaultSeatCapacity, 7);
      expect(VehicleType.motorcycle.defaultSeatCapacity, 1);
      expect(VehicleType.autoRickshaw.defaultSeatCapacity, 3);
      expect(VehicleType.miniBus.defaultSeatCapacity, 14);
    });

    test('Verify VehicleType.fromString resolver resilience', () {
      expect(VehicleTypeExtension.fromString('sedan'), VehicleType.sedan);
      expect(VehicleTypeExtension.fromString('SEDAN'), VehicleType.sedan);
      expect(VehicleTypeExtension.fromString('electric-car'), VehicleType.electricCar);
      expect(VehicleTypeExtension.fromString('electric_car'), VehicleType.electricCar);
      expect(VehicleTypeExtension.fromString('ev_scooter'), VehicleType.electricScooter);
      expect(VehicleTypeExtension.fromString('bike'), VehicleType.motorcycle);
      expect(VehicleTypeExtension.fromString('auto'), VehicleType.autoRickshaw);
      expect(VehicleTypeExtension.fromString('mini-bus'), VehicleType.miniBus);
      expect(VehicleTypeExtension.fromString(null), VehicleType.sedan);
      expect(VehicleTypeExtension.fromString('unknown_type'), VehicleType.sedan);
    });

    test('Verify VehicleModel typed getter and backward compatibility', () {
      const model = VehicleModel(
        id: 'v1',
        ownerId: 'u1',
        registrationNumber: 'GJ01AB1234',
        vehicleType: 'suv',
        make: 'Tata',
        model: 'Harrier',
        year: 2023,
        color: 'Orcus White',
        seatCapacity: 5,
      );

      expect(model.type, VehicleType.suv);
      expect(model.typeDisplay, 'SUV');
      expect(model.displayName, 'Tata Harrier');
      expect(model.fullName, 'Tata Harrier (Orcus White)');
    });
  });

  group('Vehicle Vector Painters & Icon Widget Tests', () {
    testWidgets('Renders VehicleIllustrationPainter for all 19 vehicle types without error', (tester) async {
      for (final type in VehicleType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: VehicleIcon.illustration(type: type, width: 80, height: 48),
              ),
            ),
          ),
        );
        expect(find.byType(VehicleIcon), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Renders VehicleMarkerPainter with heading and active status without error', (tester) async {
      for (final type in VehicleType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: VehicleIcon.mapMarker(
                  type: type,
                  size: 56,
                  heading: 45.0,
                  isActive: true,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(VehicleIcon), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Renders VehicleIcon badge variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VehicleIcon.badge(type: VehicleType.electricCar, size: 40),
            ),
          ),
        ),
      );
      expect(find.byType(VehicleIcon), findsOneWidget);
    });
  });

  group('Google Maps Live Vehicle Marker Architecture Tests', () {
    test('Verify LiveVehicleMarkerData model', () {
      final now = DateTime.now();
      final data = LiveVehicleMarkerData(
        driverId: 'drv_123',
        rideId: 'ride_456',
        vehicleType: VehicleType.sedan,
        latitude: 23.0225,
        longitude: 72.5714,
        heading: 90.0,
        speed: 65.0,
        updatedAt: now,
        driverName: 'Suresh Mehta',
        vehiclePlate: 'GJ-01-XX-9999',
      );

      expect(data.position.latitude, 23.0225);
      expect(data.position.longitude, 72.5714);
      expect(data.heading, 90.0);
      expect(data.speed, 65.0);
      expect(data.isActive, true);

      final updated = data.copyWith(latitude: 23.0300, heading: 95.0);
      expect(updated.latitude, 23.0300);
      expect(updated.heading, 95.0);
    });
  });

  group('Match Score Visualization Tests', () {
    final testMatch = RouteMatchDetails(
      score: 94,
      grade: 'Exceptional Match',
      factors: const RouteMatchFactors(
        routeOverlap: 96,
        pickupDeviation: 90,
        destinationDeviation: 92,
        timeCompatibility: 95,
        driverReliability: 96,
        seatAvailability: 100,
      ),
      metrics: const RouteMatchMetrics(
        routeOverlapPercentage: 96,
        pickupDistanceKm: 0.8,
        destinationDistanceKm: 0.5,
        departureDifferenceMinutes: 5,
      ),
      reasons: const [
        '96% route corridor overlap along express highway',
        'Direct pickup within 800m of your requested point',
        'Departure within 5 minutes of your preferred time',
      ],
    );

    testWidgets('Renders SahyanMatchScoreBadge with score %', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SahyanMatchScoreBadge(score: 94),
          ),
        ),
      );

      expect(find.text('94% Match'), findsOneWidget);
    });

    testWidgets('Renders SahyanMatchScoreBreakdownCard explaining why ride matched', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SahyanMatchScoreBreakdownCard(matchDetails: testMatch),
            ),
          ),
        ),
      );

      expect(find.text('94%'), findsOneWidget);
      expect(find.text('Route Overlap'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget);
      expect(find.text('Pickup Deviation'), findsOneWidget);
      expect(find.text('0.8 km'), findsOneWidget);
      expect(find.text('Drop Deviation'), findsOneWidget);
      expect(find.text('0.5 km'), findsOneWidget);
      expect(find.text('Time Difference'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('Driver Reliability'), findsOneWidget);
      expect(find.text('4.8 / 5'), findsOneWidget);
      expect(find.text('96% route corridor overlap along express highway'), findsOneWidget);
    });
  });

  group('Responsive Viewport Tests - Zero Pixel Overflow', () {
    final viewports = [
      const Size(320, 600), // Narrow 320dp
      const Size(360, 640), // Standard 360dp
      const Size(390, 844), // Modern 390dp (iPhone 14)
      const Size(412, 915), // Large 412dp (Pixel 7)
      const Size(600, 960), // Tablet 600dp+
    ];

    for (final size in viewports) {
      testWidgets('Responsive Vehicle & Match Score UI on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Plus Jakarta Sans'),
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SahyanMatchScoreBadge(score: 92),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          VehicleIcon.illustration(
                            type: VehicleType.sedan,
                            width: 64,
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                          VehicleIcon.mapMarker(
                            type: VehicleType.sedan,
                            size: 44,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SahyanMatchScoreBreakdownCard(
                        matchDetails: RouteMatchDetails(
                          score: 88,
                          grade: 'High Route Compatibility',
                          factors: const RouteMatchFactors(
                            routeOverlap: 88,
                            pickupDeviation: 85,
                            destinationDeviation: 82,
                            timeCompatibility: 90,
                            driverReliability: 90,
                            seatAvailability: 80,
                          ),
                          metrics: const RouteMatchMetrics(
                            routeOverlapPercentage: 88,
                            pickupDistanceKm: 1.4,
                            destinationDistanceKm: 1.1,
                            departureDifferenceMinutes: 8,
                          ),
                          reasons: const ['High corridor overlap'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
