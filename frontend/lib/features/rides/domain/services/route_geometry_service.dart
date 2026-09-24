import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/core/network/api_config.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/features/rides/domain/ride_model.dart';
import 'package:sahyan/shared/models/location_model.dart';

class RouteGeometryResult {
  final RouteInfo route;
  final fmap.LatLngBounds bounds;
  final List<ll.LatLng> polylineCoordinates;
  final String highwayName;
  final List<String> keyWaypoints;
  final String telemetrySummary;

  List<ll.LatLng> get polylinePoints => polylineCoordinates;
  String get highwayCorridor => highwayName;
  double get distanceKm => route.distanceMeters / 1000.0;
  int get durationMinutes => (route.durationSeconds / 60).round();
  String get encodedPolyline => route.encodedPolyline;

  const RouteGeometryResult({
    required this.route,
    required this.bounds,
    required this.polylineCoordinates,
    required this.highwayName,
    required this.keyWaypoints,
    required this.telemetrySummary,
  });
}

typedef RouteCalculationResult = RouteGeometryResult;

class RouteGeometryService {
  /// Isolated test-only mock route provider hook
  @visibleForTesting
  static RouteGeometryResult Function(
    LocationModel origin,
    LocationModel destination,
    List<LocationModel> stopovers,
  )? mockRouteProvider;

  /// Get the designated Gujarat highway corridor name for origin and destination
  static String getHighwayCorridor(LocationModel origin, LocationModel dest) {
    return _detectGujaratHighway(origin, dest);
  }

  /// Calculate route using free OSRM route service via backend API.
  /// Does NOT synthesize fake roads. If OSRM fails, fails cleanly with route error.
  static Future<RouteGeometryResult> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
    List<LocationModel> stopovers = const [],
    List<LocationModel> waypoints = const [],
  }) async {
    final activeStopovers = [...stopovers, ...waypoints];

    try {
      final baseUrl = ApiConfig.baseUrl;
      final uri = Uri.parse('$baseUrl/rides/route/calculate');

      final body = jsonEncode({
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
          'name': origin.name,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
          'name': destination.name,
        },
      });

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['encodedPolyline'] != null) {
          final encodedPolyline = data['encodedPolyline'] as String;
          final distanceMeters =
              (data['distanceMeters'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds =
              (data['durationSeconds'] as num?)?.toInt() ?? 0;
          final highway = _detectGujaratHighway(origin, destination);

          final decoded = RouteService.decodePolyline(encodedPolyline);
          final latLngList = decoded
              .map((p) => ll.LatLng(p.latitude, p.longitude))
              .toList();

          final bounds = calculateBounds(latLngList, origin, destination);
          final distKm = (distanceMeters / 1000).toStringAsFixed(0);
          final durHours = durationSeconds ~/ 3600;
          final durMins = (durationSeconds % 3600) ~/ 60;
          final durStr =
              durHours > 0 ? '${durHours}h ${durMins}m' : '${durMins}m';

          final wps = activeStopovers.isNotEmpty
              ? activeStopovers.map((s) => s.name).toList()
              : _suggestDefaultWaypoints(origin, destination);

          return RouteGeometryResult(
            route: RouteInfo(
              encodedPolyline: encodedPolyline,
              distanceMeters: distanceMeters,
              durationSeconds: durationSeconds,
            ),
            bounds: bounds,
            polylineCoordinates: latLngList,
            highwayName: highway,
            keyWaypoints: wps,
            telemetrySummary: 'via $highway · $distKm km · $durStr',
          );
        }
      }
    } catch (_) {
      if (mockRouteProvider != null) {
        return mockRouteProvider!(origin, destination, activeStopovers);
      }
      throw Exception('Route unavailable. Please try again.');
    }

    if (mockRouteProvider != null) {
      return mockRouteProvider!(origin, destination, activeStopovers);
    }
    throw Exception('Route unavailable. Please try again.');
  }

  static String _detectGujaratHighway(LocationModel origin, LocationModel dest) {
    final text =
        '${origin.city} ${dest.city} ${origin.name} ${dest.name} ${origin.address} ${dest.address}'
            .toLowerCase();

    final isAmd =
        text.contains('ahmedabad') ||
        text.contains('iscon') ||
        (origin.latitude > 22.8 &&
            origin.latitude < 23.3 &&
            origin.longitude > 72.3 &&
            origin.longitude < 72.8);
    final isRaj =
        text.contains('rajkot') ||
        text.contains('kalawad') ||
        (dest.latitude > 22.1 &&
            dest.latitude < 22.5 &&
            dest.longitude > 70.6 &&
            dest.longitude < 71.0);

    if (isAmd && isRaj) {
      return 'NH47';
    }
    if (text.contains('ahmedabad') &&
        (text.contains('vadodara') ||
            text.contains('surat') ||
            text.contains('mumbai') ||
            text.contains('majura') ||
            text.contains('alkapuri'))) {
      return 'NE1 Express';
    }
    if (text.contains('bhuj') ||
        text.contains('kutch') ||
        text.contains('anjar') ||
        text.contains('jubilee')) {
      return 'NH27';
    }
    if (text.contains('gandhinagar') || text.contains('gift')) {
      return 'GIFT Highway';
    }
    return 'NH47';
  }

  static List<String> _suggestDefaultWaypoints(LocationModel origin, LocationModel dest) {
    final highway = _detectGujaratHighway(origin, dest);
    if (highway == 'NH47') {
      return ['Limbdi Toll Plaza', 'Chotila Bypass'];
    }
    if (highway == 'NE1 Express') {
      return ['Nadiad Toll', 'Anand Jn'];
    }
    if (highway == 'NH27') {
      return ['Maliya Toll', 'Samakhiali Circle'];
    }
    return ['Highway Rest Plaza'];
  }

  static fmap.LatLngBounds calculateBounds(
    List<ll.LatLng> points, [
    LocationModel? origin,
    LocationModel? destination,
  ]) {
    final validPoints = points
        .where((p) =>
            p.latitude >= -90.0 &&
            p.latitude <= 90.0 &&
            p.longitude >= -180.0 &&
            p.longitude <= 180.0)
        .toList();

    if (validPoints.isEmpty) {
      final minLat = math.min(
        origin?.latitude ?? 22.0,
        destination?.latitude ?? 23.5,
      ).clamp(-90.0, 90.0);
      final maxLat = math.max(
        origin?.latitude ?? 22.0,
        destination?.latitude ?? 23.5,
      ).clamp(-90.0, 90.0);
      final minLng = math.min(
        origin?.longitude ?? 69.5,
        destination?.longitude ?? 73.0,
      ).clamp(-180.0, 180.0);
      final maxLng = math.max(
        origin?.longitude ?? 69.5,
        destination?.longitude ?? 73.0,
      ).clamp(-180.0, 180.0);
      return fmap.LatLngBounds(
        ll.LatLng(minLat, minLng),
        ll.LatLng(maxLat, maxLng),
      );
    }

    double minLat = validPoints.first.latitude;
    double maxLat = validPoints.first.latitude;
    double minLng = validPoints.first.longitude;
    double maxLng = validPoints.first.longitude;

    for (final p in validPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return fmap.LatLngBounds(
      ll.LatLng(minLat.clamp(-90.0, 90.0), minLng.clamp(-180.0, 180.0)),
      ll.LatLng(maxLat.clamp(-90.0, 90.0), maxLng.clamp(-180.0, 180.0)),
    );
  }
}
