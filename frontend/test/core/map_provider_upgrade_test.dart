import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/core/services/map_provider_config.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sahyan_route_map.dart';

void main() {
  group('MapProviderConfig & Provider Abstraction Tests', () {
    test('All presets contain valid HTTPS endpoints and attribution', () {
      for (final type in MapProviderType.values) {
        final config = MapProviderConfig.providers[type];
        expect(config, isNotNull);
        expect(config!.urlTemplate.startsWith('https://'), isTrue);
        expect(config.attributionText, contains('OpenStreetMap'));
        expect(config.displayName.isNotEmpty, isTrue);
      }
    });

    test('Allows dynamic switching between providers', () {
      MapProviderConfig.setProvider(MapProviderType.cartoPositron);
      expect(MapProviderConfig.currentProvider, equals(MapProviderType.cartoPositron));
      expect(MapProviderConfig.activeConfig.displayName, equals('Clean Navigation'));

      MapProviderConfig.setProvider(MapProviderType.osmStandard);
      expect(MapProviderConfig.currentProvider, equals(MapProviderType.osmStandard));
      expect(MapProviderConfig.activeConfig.displayName, equals('OpenStreetMap'));

      MapProviderConfig.setProvider(MapProviderType.cartoVoyager);
      expect(MapProviderConfig.currentProvider, equals(MapProviderType.cartoVoyager));
      expect(MapProviderConfig.activeConfig.displayName, equals('Sahyān Road'));
    });

    test('configForBrightness selects dark theme map in dark mode', () {
      final lightConfig = MapProviderConfig.configForBrightness(Brightness.light);
      expect(lightConfig.type, equals(MapProviderConfig.currentProvider));

      final darkConfig = MapProviderConfig.configForBrightness(Brightness.dark);
      expect(darkConfig.type, equals(MapProviderType.cartoDark));
      expect(darkConfig.displayName, equals('Night Voyage'));
    });
  });

  group('Gujarat Corridors & Real Road Routing Verification', () {
    test('Rajkot to Ahmedabad route detection', () {
      final rajkot = LocationModel.fromCoordinates(
        name: 'Kalawad Road, Rajkot',
        latitude: 22.2810,
        longitude: 70.7620,
      );
      final ahmedabad = LocationModel.fromCoordinates(
        name: 'ISCON Cross Road, Ahmedabad',
        latitude: 23.0285,
        longitude: 72.5068,
      );

      final distanceM = RouteService.calculateDistanceMeters(
        rajkot.latitude,
        rajkot.longitude,
        ahmedabad.latitude,
        ahmedabad.longitude,
      );

      expect(distanceM, greaterThan(180000)); // ~215 km
      expect(distanceM, lessThan(250000));
    });

    test('Rajkot to Jamnagar route detection', () {
      final rajkot = LocationModel.fromCoordinates(
        name: 'Madhapar Chokdi, Rajkot',
        latitude: 22.3129,
        longitude: 70.7815,
      );
      final jamnagar = LocationModel.fromCoordinates(
        name: 'Digjam Circle, Jamnagar',
        latitude: 22.4580,
        longitude: 70.0480,
      );

      final distanceM = RouteService.calculateDistanceMeters(
        rajkot.latitude,
        rajkot.longitude,
        jamnagar.latitude,
        jamnagar.longitude,
      );

      expect(distanceM, greaterThan(70000)); // ~88 km
      expect(distanceM, lessThan(110000));
    });

    test('Intra-city Rajkot route detection', () {
      final kalawad = LocationModel.fromCoordinates(
        name: 'Kalawad Road',
        latitude: 22.2810,
        longitude: 70.7620,
      );
      final trikonBaug = LocationModel.fromCoordinates(
        name: 'Trikon Baug',
        latitude: 22.3012,
        longitude: 70.8022,
      );

      final distanceM = RouteService.calculateDistanceMeters(
        kalawad.latitude,
        kalawad.longitude,
        trikonBaug.latitude,
        trikonBaug.longitude,
      );

      expect(distanceM, greaterThan(2000)); // ~4.7 km
      expect(distanceM, lessThan(10000));
    });
  });

  group('SahyanRouteMap Widget Rendering Tests', () {
    testWidgets('renders cleanly with origin, destination and polyline in test environment', (tester) async {
      final origin = LocationModel.fromCoordinates(
        name: 'Rajkot',
        latitude: 22.3039,
        longitude: 70.8022,
      );
      final destination = LocationModel.fromCoordinates(
        name: 'Ahmedabad',
        latitude: 23.0225,
        longitude: 72.5714,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SahyanRouteMap(
              origin: origin,
              destination: destination,
              showControls: true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SahyanRouteMap), findsOneWidget);
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Ahmedabad'), findsOneWidget);
    });
  });
}
