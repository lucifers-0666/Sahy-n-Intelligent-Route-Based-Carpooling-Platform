import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sahyan/core/location/data/providers/mock_location_provider.dart';
import 'package:sahyan/core/location/domain/distance_calculator.dart';
import 'package:sahyan/core/location/domain/gps_provider.dart';
import 'package:sahyan/core/location/domain/location_accuracy_policy.dart';
import 'package:sahyan/core/location/domain/location_filter.dart';
import 'package:sahyan/core/location/domain/models/location_point.dart';
import 'package:sahyan/core/location/services/distance_tracking_service.dart';
import 'package:sahyan/core/location/services/gps_diagnostic_service.dart';
import 'package:sahyan/core/location/services/location_preprocessor.dart';
import 'package:sahyan/core/location/services/route_progress_service.dart';
import 'package:sahyan/features/trip/presentation/screens/gps_diagnostic_screen.dart';

void main() {
  group('GPS Subsystem: DistanceCalculator & Bearing Pure Mathematical Tests', () {
    test('Haversine distance between Ahmedabad and Rajkot matches expected displacement', () {
      // Ahmedabad: 23.0225, 72.5714 -> Rajkot: 22.3039, 70.8022
      final distMeters = DistanceCalculator.haversineDistance(23.0225, 72.5714, 22.3039, 70.8022);
      final distKm = distMeters / 1000.0;
      expect(distKm, greaterThanOrEqualTo(195.0));
      expect(distKm, lessThanOrEqualTo(208.0));

      // Same coordinates return 0 distance
      expect(DistanceCalculator.haversineDistance(23.0225, 72.5714, 23.0225, 72.5714), 0.0);
    });

    test('Bearing calculation returns correct compass angles', () {
      // Due East
      final bearingEast = DistanceCalculator.calculateBearing(23.0, 72.0, 23.0, 73.0);
      expect(bearingEast, closeTo(90.0, 1.5));

      // Due North
      final bearingNorth = DistanceCalculator.calculateBearing(23.0, 72.0, 24.0, 72.0);
      expect(bearingNorth, closeTo(0.0, 1.5));

      // Due South
      final bearingSouth = DistanceCalculator.calculateBearing(23.0, 72.0, 22.0, 72.0);
      expect(bearingSouth, closeTo(180.0, 1.5));

      // Due West
      final bearingWest = DistanceCalculator.calculateBearing(23.0, 72.0, 23.0, 71.0);
      expect(bearingWest, closeTo(270.0, 1.5));
    });
  });

  group('GPS Subsystem: LocationAccuracyPolicy Tests', () {
    test('Classifies accuracy thresholds correctly', () {
      expect(LocationAccuracyPolicy.classify(5.0), LocationAccuracyTier.excellent);
      expect(LocationAccuracyPolicy.classify(15.0), LocationAccuracyTier.good);
      expect(LocationAccuracyPolicy.classify(35.0), LocationAccuracyTier.acceptable);
      expect(LocationAccuracyPolicy.classify(75.0), LocationAccuracyTier.poor);
      expect(LocationAccuracyPolicy.classify(150.0), LocationAccuracyTier.invalid);
    });

    test('Validates pickup and tracking acceptability thresholds', () {
      expect(LocationAccuracyPolicy.isAcceptableForPickup(15.0), true);
      expect(LocationAccuracyPolicy.isAcceptableForPickup(30.0), false);

      expect(LocationAccuracyPolicy.isAcceptableForTracking(40.0), true);
      expect(LocationAccuracyPolicy.isAcceptableForTracking(70.0), false);
    });
  });

  group('GPS Subsystem: LocationFilter Outlier & Freshness Tests', () {
    final filter = LocationFilter(config: LocationFilterConfig.forVehicleType('sedan'));

    test('Rejects stale timestamps older than 60 seconds', () {
      final freshPoint = LocationPoint(
        latitude: 23.0225,
        longitude: 72.5714,
        timestamp: DateTime.now(),
      );
      expect(filter.isValidTimestamp(freshPoint), true);

      final stalePoint = LocationPoint(
        latitude: 23.0225,
        longitude: 72.5714,
        timestamp: DateTime.now().subtract(const Duration(seconds: 90)),
      );
      expect(filter.isValidTimestamp(stalePoint), false);
    });

    test('Rejects physically impossible speed jumps', () {
      final t0 = DateTime.now();
      final p1 = LocationPoint(
        latitude: 23.0225,
        longitude: 72.5714,
        timestamp: t0,
      );

      // Normal displacement: 80 meters in 4 seconds = 20 m/s = 72 km/h
      final pNormal = LocationPoint(
        latitude: 23.0232,
        longitude: 72.5714,
        timestamp: t0.add(const Duration(seconds: 4)),
      );
      expect(filter.isOutlier(p1, pNormal), false);

      // Outlier jump: 15 km in 4 seconds = 3750 m/s = 13500 km/h
      final pOutlier = LocationPoint(
        latitude: 23.1500,
        longitude: 72.5714,
        timestamp: t0.add(const Duration(seconds: 4)),
      );
      expect(filter.isOutlier(p1, pOutlier), true);
    });
  });

  group('GPS Subsystem: LocationPreprocessor Pipeline Tests', () {
    test('Smooths coordinates and passes valid fixes through EMA filter', () {
      final preprocessor = LocationPreprocessor(smoothingAlpha: 0.5);
      final t0 = DateTime.now();

      final p1 = LocationPoint(
        latitude: 23.0000,
        longitude: 72.0000,
        accuracy: 8.0,
        speed: 40.0,
        heading: 90.0,
        timestamp: t0,
      );
      final res1 = preprocessor.process(p1);
      expect(res1, isNotNull);
      expect(res1!.latitude, 23.0000);
      expect(res1.longitude, 72.0000);

      // Second fix slightly moved
      final p2 = LocationPoint(
        latitude: 23.0010,
        longitude: 72.0010,
        accuracy: 10.0,
        speed: 45.0,
        heading: 90.0,
        timestamp: t0.add(const Duration(seconds: 5)),
      );
      final res2 = preprocessor.process(p2);
      expect(res2, isNotNull);
      // EMA: 23.0000 + 0.5 * (23.0010 - 23.0000) = 23.0005
      expect(res2!.latitude, closeTo(23.0005, 0.0001));
      expect(res2.longitude, closeTo(72.0005, 0.0001));

      // Reject fix with invalid accuracy > 100m
      final pBadAcc = LocationPoint(
        latitude: 23.0020,
        longitude: 72.0020,
        accuracy: 120.0,
        timestamp: t0.add(const Duration(seconds: 10)),
      );
      expect(preprocessor.process(pBadAcc), isNull);
    });
  });

  group('GPS Subsystem: DistanceTrackingService Tests', () {
    test('Accumulates cumulative tracked distance while suppressing stationary jitter', () {
      final tracker = DistanceTrackingService();
      final t0 = DateTime.now();

      final p1 = LocationPoint(latitude: 23.0000, longitude: 72.0000, timestamp: t0);
      tracker.addPoint(p1);
      expect(tracker.totalTrackedDistanceMeters, 0.0);

      // Micro-jitter (1 meter displacement) -> should be suppressed
      final pJitter = LocationPoint(
        latitude: 23.000008,
        longitude: 72.0000,
        timestamp: t0.add(const Duration(seconds: 1)),
      );
      tracker.addPoint(pJitter);
      expect(tracker.totalTrackedDistanceMeters, 0.0);

      // Real displacement (500 meters)
      final pMoved = LocationPoint(
        latitude: 23.0045,
        longitude: 72.0000,
        timestamp: t0.add(const Duration(seconds: 10)),
      );
      tracker.addPoint(pMoved);
      expect(tracker.totalTrackedDistanceMeters, greaterThan(400.0));
      expect(tracker.totalTrackedDistanceKm, greaterThan(0.4));
    });
  });

  group('GPS Subsystem: RouteProgressService Tests', () {
    final routePoints = [
      const LatLng(23.0225, 72.5714), // Ahmedabad
      const LatLng(22.6632, 71.6868), // Limbdi
      const LatLng(22.3039, 70.8022), // Rajkot
    ];
    final destination = const LatLng(22.3039, 70.8022);

    test('Calculates on-route progress fraction correctly', () {
      // Driver at Ahmedabad origin
      final posOrigin = LocationPoint(
        latitude: 23.0225,
        longitude: 72.5714,
        accuracy: 8.0,
        timestamp: DateTime.now(),
      );
      final resOrigin = RouteProgressService.evaluateProgress(
        currentPosition: posOrigin,
        polylinePoints: routePoints,
        destination: destination,
      );
      expect(resOrigin.isOffRoute, false);
      expect(resOrigin.progressFraction, lessThanOrEqualTo(0.05));

      // Driver at Limbdi midpoint
      final posMid = LocationPoint(
        latitude: 22.6632,
        longitude: 71.6868,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      final resMid = RouteProgressService.evaluateProgress(
        currentPosition: posMid,
        polylinePoints: routePoints,
        destination: destination,
      );
      expect(resMid.isOffRoute, false);
      expect(resMid.progressFraction, greaterThanOrEqualTo(0.35));
      expect(resMid.progressFraction, lessThanOrEqualTo(0.65));
    });

    test('Identifies off-route status for significant deviation', () {
      // Driver 20 km off route in Vadodara (22.3072, 73.1812)
      final posOff = LocationPoint(
        latitude: 22.3072,
        longitude: 73.1812,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      final resOff = RouteProgressService.evaluateProgress(
        currentPosition: posOff,
        polylinePoints: routePoints,
        destination: destination,
        offRouteThresholdMeters: 100.0,
      );
      expect(resOff.isOffRoute, true);
      expect(resOff.effectiveDeviationMeters, greaterThan(1000.0));
    });
  });

  group('GPS Subsystem: GpsDiagnosticService Tests', () {
    test('Diagnostic service reports healthy for valid provider', () async {
      final mock = MockLocationProvider();
      final diagnostic = GpsDiagnosticService(mock);

      final result = await diagnostic.runDiagnostics();
      expect(result.locationServicesEnabled, true);
      expect(result.permissionStatus, LocationPermissionStatus.granted);
      expect(result.hasPosition, true);
      expect(result.isHealthy, true);
    });

    test('Diagnostic service flags disabled location services', () async {
      final mock = MockLocationProvider();
      mock.setServiceEnabled(false);
      final diagnostic = GpsDiagnosticService(mock);

      final result = await diagnostic.runDiagnostics();
      expect(result.locationServicesEnabled, false);
      expect(result.isHealthy, false);
      expect(result.errorCode, 'LOCATION_SERVICES_DISABLED');
    });

    test('Diagnostic service flags denied permissions', () async {
      final mock = MockLocationProvider();
      mock.setPermissionStatus(LocationPermissionStatus.deniedForever);
      final diagnostic = GpsDiagnosticService(mock);

      final result = await diagnostic.runDiagnostics();
      expect(result.permissionStatus, LocationPermissionStatus.deniedForever);
      expect(result.isHealthy, false);
      expect(result.errorCode, 'PERMISSION_DENIEDFOREVER');
    });
  });

  group('GPS Subsystem: GpsDiagnosticScreen Widget Tests', () {
    testWidgets('Renders diagnostic console and updates telemetry stream', (tester) async {
      final mock = MockLocationProvider(
        initialPoint: LocationPoint(
          latitude: 23.0225,
          longitude: 72.5714,
          accuracy: 6.5,
          speed: 48.0,
          heading: 120.0,
          timestamp: DateTime.now(),
          provider: 'mock',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GpsDiagnosticScreen(customProvider: mock),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GPS Diagnostic Console'), findsOneWidget);
      expect(find.text('GPS Subsystem Healthy'), findsOneWidget);
      expect(find.text('Location Services'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('23.022500'), findsWidgets);
      expect(find.text('72.571400'), findsWidgets);
    });
  });
}
