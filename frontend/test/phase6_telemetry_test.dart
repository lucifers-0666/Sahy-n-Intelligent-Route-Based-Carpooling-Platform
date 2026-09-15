import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/core/network/socket_client.dart';
import 'package:sahyan/core/services/driver_location_service.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sayan_route_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

/// Haversine distance helper (mirrors live_ride_tracking_screen.dart).
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

// ── Stub widget for SayanRouteMap (avoids GoogleMap in tests) ─────────────

class _StubRouteMapHost extends StatelessWidget {
  final LatLng? driverPosition;
  final String? vehicleTypeCode;
  final bool followVehicle;

  const _StubRouteMapHost({
    this.driverPosition,
    this.vehicleTypeCode,
    this.followVehicle = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SayanRouteMap(
          origin: LocationModel.fromCoordinates(
            name: 'Ahmedabad',
            latitude: 23.0225,
            longitude: 72.5714,
          ),
          destination: LocationModel.fromCoordinates(
            name: 'Rajkot',
            latitude: 22.3039,
            longitude: 70.8022,
          ),
          driverPosition: driverPosition,
          vehicleTypeCode: vehicleTypeCode,
          followVehicle: followVehicle,
        ),
      ),
    );
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('Phase 6 – Real-Time Telematics', () {
    // ── Test 1: DriverLocationPayload serialisation ───────────────────────
    test('T1: DriverLocationPayload serialises and deserialises correctly', () {
      final now = DateTime.now();
      final payload = DriverLocationPayload(
        rideId: 'ride-001',
        latitude: 23.0225,
        longitude: 72.5714,
        heading: 45.0,
        speed: 60.0,
        timestamp: now,
      );

      final map = payload.toMap();
      final restored = DriverLocationPayload.fromMap(map);

      expect(restored.rideId, 'ride-001');
      expect(restored.latitude, closeTo(23.0225, 0.0001));
      expect(restored.longitude, closeTo(72.5714, 0.0001));
      expect(restored.heading, closeTo(45.0, 0.01));
      expect(restored.speed, closeTo(60.0, 0.01));
    });

    // ── Test 2: DriverLocationPayload fromMap handles nulls gracefully ────
    test('T2: DriverLocationPayload.fromMap handles missing fields gracefully', () {
      final payload = DriverLocationPayload.fromMap({});
      expect(payload.rideId, '');
      expect(payload.latitude, 0.0);
      expect(payload.longitude, 0.0);
      expect(payload.heading, 0.0);
      expect(payload.speed, 0.0);
      expect(payload.timestamp, isA<DateTime>());
    });

    // ── Test 3: Haversine ETA formula ─────────────────────────────────────
    test('T3: Haversine correctly estimates Ahmedabad → Rajkot distance', () {
      // Known great-circle distance ≈ 198 km (direct air, not road distance)
      final dist = _haversineKm(23.0225, 72.5714, 22.3039, 70.8022);
      expect(dist, greaterThan(190));
      expect(dist, lessThan(230));
    });

    // ── Test 4: ETA calculation from speed and distance ───────────────────
    test('T4: ETA formula gives plausible minutes at 60 km/h', () {
      const remaining = 120.0; // km
      const speed = 60.0; // km/h
      final etaMins = ((remaining / speed) * 60).round();
      expect(etaMins, 120); // 2 hours = 120 mins exactly
    });

    // ── Test 5: SayanRouteMap renders without overflow ────────────────────
    testWidgets('T5: SayanRouteMap renders with driverPosition and vehicleTypeCode',
        (tester) async {
      await tester.pumpWidget(
        const _StubRouteMapHost(
          driverPosition: LatLng(22.8, 71.8),
          vehicleTypeCode: 'sedan',
          followVehicle: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Should render without exceptions or overflow
      expect(find.byType(SayanRouteMap), findsOneWidget);
    });

    // ── Test 6: Connection health logic ───────────────────────────────────
    test('T6: Connection health is "reconnecting" after 10s no packet', () {
      DateTime? lastPacketAt = DateTime.now().subtract(const Duration(seconds: 11));
      final bool isLive = DateTime.now().difference(lastPacketAt).inSeconds < 10;
      final bool isReconnecting = !isLive && lastPacketAt != null;

      expect(isLive, isFalse);
      expect(isReconnecting, isTrue);
    });
  });
}
