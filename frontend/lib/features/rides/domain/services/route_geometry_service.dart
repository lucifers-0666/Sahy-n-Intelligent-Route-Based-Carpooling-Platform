import 'dart:convert';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/features/rides/domain/ride_model.dart';
import 'package:sahyan/shared/models/location_model.dart';

class RouteGeometryResult {
  final RouteInfo route;
  final LatLngBounds bounds;
  final List<LatLng> polylineCoordinates;
  final String highwayName;
  final List<String> keyWaypoints;
  final String telemetrySummary;

  List<LatLng> get polylinePoints => polylineCoordinates;
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
  static const String _envApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static String? customApiKey;

  static String? get activeApiKey =>
      customApiKey ?? (_envApiKey.isNotEmpty ? _envApiKey : null);

  /// Get the designated Gujarat highway corridor name for origin and destination
  static String getHighwayCorridor(LocationModel origin, LocationModel dest) {
    return _detectGujaratHighway(origin, dest);
  }

  /// Calculate route using Directions API or offline curved highway geometry fallback
  static Future<RouteGeometryResult> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
    List<LocationModel> stopovers = const [],
    List<LocationModel> waypoints = const [],
  }) async {
    final activeStopovers = [...stopovers, ...waypoints];
    final apiKey = activeApiKey;

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '${activeStopovers.isNotEmpty ? "&waypoints=${activeStopovers.map((s) => "${s.latitude},${s.longitude}").join("|")}" : ""}'
          '&mode=driving&key=$apiKey',
        );

        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
            final routeJson = data['routes'][0] as Map<String, dynamic>;
            final overviewPolyline =
                routeJson['overview_polyline']?['points'] as String? ?? '';
            final leg = routeJson['legs']?[0] as Map<String, dynamic>?;
            final distanceMeters =
                (leg?['distance']?['value'] as num?)?.toDouble() ?? 0.0;
            final durationSeconds =
                (leg?['duration']?['value'] as num?)?.toInt() ?? 0;
            final summary =
                routeJson['summary'] as String? ?? 'Primary Highway';

            final decoded = RouteService.decodePolyline(overviewPolyline);
            final latLngList = decoded
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList();

            final bounds = calculateBounds(latLngList, origin, destination);
            final distKm = (distanceMeters / 1000).toStringAsFixed(0);
            final durHours = durationSeconds ~/ 3600;
            final durMins = (durationSeconds % 3600) ~/ 60;
            final durStr =
                durHours > 0 ? '${durHours}h ${durMins}m' : '${durMins}m';

            return RouteGeometryResult(
              route: RouteInfo(
                encodedPolyline: overviewPolyline,
                distanceMeters: distanceMeters,
                durationSeconds: durationSeconds,
              ),
              bounds: bounds,
              polylineCoordinates: latLngList,
              highwayName: summary,
              keyWaypoints: activeStopovers.map((s) => s.name).toList(),
              telemetrySummary: 'via $summary · $distKm km · $durStr',
            );
          }
        }
      } catch (_) {
        // Fall back gracefully to offline geometric interpolation
      }
    }

    return _generateOfflineFallbackRoute(
      origin: origin,
      destination: destination,
      stopovers: activeStopovers,
    );
  }

  /// Self-contained offline highway interpolation with realistic corridor curvature
  static RouteGeometryResult _generateOfflineFallbackRoute({
    required LocationModel origin,
    required LocationModel destination,
    List<LocationModel> stopovers = const [],
  }) {
    final directDistanceMeters = RouteService.calculateDistanceMeters(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Highway routing factor (1.18x road curvature factor over straight-line)
    final distanceMeters = directDistanceMeters * 1.18;
    // Average intercity highway speed ~ 68 km/h = 18.88 m/s
    final durationSeconds = (distanceMeters / 18.88).round();

    final List<LatLngPoint> points = [];
    points.add(LatLngPoint(origin.latitude, origin.longitude));

    // Incorporate stopovers if provided
    final allNodes = [
      LatLngPoint(origin.latitude, origin.longitude),
      ...stopovers.map((s) => LatLngPoint(s.latitude, s.longitude)),
      LatLngPoint(destination.latitude, destination.longitude),
    ];

    for (int i = 0; i < allNodes.length - 1; i++) {
      final start = allNodes[i];
      final end = allNodes[i + 1];
      const int segments = 12;

      for (int step = 1; step <= segments; step++) {
        final t = step / segments;
        // Interpolate with natural highway Bezier arc
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lng = start.longitude + (end.longitude - start.longitude) * t;
        // Micro deviation perpendicular to vector
        final deviation = math.sin(t * math.pi) * 0.012 * (i % 2 == 0 ? 1 : -1);
        points.add(LatLngPoint(lat + deviation * 0.3, lng + deviation));
      }
    }

    final encoded = RouteService.encodePolyline(points);
    final latLngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = calculateBounds(latLngs, origin, destination);

    final distKm = (distanceMeters / 1000).toStringAsFixed(0);
    final durHours = durationSeconds ~/ 3600;
    final durMins = (durationSeconds % 3600) ~/ 60;
    final durStr = durHours > 0 ? '${durHours}h ${durMins}m' : '${durMins}m';
    final highway = _detectGujaratHighway(origin, destination);

    final List<String> waypoints = stopovers.isNotEmpty
        ? stopovers.map((s) => s.name).toList()
        : _suggestDefaultWaypoints(origin, destination);

    return RouteGeometryResult(
      route: RouteInfo(
        encodedPolyline: encoded,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      ),
      bounds: bounds,
      polylineCoordinates: latLngs,
      highwayName: highway,
      keyWaypoints: waypoints,
      telemetrySummary: 'via $highway · $distKm km · $durStr',
    );
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

  static LatLngBounds calculateBounds(
    List<LatLng> points, [
    LocationModel? origin,
    LocationModel? destination,
  ]) {
    if (points.isEmpty) {
      final minLat = math.min(
        origin?.latitude ?? 22.0,
        destination?.latitude ?? 23.5,
      );
      final maxLat = math.max(
        origin?.latitude ?? 22.0,
        destination?.latitude ?? 23.5,
      );
      final minLng = math.min(
        origin?.longitude ?? 69.5,
        destination?.longitude ?? 73.0,
      );
      final maxLng = math.max(
        origin?.longitude ?? 69.5,
        destination?.longitude ?? 73.0,
      );
      return LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
