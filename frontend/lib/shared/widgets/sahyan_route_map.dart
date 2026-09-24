import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/shared/models/location_model.dart';

/// Helper to convert any LatLng-like coordinate object to latlong2.LatLng
ll.LatLng toLatLong(dynamic point) {
  if (point is ll.LatLng) return point;
  return ll.LatLng(
    (point.latitude as num).toDouble(),
    (point.longitude as num).toDouble(),
  );
}

/// Canonical Sahyān Route Map widget with real-time polyline rendering,
/// live vehicle marker animation, and camera tracking powered by OpenStreetMap.
class SahyanRouteMap extends StatefulWidget {
  final LocationModel origin;
  final LocationModel destination;
  final List<dynamic> polylinePoints;
  final List<LocationModel> stopovers;
  final dynamic driverPosition;
  final double? driverHeading;
  final dynamic bounds;
  final bool interactive;
  final bool showControls;
  final double? height;
  final void Function(dynamic controller)? onMapCreated;

  /// Vehicle type code used to select the marker icon colour.
  /// Accepted values: 'sedan','suv','hatchback','ev','motorcycle', etc.
  final String? vehicleTypeCode;

  /// When true the camera tracks the driver marker automatically.
  final bool followVehicle;

  /// Called when the user toggles the Follow / Free-pan button.
  final ValueChanged<bool>? onFollowToggle;

  const SahyanRouteMap({
    super.key,
    required this.origin,
    required this.destination,
    this.polylinePoints = const [],
    this.stopovers = const [],
    this.driverPosition,
    this.driverHeading,
    this.bounds,
    this.interactive = true,
    this.showControls = false,
    this.height,
    this.onMapCreated,
    this.vehicleTypeCode,
    this.followVehicle = false,
    this.onFollowToggle,
  });

  @override
  State<SahyanRouteMap> createState() => _SahyanRouteMapState();
}

/// Backwards compatibility alias for SayanRouteMap
typedef SayanRouteMap = SahyanRouteMap;

class _SahyanRouteMapState extends State<SahyanRouteMap>
    with SingleTickerProviderStateMixin {
  fmap.MapController? _mapController;
  bool _isMapReady = false;

  // ── Interpolation state ──────────────────────────────────────────────────
  late AnimationController _interpolationController;
  late Animation<double> _interpolationAnim;

  ll.LatLng? _prevDriverPos;
  ll.LatLng? _currentDriverPos;
  double _prevHeading = 0.0;
  double _currentHeading = 0.0;
  ll.LatLng? _displayDriverPos;
  double _displayHeading = 0.0;

  /// Determine if running in a web or headless widget test environment
  bool get _isTestingEnvironment {
    if (kIsWeb) return true;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _mapController = fmap.MapController();

    if (widget.driverPosition != null) {
      final pos = toLatLong(widget.driverPosition);
      _displayDriverPos = pos;
      _prevDriverPos = pos;
      _currentDriverPos = pos;
    }
    _displayHeading = widget.driverHeading ?? 0.0;

    _interpolationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _interpolationAnim = CurvedAnimation(
      parent: _interpolationController,
      curve: Curves.easeInOut,
    );

    _interpolationController.addListener(_onInterpolationTick);
  }

  @override
  void didUpdateWidget(covariant SahyanRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_mapController != null && _isMapReady && widget.bounds != null) {
      _fitBounds();
    }

    // New driver position received — start interpolation
    if (widget.driverPosition != null &&
        widget.driverPosition != oldWidget.driverPosition) {
      final newPos = toLatLong(widget.driverPosition);
      _prevDriverPos = _displayDriverPos ?? newPos;
      _prevHeading = _displayHeading;
      _currentDriverPos = newPos;
      _currentHeading = _shortestHeading(_prevHeading, widget.driverHeading ?? 0.0);

      _interpolationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _interpolationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Interpolation ────────────────────────────────────────────────────────

  void _onInterpolationTick() {
    final t = _interpolationAnim.value;
    final from = _prevDriverPos;
    final to = _currentDriverPos;
    if (from == null || to == null) return;

    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    final heading = _prevHeading + (_currentHeading - _prevHeading) * t;

    setState(() {
      _displayDriverPos = ll.LatLng(lat, lng);
      _displayHeading = heading;
    });

    // Camera follow
    if (widget.followVehicle && _isMapReady && _mapController != null) {
      try {
        _mapController!.move(ll.LatLng(lat, lng), _mapController!.camera.zoom);
      } catch (_) {}
    }
  }

  /// Returns the shortest angular delta so heading never wraps 359 to 1 as +358 degrees.
  double _shortestHeading(double from, double to) {
    double delta = (to - from + 360) % 360;
    if (delta > 180) delta -= 360;
    return from + delta;
  }

  Color _colorForVehicleType(String code) {
    switch (code) {
      case 'ev':
      case 'electric_car':
      case 'electric_scooter':
        return const Color(0xFF10B981); // Emerald for EVs
      case 'motorcycle':
      case 'scooter':
        return const Color(0xFFF59E0B); // Amber for two-wheelers
      case 'auto_rickshaw':
      case 'electric_auto_rickshaw':
        return const Color(0xFF8B5CF6); // Purple for three-wheelers
      case 'suv':
      case 'muv':
      case 'crossover':
        return const Color(0xFF0F172A); // Deep blue for SUVs
      default:
        return SahyanColors.primaryDark; // Default deep pine
    }
  }

  // ── Map builders ─────────────────────────────────────────────────────────

  void _fitBounds() {
    if (widget.bounds == null || _mapController == null) return;
    try {
      final sw = toLatLong(widget.bounds.southwest);
      final ne = toLatLong(widget.bounds.northeast);
      _mapController!.fitCamera(
        fmap.CameraFit.bounds(
          bounds: fmap.LatLngBounds(sw, ne),
          padding: const EdgeInsets.all(48.0),
        ),
      );
    } catch (_) {}
  }

  List<fmap.Polyline> _buildPolylines() {
    if (widget.polylinePoints.isEmpty) return [];
    final points = widget.polylinePoints.map(toLatLong).toList();
    return [
      fmap.Polyline(
        points: points,
        color: SahyanColors.primaryMint.withValues(alpha: 0.35),
        strokeWidth: 8,
      ),
      fmap.Polyline(
        points: points,
        color: SahyanColors.primaryDark,
        strokeWidth: 4,
      ),
    ];
  }

  List<fmap.Marker> _buildMarkers() {
    final markers = <fmap.Marker>[];

    // Origin marker
    markers.add(
      fmap.Marker(
        point: ll.LatLng(widget.origin.latitude, widget.origin.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: SahyanColors.primaryDark,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.trip_origin_rounded, size: 20, color: Colors.white),
        ),
      ),
    );

    // Destination marker
    markers.add(
      fmap.Marker(
        point: ll.LatLng(widget.destination.latitude, widget.destination.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: SahyanColors.primaryMint,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.location_on_rounded, size: 22, color: Colors.white),
        ),
      ),
    );

    // Stopovers
    for (int i = 0; i < widget.stopovers.length; i++) {
      final stop = widget.stopovers[i];
      markers.add(
        fmap.Marker(
          point: ll.LatLng(stop.latitude, stop.longitude),
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.flag_rounded, size: 16, color: Colors.white),
          ),
        ),
      );
    }

    // Driver vehicle marker — uses interpolated position & heading
    final driverPos = _displayDriverPos ?? (widget.driverPosition != null ? toLatLong(widget.driverPosition) : null);
    if (driverPos != null) {
      markers.add(
        fmap.Marker(
          point: driverPos,
          width: 50,
          height: 50,
          child: Transform.rotate(
            angle: _displayHeading * math.pi / 180.0,
            child: Container(
              decoration: BoxDecoration(
                color: _colorForVehicleType(widget.vehicleTypeCode ?? ''),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.navigation_rounded, size: 26, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  ll.LatLng _getInitialCenter() {
    final lat = (widget.origin.latitude + widget.destination.latitude) / 2;
    final lng = (widget.origin.longitude + widget.destination.longitude) / 2;
    return ll.LatLng(lat, lng);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: _isTestingEnvironment
          ? _buildVectorFallbackPreview()
          : Stack(
              children: [
                fmap.FlutterMap(
                  mapController: _mapController,
                  options: fmap.MapOptions(
                    initialCenter: _getInitialCenter(),
                    initialZoom: 8.5,
                    interactionOptions: fmap.InteractionOptions(
                      flags: widget.interactive
                          ? fmap.InteractiveFlag.all
                          : fmap.InteractiveFlag.none,
                    ),
                    onMapReady: () {
                      _isMapReady = true;
                      _fitBounds();
                      widget.onMapCreated?.call(_mapController);
                    },
                  ),
                  children: [
                    fmap.TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sahyan.sahyan',
                      maxZoom: 19,
                    ),
                    fmap.PolylineLayer(
                      polylines: _buildPolylines(),
                    ),
                    fmap.MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),

                // ── Live Route Corridor badge ──────────────────────────────
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: SahyanColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SahyanColors.border, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar_rounded, size: 14, color: SahyanColors.primaryMint),
                        SizedBox(width: 6),
                        Text(
                          'Live Route Corridor',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: SahyanColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── OpenStreetMap Attribution ──────────────────────────────
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: SahyanColors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OpenStreetMap',
                      style: TextStyle(
                        fontSize: 9,
                        color: SahyanColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // ── Follow / Free-pan toggle FAB ───────────────────────────
                if (widget.driverPosition != null && widget.onFollowToggle != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => widget.onFollowToggle!(!widget.followVehicle),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.followVehicle
                              ? SahyanColors.primaryMint
                              : SahyanColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.followVehicle
                                ? SahyanColors.primaryMint
                                : SahyanColors.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.followVehicle
                                  ? Icons.navigation_rounded
                                  : Icons.pan_tool_rounded,
                              size: 16,
                              color: widget.followVehicle
                                  ? Colors.white
                                  : SahyanColors.textMain,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.followVehicle ? 'Following' : 'Free Pan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.followVehicle
                                    ? Colors.white
                                    : SahyanColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, width: double.infinity, child: content);
    }
    return content;
  }

  // ── Vector fallback for tests ────────────────────────────────────────────

  Widget _buildVectorFallbackPreview() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F6F3),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _SayanVectorRoutePainter(
              points: widget.polylinePoints,
              origin: widget.origin,
              destination: widget.destination,
              driverPosition: _displayDriverPos ??
                  (widget.driverPosition != null ? toLatLong(widget.driverPosition) : null),
              driverHeading: _displayHeading,
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SahyanColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SahyanColors.border, width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 13, color: SahyanColors.primaryDark),
                  SizedBox(width: 4),
                  Text(
                    'Interactive Route Preview',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SahyanColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SahyanColors.border, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trip_origin, size: 12, color: SahyanColors.primaryDark),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.origin.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 10, color: SahyanColors.textMuted),
                  ),
                  const Icon(Icons.location_on, size: 12, color: SahyanColors.primaryMint),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.destination.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vector route painter ───────────────────────────────────────────────────

class _SayanVectorRoutePainter extends CustomPainter {
  final List<dynamic> points;
  final LocationModel origin;
  final LocationModel destination;
  final dynamic driverPosition;
  final double driverHeading;

  const _SayanVectorRoutePainter({
    required this.points,
    required this.origin,
    required this.destination,
    this.driverPosition,
    this.driverHeading = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Background grid
    final gridPaint = Paint()
      ..color = SahyanColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final p1 = Offset(size.width * 0.18, size.height * 0.76);
    final p2 = Offset(size.width * 0.82, size.height * 0.24);

    // Route polyline
    final glowPaint = Paint()
      ..color = SahyanColors.primaryMint.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = SahyanColors.primaryDark
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (points.length > 2) {
      final ctrl = Offset((p1.dx + p2.dx) / 2 + 25, (p1.dy + p2.dy) / 2 - 20);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    // Origin marker
    canvas.drawCircle(p1, 9, Paint()..color = SahyanColors.primaryDark);
    canvas.drawCircle(p1, 4, Paint()..color = Colors.white);

    // Destination marker
    canvas.drawCircle(p2, 9, Paint()..color = SahyanColors.primaryMint);
    canvas.drawCircle(p2, 4, Paint()..color = SahyanColors.primaryDark);

    // Driver position with bearing arrow
    if (driverPosition != null) {
      final carPos = Offset(
        p1.dx + (p2.dx - p1.dx) * 0.45,
        p1.dy + (p2.dy - p1.dy) * 0.45,
      );
      final carPaint = Paint()..color = SahyanColors.urgentCoral;
      canvas.drawCircle(carPos, 9, carPaint);
      canvas.drawCircle(carPos, 4, Paint()..color = Colors.white);

      // Bearing arrow
      final headingRad = driverHeading * math.pi / 180.0;
      final arrowPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final arrowEnd = Offset(
        carPos.dx + math.sin(headingRad) * 14,
        carPos.dy - math.cos(headingRad) * 14,
      );
      canvas.drawLine(carPos, arrowEnd, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SayanVectorRoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.driverPosition != driverPosition ||
        oldDelegate.driverHeading != driverHeading;
  }
}
