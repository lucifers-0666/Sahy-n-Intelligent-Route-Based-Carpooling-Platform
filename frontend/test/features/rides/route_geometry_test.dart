import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sahyan/features/rides/domain/services/route_geometry_service.dart';
import 'package:sahyan/features/rides/presentation/widgets/location_search_bottom_sheet.dart';
import 'package:sahyan/features/trip/presentation/screens/live_ride_tracking_screen.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sayan_route_map.dart';

void main() {
  group('Phase 3: RouteGeometryService Unit Tests', () {
    final originAmd = LocationModel.fromCoordinates(
      name: 'Iscon Cross Roads',
      latitude: 23.0270,
      longitude: 72.5080,
    );
    final destRaj = LocationModel.fromCoordinates(
      name: 'Kalawad Road',
      latitude: 22.2850,
      longitude: 70.7720,
    );

    test(
      'calculates offline fallback curved polyline route accurately',
      () async {
        final result = await RouteGeometryService.calculateRoute(
          origin: originAmd,
          destination: destRaj,
        );

        expect(result.polylineCoordinates.isNotEmpty, isTrue);
        expect(result.polylineCoordinates.length, greaterThan(10));
        expect(result.distanceKm, greaterThan(200.0));
        expect(result.durationMinutes, greaterThan(150));
        expect(result.highwayCorridor, 'NH47');
        expect(result.route.encodedPolyline.isNotEmpty, isTrue);
      },
    );

    test(
      'incorporates highway stopovers into calculated route geometry',
      () async {
        final stopovers = [
          LocationModel.fromCoordinates(
            name: 'Limbdi Toll Plaza',
            latitude: 22.5645,
            longitude: 71.8080,
          ),
          LocationModel.fromCoordinates(
            name: 'Chotila Highway Circle',
            latitude: 22.4225,
            longitude: 71.1925,
          ),
        ];

        final result = await RouteGeometryService.calculateRoute(
          origin: originAmd,
          destination: destRaj,
          stopovers: stopovers,
        );

        expect(result.keyWaypoints.contains('Limbdi Toll Plaza'), isTrue);
        expect(result.keyWaypoints.contains('Chotila Highway Circle'), isTrue);
        expect(result.polylineCoordinates.length, greaterThan(20));
      },
    );

    test('detects designated Gujarat highway corridors correctly', () {
      const amd = LocationModel(
        name: 'Ahmedabad',
        address: 'Ahmedabad',
        city: 'Ahmedabad',
        latitude: 23.0225,
        longitude: 72.5714,
      );
      const raj = LocationModel(
        name: 'Rajkot',
        address: 'Rajkot',
        city: 'Rajkot',
        latitude: 22.3039,
        longitude: 70.8022,
      );
      const baroda = LocationModel(
        name: 'Vadodara',
        address: 'Vadodara',
        city: 'Vadodara',
        latitude: 22.3072,
        longitude: 73.1812,
      );
      const bhuj = LocationModel(
        name: 'Bhuj',
        address: 'Bhuj',
        city: 'Bhuj',
        latitude: 23.2420,
        longitude: 69.6669,
      );
      const gnr = LocationModel(
        name: 'Gandhinagar',
        address: 'Gandhinagar',
        city: 'Gandhinagar',
        latitude: 23.2156,
        longitude: 72.6369,
      );

      expect(RouteGeometryService.getHighwayCorridor(amd, raj), 'NH47');
      expect(
        RouteGeometryService.getHighwayCorridor(amd, baroda),
        'NE1 Express',
      );
      expect(RouteGeometryService.getHighwayCorridor(amd, bhuj), 'NH27');
      expect(RouteGeometryService.getHighwayCorridor(amd, gnr), 'GIFT Highway');
    });

    test('computes LatLngBounds enclosing all route points', () {
      final points = [
        const LatLng(23.0270, 72.5080),
        const LatLng(22.5645, 71.8080),
        const LatLng(22.2850, 70.7720),
      ];

      final bounds = RouteGeometryService.calculateBounds(points);
      expect(bounds.southwest.latitude, 22.2850);
      expect(bounds.northeast.latitude, 23.0270);
      expect(bounds.southwest.longitude, 70.7720);
      expect(bounds.northeast.longitude, 72.5080);
    });
  });

  group('Phase 3: Places Autocomplete & LocationPicker Sheet Widget Tests', () {
    testWidgets('displays Gujarat transport corridors and allows selection', (
      tester,
    ) async {
      LocationModel? selectedLocation;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedLocation = await LocationSearchBottomSheet.show(
                      context: context,
                      title: 'Select Pickup Hub',
                    );
                  },
                  child: const Text('Open Picker'),
                );
              },
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify header and action elements
      expect(find.text('Select Pickup Hub'), findsWidgets);
      expect(find.text('Use Current GPS Location'), findsOneWidget);
      expect(find.text('POPULAR GUJARAT CORRIDORS'), findsOneWidget);
      expect(find.text('Iscon Cross Roads'), findsOneWidget);
      expect(find.text('Kalawad Road'), findsOneWidget);
      expect(find.text('Majura Gate'), findsOneWidget);

      // Tap on Kalawad Road hub
      await tester.tap(find.text('Kalawad Road'));
      await tester.pumpAndSettle();

      // Verify selected location model returned
      expect(selectedLocation, isNotNull);
      expect(selectedLocation!.name, 'Kalawad Road');
      expect(selectedLocation!.city, 'Rajkot');
    });

    testWidgets(
      'filters Gujarat corridor hubs when user types in search query',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => LocationSearchBottomSheet.show(
                      context: context,
                      title: 'Search Destination',
                    ),
                    child: const Text('Search'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        // Type "Surat" in search field
        await tester.enterText(find.byType(TextField), 'Surat');
        await tester.pumpAndSettle();

        // Majura Gate in Surat should match
        expect(find.text('Majura Gate'), findsOneWidget);
        // Bhuj should be filtered out
        expect(find.text('Jubilee Ground'), findsNothing);
      },
    );
  });

  group('Phase 3: SayanRouteMap Widget Tests', () {
    final origin = LocationModel.fromCoordinates(
      name: 'Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
    );
    final destination = LocationModel.fromCoordinates(
      name: 'Rajkot',
      latitude: 22.3039,
      longitude: 70.8022,
    );

    testWidgets('renders headless vector fallback preview cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 360,
              child: SayanRouteMap(
                origin: origin,
                destination: destination,
                polylinePoints: const [
                  LatLng(23.0225, 72.5714),
                  LatLng(22.6, 71.6),
                  LatLng(22.3039, 70.8022),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In test environments, SayanRouteMap renders vector fallback
      expect(find.text('Ahmedabad'), findsOneWidget);
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Phase 3: LiveRideTrackingScreen Widget Tests', () {
    testWidgets('renders live tracking screen with dynamic glass card & dock', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveRideTrackingScreen(
            originName: 'Iscon Cross Roads, Ahmedabad',
            destinationName: 'Kalawad Road, Rajkot',
            driverName: 'Karan Patel',
            vehicleInfo: 'Hyundai Creta \u2022 GJ-01-AB-1234',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify app bar title
      expect(find.text('Live Tracking'), findsOneWidget);

      // Verify floating top glass card content
      expect(find.text('Karan Patel'), findsOneWidget);
      expect(find.text('Hyundai Creta \u2022 GJ-01-AB-1234'), findsOneWidget);

      // Verify 4 contact action buttons
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });
  });
}
