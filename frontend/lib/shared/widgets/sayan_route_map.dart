import 'dart:io';
import 'package:flutter/material.dart';
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
    "stylers": [{"color": "#CBD8D0"}, {"weight": 1.2}]
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

class SayanRouteMap extends StatefulWidget {
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

  const SayanRouteMap({
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
  });

  @override
  State<SayanRouteMap> createState() => _SayanRouteMapState();
}

class _SayanRouteMapState extends State<SayanRouteMap> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;

  /// Determine if running in a headless widget test environment
  bool get _isTestingEnvironment {
    // In headless test environments (flutter_test), platform views are not supported
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void didUpdateWidget(covariant SayanRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapController != null && _isMapReady && widget.bounds != null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.bounds == null || _mapController == null) return;
    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(widget.bounds!, 48.0),
      );
    } catch (_) {
      // Bounds animation fallback
    }
  }

  Set<Polyline> _buildPolylines() {
    if (widget.polylinePoints.isEmpty) return {};

    return {
      // Outer subtle glow line
      Polyline(
        polylineId: const PolylineId('route_glow'),
        points: widget.polylinePoints,
        color: SahyanColors.primaryMint.withValues(alpha: 0.35),
        width: 8,
      ),
      // Inner deep pine primary route line
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

    // Origin Marker (Deep Pine)
    markers.add(
      Marker(
        markerId: const MarkerId('origin_marker'),
        position: LatLng(widget.origin.latitude, widget.origin.longitude),
        infoWindow: InfoWindow(
          title: 'Pickup: ${widget.origin.name}',
          snippet: widget.origin.city,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Destination Marker (Mint)
    markers.add(
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Drop: ${widget.destination.name}',
          snippet: widget.destination.city,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    );

    // Stopovers Markers
    for (int i = 0; i < widget.stopovers.length; i++) {
      final stop = widget.stopovers[i];
      markers.add(
        Marker(
          markerId: MarkerId('stopover_${i}_${stop.name}'),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(title: 'Stop: ${stop.name}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // Driver Vehicle Marker (if live tracking)
    if (widget.driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_vehicle_marker'),
          position: widget.driverPosition!,
          rotation: widget.driverHeading ?? 0.0,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Driver Live Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    return markers;
  }

  CameraPosition _getInitialCameraPosition() {
    final lat = (widget.origin.latitude + widget.destination.latitude) / 2;
    final lng = (widget.origin.longitude + widget.destination.longitude) / 2;
    return CameraPosition(
      target: LatLng(lat, lng),
      zoom: 8.5,
    );
  }

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

                // Top Floating Telemetry Overlay Capsule
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                        Icon(
                          Icons.radar_rounded,
                          size: 14,
                          color: SahyanColors.primaryMint,
                        ),
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
              ],
            ),
    );

    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: content,
      );
    }

    return content;
  }

  /// High-contrast vector canvas fallback used in tests and offline situations
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
              driverPosition: widget.driverPosition,
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
                  const Icon(
                    Icons.trip_origin,
                    size: 12,
                    color: SahyanColors.primaryDark,
                  ),
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
                    child: Icon(
                      Icons.arrow_forward,
                      size: 10,
                      color: SahyanColors.textMuted,
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: SahyanColors.primaryMint,
                  ),
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

class _SayanVectorRoutePainter extends CustomPainter {
  final List<LatLng> points;
  final LocationModel origin;
  final LocationModel destination;
  final LatLng? driverPosition;

  const _SayanVectorRoutePainter({
    required this.points,
    required this.origin,
    required this.destination,
    this.driverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Draw minimalist map background grid lines
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

    // Glow line
    final glowPaint = Paint()
      ..color = SahyanColors.primaryMint.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Primary route line
    final routePaint = Paint()
      ..color = SahyanColors.primaryDark
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (points.length > 2) {
      final ctrl = Offset(
        (p1.dx + p2.dx) / 2 + 25,
        (p1.dy + p2.dy) / 2 - 20,
      );
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    // Draw Origin Marker (Deep Pine with inner white dot)
    final originBg = Paint()..color = SahyanColors.primaryDark;
    final originInner = Paint()..color = Colors.white;
    canvas.drawCircle(p1, 9, originBg);
    canvas.drawCircle(p1, 4, originInner);

    // Draw Destination Marker (Mint Pin)
    final destBg = Paint()..color = SahyanColors.primaryMint;
    final destInner = Paint()..color = SahyanColors.primaryDark;
    canvas.drawCircle(p2, 9, destBg);
    canvas.drawCircle(p2, 4, destInner);

    // Draw Simulated Driver position if provided
    if (driverPosition != null) {
      final carPos = Offset(
        p1.dx + (p2.dx - p1.dx) * 0.45,
        p1.dy + (p2.dy - p1.dy) * 0.45,
      );
      final carPaint = Paint()..color = SahyanColors.urgentCoral;
      canvas.drawCircle(carPos, 8, carPaint);
      canvas.drawCircle(carPos, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SayanVectorRoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.driverPosition != driverPosition;
  }
}
