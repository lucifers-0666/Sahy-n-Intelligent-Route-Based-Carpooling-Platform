import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/shared/models/location_model.dart';

/// Minimalist Luxury Light theme JSON styling for Google Maps
const String kSahyanMapStyle = '''
[
  {
    "featureType": "administrative",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#444444"}]
  },
  {
    "featureType": "landscape",
    "elementType": "all",
    "stylers": [{"color": "#F4F7F5"}]
  },
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "all",
    "stylers": [{"saturation": -100}, {"lightness": 45}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#E2EBE5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#CBD8D0"}, {"weight": 1}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#FFFFFF"}]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "water",
    "elementType": "all",
    "stylers": [{"color": "#D5E5DC"}, {"visibility": "on"}]
  }
]
''';

/// Canonical Sahyān Route Map widget with real-time polyline rendering,
/// live vehicle marker animation, and camera tracking.
class SahyanRouteMap extends StatefulWidget {
  final LocationModel origin;
  final LocationModel destination;
  final List<LatLng> polylinePoints;
  final List<LocationModel> stopovers;
  final LatLng? driverPosition;
  final double? driverHeading;
  final LatLngBounds? bounds;
  final bool interactive;
  final bool showControls;
  final double? height;
  final void Function(GoogleMapController controller)? onMapCreated;

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
  GoogleMapController? _mapController;
  bool _isMapReady = false;

  // ── Interpolation state ──────────────────────────────────────────────────
  late AnimationController _interpolationController;
  late Animation<double> _interpolationAnim;

  LatLng? _prevDriverPos;
  LatLng? _currentDriverPos;
  double _prevHeading = 0.0;
  double _currentHeading = 0.0;
  LatLng? _displayDriverPos;
  double _displayHeading = 0.0;

  // ── Custom marker icon cache ─────────────────────────────────────────────
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  BitmapDescriptor? _vehicleMarkerIcon;

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

    _displayDriverPos = widget.driverPosition;
    _displayHeading = widget.driverHeading ?? 0.0;
    _prevDriverPos = widget.driverPosition;
    _currentDriverPos = widget.driverPosition;

    _interpolationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _interpolationAnim = CurvedAnimation(
      parent: _interpolationController,
      curve: Curves.easeInOut,
    );

    _interpolationController.addListener(_onInterpolationTick);

    if (widget.vehicleTypeCode != null && !_isTestingEnvironment) {
      _loadVehicleMarkerIcon(widget.vehicleTypeCode!);
    }
  }

  @override
  void didUpdateWidget(covariant SayanRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_mapController != null && _isMapReady && widget.bounds != null) {
      _fitBounds();
    }

    // New driver position received — start interpolation
    if (widget.driverPosition != null &&
        widget.driverPosition != oldWidget.driverPosition) {
      _prevDriverPos = _displayDriverPos ?? widget.driverPosition;
      _prevHeading = _displayHeading;
      _currentDriverPos = widget.driverPosition;
      _currentHeading = _shortestHeading(_prevHeading, widget.driverHeading ?? 0.0);

      _interpolationController.forward(from: 0.0);
    }

    if (widget.vehicleTypeCode != oldWidget.vehicleTypeCode &&
        widget.vehicleTypeCode != null &&
        !_isTestingEnvironment) {
      _loadVehicleMarkerIcon(widget.vehicleTypeCode!);
    }
  }

  @override
  void dispose() {
    _interpolationController.dispose();
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
      _displayDriverPos = LatLng(lat, lng);
      _displayHeading = heading;
    });

    // Camera follow
    if (widget.followVehicle && _isMapReady && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  /// Returns the shortest angular delta so heading never wraps 359→1 as +358°.
  double _shortestHeading(double from, double to) {
    double delta = (to - from + 360) % 360;
    if (delta > 180) delta -= 360;
    return from + delta;
  }

  // ── Custom marker icon ───────────────────────────────────────────────────

  Future<void> _loadVehicleMarkerIcon(String typeCode) async {
    // Check cache first
    if (_markerIconCache.containsKey(typeCode)) {
      if (mounted) setState(() => _vehicleMarkerIcon = _markerIconCache[typeCode]);
      return;
    }

    final Color markerColor = _colorForVehicleType(typeCode);

    try {
      // Try loading asset icon if it exists
      final assetPath = 'assets/icons/vehicles/$typeCode/icon.png';
      final bytes = await _tryLoadAsset(assetPath);
      if (bytes != null) {
        final descriptor = BitmapDescriptor.bytes(bytes, width: 48, height: 48);
        _markerIconCache[typeCode] = descriptor;
        if (mounted) setState(() => _vehicleMarkerIcon = descriptor);
        return;
      }
    } catch (_) {
      // Fall through to canvas-drawn marker
    }

    // Fallback: draw a canvas-based arrow marker
    final descriptor = await _buildCanvasVehicleMarker(markerColor);
    _markerIconCache[typeCode] = descriptor;
    if (mounted) setState(() => _vehicleMarkerIcon = descriptor);
  }

  Future<Uint8List?> _tryLoadAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<BitmapDescriptor> _buildCanvasVehicleMarker(Color color) async {
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 2), size / 2 - 6, shadowPaint);

    // Circle background
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 6, bgPaint);

    // White ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 6, ringPaint);

    // Arrow pointing up (north)
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(size / 2, 10)
      ..lineTo(size / 2 - 7, size - 12)
      ..lineTo(size / 2, size - 18)
      ..lineTo(size / 2 + 7, size - 12)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: size, height: size);
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
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(widget.bounds!, 48.0),
      );
    } catch (_) {}
  }

  Set<Polyline> _buildPolylines() {
    if (widget.polylinePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route_glow'),
        points: widget.polylinePoints,
        color: SahyanColors.primaryMint.withValues(alpha: 0.35),
        width: 8,
      ),
      Polyline(
        polylineId: const PolylineId('route_primary'),
        points: widget.polylinePoints,
        color: SahyanColors.primaryDark,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    markers.add(Marker(
      markerId: const MarkerId('origin_marker'),
      position: LatLng(widget.origin.latitude, widget.origin.longitude),
      infoWindow: InfoWindow(
        title: 'Pickup: ${widget.origin.name}',
        snippet: widget.origin.city,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    markers.add(Marker(
      markerId: const MarkerId('destination_marker'),
      position: LatLng(widget.destination.latitude, widget.destination.longitude),
      infoWindow: InfoWindow(
        title: 'Drop: ${widget.destination.name}',
        snippet: widget.destination.city,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
    ));

    for (int i = 0; i < widget.stopovers.length; i++) {
      final stop = widget.stopovers[i];
      markers.add(Marker(
        markerId: MarkerId('stopover_${i}_${stop.name}'),
        position: LatLng(stop.latitude, stop.longitude),
        infoWindow: InfoWindow(title: 'Stop: ${stop.name}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Driver vehicle marker — uses interpolated position & heading
    final driverPos = _displayDriverPos ?? widget.driverPosition;
    if (driverPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver_vehicle_marker'),
        position: driverPos,
        rotation: _displayHeading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Driver Live Location'),
        icon: _vehicleMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }

    return markers;
  }

  CameraPosition _getInitialCameraPosition() {
    final lat = (widget.origin.latitude + widget.destination.latitude) / 2;
    final lng = (widget.origin.longitude + widget.destination.longitude) / 2;
    return CameraPosition(target: LatLng(lat, lng), zoom: 8.5);
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
                GoogleMap(
                  style: kSahyanMapStyle,
                  initialCameraPosition: _getInitialCameraPosition(),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _isMapReady = true;
                    _fitBounds();
                    widget.onMapCreated?.call(controller);
                  },
                  polylines: _buildPolylines(),
                  markers: _buildMarkers(),
                  zoomControlsEnabled: widget.showControls,
                  compassEnabled: widget.interactive,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  scrollGesturesEnabled: widget.interactive,
                  zoomGesturesEnabled: widget.interactive,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: widget.interactive,
                  mapToolbarEnabled: false,
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

                // ── Follow / Free-pan toggle FAB ───────────────────────────
                if (widget.driverPosition != null && widget.onFollowToggle != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
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
              driverPosition: _displayDriverPos ?? widget.driverPosition,
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
  final List<LatLng> points;
  final LocationModel origin;
  final LocationModel destination;
  final LatLng? driverPosition;
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
