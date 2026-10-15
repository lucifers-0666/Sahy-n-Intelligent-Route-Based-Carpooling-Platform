import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sahyan_route_map.dart';

/// Full-screen expandable route map sheet inspired by Uber and Apple Maps navigation.
/// Offers full-canvas interactive route exploration with bounds fitting, zoom controls,
/// and live corridor waypoints inspection.
class FullScreenRouteMapSheet extends StatefulWidget {
  final LocationModel origin;
  final LocationModel destination;
  final List<dynamic> polylinePoints;
  final List<LocationModel> stopovers;
  final dynamic bounds;
  final String? routeTitle;
  final String? corridorHighway;
  final double? distanceKm;

  const FullScreenRouteMapSheet({
    super.key,
    required this.origin,
    required this.destination,
    this.polylinePoints = const [],
    this.stopovers = const [],
    this.bounds,
    this.routeTitle,
    this.corridorHighway,
    this.distanceKm,
  });

  /// Opens the full-screen interactive route map modal
  static Future<void> show({
    required BuildContext context,
    required LocationModel origin,
    required LocationModel destination,
    List<dynamic> polylinePoints = const [],
    List<LocationModel> stopovers = const [],
    dynamic bounds,
    String? routeTitle,
    String? corridorHighway,
    double? distanceKm,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => FullScreenRouteMapSheet(
          origin: origin,
          destination: destination,
          polylinePoints: polylinePoints,
          stopovers: stopovers,
          bounds: bounds,
          routeTitle: routeTitle,
          corridorHighway: corridorHighway,
          distanceKm: distanceKm,
        ),
      ),
    );
  }

  @override
  State<FullScreenRouteMapSheet> createState() =>
      _FullScreenRouteMapSheetState();
}

class _FullScreenRouteMapSheetState extends State<FullScreenRouteMapSheet> {
  late final fmap.MapController _mapController;
  bool _isMapReady = false;

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
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool _isValidCoord(ll.LatLng coord) {
    return coord.latitude >= -90.0 &&
        coord.latitude <= 90.0 &&
        coord.longitude >= -180.0 &&
        coord.longitude <= 180.0 &&
        !coord.latitude.isNaN &&
        !coord.longitude.isNaN;
  }

  void _fitRouteBounds() {
    if (!_isMapReady) return;
    try {
      if (widget.bounds != null) {
        final sw = toLatLong(widget.bounds.southwest);
        final ne = toLatLong(widget.bounds.northeast);
        if (_isValidCoord(sw) && _isValidCoord(ne)) {
          _mapController.fitCamera(
            fmap.CameraFit.bounds(
              bounds: fmap.LatLngBounds(sw, ne),
              padding: const EdgeInsets.all(50.0),
            ),
          );
          return;
        }
      }
      if (widget.polylinePoints.isNotEmpty) {
        final points = widget.polylinePoints.map(toLatLong).where(_isValidCoord).toList();
        if (points.length >= 2) {
          _mapController.fitCamera(
            fmap.CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(50.0),
            ),
          );
          return;
        }
      }
      final p1 = ll.LatLng(widget.origin.latitude, widget.origin.longitude);
      final p2 = ll.LatLng(
        widget.destination.latitude,
        widget.destination.longitude,
      );
      if (_isValidCoord(p1) && _isValidCoord(p2)) {
        _mapController.fitCamera(
          fmap.CameraFit.coordinates(
            coordinates: [p1, p2],
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }
    } catch (_) {}
  }

  void _zoomIn() {
    if (!_isMapReady) return;
    try {
      _mapController.move(
        _mapController.camera.center,
        (_mapController.camera.zoom + 1.0).clamp(1.0, 19.0),
      );
    } catch (_) {}
  }

  void _zoomOut() {
    if (!_isMapReady) return;
    try {
      _mapController.move(
        _mapController.camera.center,
        (_mapController.camera.zoom - 1.0).clamp(1.0, 19.0),
      );
    } catch (_) {}
  }

  List<fmap.Marker> _buildMarkers() {
    final markers = <fmap.Marker>[];

    // Origin Marker (Solid Pine Circle)
    markers.add(
      fmap.Marker(
        point: ll.LatLng(widget.origin.latitude, widget.origin.longitude),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: SahyanColors.primaryDark,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3314241C),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.trip_origin_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Destination Marker (Mint Location Pin)
    markers.add(
      fmap.Marker(
        point: ll.LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        ),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: SahyanColors.primaryMint,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3314241C),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Waypoint chips / Stopovers
    for (int i = 0; i < widget.stopovers.length; i++) {
      final stop = widget.stopovers[i];
      markers.add(
        fmap.Marker(
          point: ll.LatLng(stop.latitude, stop.longitude),
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<fmap.Polyline> _buildPolylines() {
    if (widget.polylinePoints.isEmpty) return [];
    final points = widget.polylinePoints.map(toLatLong).toList();
    return [
      fmap.Polyline(
        points: points,
        color: SahyanColors.primaryMint.withValues(alpha: 0.4),
        strokeWidth: 9,
      ),
      fmap.Polyline(
        points: points,
        color: SahyanColors.primaryDark,
        strokeWidth: 4.5,
      ),
    ];
  }

  ll.LatLng _getInitialCenter() {
    final lat = (widget.origin.latitude + widget.destination.latitude) / 2;
    final lng = (widget.origin.longitude + widget.destination.longitude) / 2;
    return ll.LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: Stack(
        children: [
          // ─── 1. Full-Canvas FlutterMap ──────────────────────────────────────
          Positioned.fill(
            child: _isTestingEnvironment
                ? Container(
                    color: const Color(0xFFF1F6F3),
                    child: const Center(
                      child: Text(
                        'Full Screen Route Map Preview',
                        style: TextStyle(
                          color: SahyanColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : fmap.FlutterMap(
                    mapController: _mapController,
                    options: fmap.MapOptions(
                      initialCenter: _getInitialCenter(),
                      initialZoom: 8.5,
                      interactionOptions: const fmap.InteractionOptions(
                        flags: fmap.InteractiveFlag.all,
                      ),
                      onMapReady: () {
                        _isMapReady = true;
                        _fitRouteBounds();
                      },
                    ),
                    children: [
                      fmap.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.sahyan.sahyan',
                        maxZoom: 19,
                      ),
                      fmap.PolylineLayer(polylines: _buildPolylines()),
                      fmap.MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
          ),

          // ─── 2. Top Navigation Bar ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Corridor Active Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: SahyanColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: SahyanColors.border,
                          width: 0.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1414241C),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.radar_rounded,
                            size: 16,
                            color: SahyanColors.primaryMint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.corridorHighway ?? 'Highway Corridor Active',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    Material(
                      color: SahyanColors.surface,
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: const Color(0x2214241C),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: SahyanColors.textMain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 3. Right Floating Controls (Fit Bounds + Zoom) ─────────────────
          Positioned(
            right: 16,
            top: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fit Route Bounds Button
                Material(
                  color: SahyanColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: SahyanColors.border,
                      width: 0.8,
                    ),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x1E14241C),
                  child: InkWell(
                    onTap: _fitRouteBounds,
                    borderRadius: BorderRadius.circular(12),
                    child: const Tooltip(
                      message: 'Fit Route Bounds',
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.center_focus_strong_rounded,
                          size: 20,
                          color: SahyanColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Zoom In
                Material(
                  color: SahyanColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    side: BorderSide(color: SahyanColors.border, width: 0.8),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x1E14241C),
                  child: InkWell(
                    onTap: _zoomIn,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: const SizedBox(
                      width: 44,
                      height: 40,
                      child: Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: SahyanColors.textMain,
                      ),
                    ),
                  ),
                ),
                // Zoom Out
                Material(
                  color: SahyanColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    side: BorderSide(color: SahyanColors.border, width: 0.8),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x1E14241C),
                  child: InkWell(
                    onTap: _zoomOut,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: const SizedBox(
                      width: 44,
                      height: 40,
                      child: Icon(
                        Icons.remove_rounded,
                        size: 22,
                        color: SahyanColors.textMain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 4. Bottom Route Inspection Capsule ─────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SahyanColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SahyanColors.border, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1814241C),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: SahyanColors.primaryDark,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.origin.name.isNotEmpty
                                          ? widget.origin.name
                                          : 'Origin Point',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: SahyanColors.primaryMint,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      widget.destination.name.isNotEmpty
                                          ? widget.destination.name
                                          : 'Destination Point',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.distanceKm != null &&
                            widget.distanceKm! > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: SahyanColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.distanceKm!.toStringAsFixed(0)} km',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: SahyanColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (widget.stopovers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(
                        color: SahyanColors.border,
                        height: 1,
                        thickness: 0.8,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'PLANNED WAYPOINTS & TOLLS',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.stopovers.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SahyanColors.canvas,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: SahyanColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pin_drop,
                                  size: 11,
                                  color: Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: SahyanColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
