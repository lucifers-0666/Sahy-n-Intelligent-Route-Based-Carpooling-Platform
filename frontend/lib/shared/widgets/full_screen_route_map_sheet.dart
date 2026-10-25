import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/services/map_provider_config.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/core/services/sahyan_tile_provider.dart';
import 'package:sahyan/features/trip/presentation/screens/live_ride_tracking_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sahyan_3d_vehicle_marker.dart';
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
  final String? vehicleTypeCode;

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
    this.vehicleTypeCode,
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
    String? vehicleTypeCode,
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
          vehicleTypeCode: vehicleTypeCode,
        ),
      ),
    );
  }

  @override
  State<FullScreenRouteMapSheet> createState() =>
      _FullScreenRouteMapSheetState();
}

class _FullScreenRouteMapSheetState extends State<FullScreenRouteMapSheet>
    with TickerProviderStateMixin {
  late final fmap.MapController _mapController;
  bool _isMapReady = false;
  late MapProviderType _selectedProviderType;
  List<ll.LatLng> _fetchedPolylinePoints = [];
  bool _isFetchingRealRoute = false;

  // 3D perspective and live vehicle animation state
  bool _is3DTilt = false;
  AnimationController? _vehicleAnimController;
  ll.LatLng? _simVehiclePos;
  double _simVehicleHeading = 0.0;
  final bool _isVehicleStopped = false;

  List<ll.LatLng> get _effectivePolylinePoints {
    if (_fetchedPolylinePoints.isNotEmpty) {
      return _fetchedPolylinePoints;
    }
    if (widget.polylinePoints.length >= 50) {
      return widget.polylinePoints.map(toLatLong).toList();
    }
    if (widget.polylinePoints.isNotEmpty) {
      return widget.polylinePoints.map(toLatLong).toList();
    }
    return const [];
  }

  MapTileConfig get _activeTileConfig =>
      MapProviderConfig.providers[_selectedProviderType] ??
      MapProviderConfig.activeConfig;

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
    _selectedProviderType = MapProviderConfig.currentProvider;
    _mapController = fmap.MapController();
    _initVehicleAnimation();
    if (widget.polylinePoints.length < 50) {
      _fetchRoadRouteIfNeeded();
    }
  }

  void _initVehicleAnimation() {
    if (_isTestingEnvironment) return;
    _vehicleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..addListener(_onVehicleAnimTick);
    _vehicleAnimController?.repeat();
  }

  void _onVehicleAnimTick() {
    final points = _effectivePolylinePoints;
    if (points.length < 2) return;
    final progress = _vehicleAnimController?.value ?? 0.0;
    final floatIndex = progress * (points.length - 1);
    final baseIndex = floatIndex.floor().clamp(0, points.length - 2);
    final frac = floatIndex - baseIndex;

    final p1 = points[baseIndex];
    final p2 = points[baseIndex + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

    final dLat = p2.latitude - p1.latitude;
    final dLng = p2.longitude - p1.longitude;
    final headingRad = math.atan2(dLng, dLat);
    final headingDeg = (headingRad * 180.0 / math.pi + 360.0) % 360.0;

    if (mounted) {
      setState(() {
        _simVehiclePos = ll.LatLng(lat, lng);
        _simVehicleHeading = headingDeg;
      });
    }
  }

  @override
  void dispose() {
    _vehicleAnimController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FullScreenRouteMapSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final originChanged =
        widget.origin.latitude != oldWidget.origin.latitude ||
        widget.origin.longitude != oldWidget.origin.longitude;
    final destChanged =
        widget.destination.latitude != oldWidget.destination.latitude ||
        widget.destination.longitude != oldWidget.destination.longitude;
    if (originChanged ||
        destChanged ||
        (widget.polylinePoints.length <= 4 && _fetchedPolylinePoints.isEmpty)) {
      _fetchRoadRouteIfNeeded();
    }
  }

  Future<void> _fetchRoadRouteIfNeeded() async {
    if (_isTestingEnvironment) return;
    if (_isFetchingRealRoute) return;
    if (widget.origin.latitude == 0.0 && widget.origin.longitude == 0.0) return;
    if (widget.destination.latitude == 0.0 &&
        widget.destination.longitude == 0.0) {
      return;
    }

    _isFetchingRealRoute = true;
    try {
      final res = await RouteService.fetchRealRoadPolyline(
        origin: widget.origin,
        destination: widget.destination,
        stopovers: widget.stopovers,
      );
      if (mounted && res.points.isNotEmpty) {
        setState(() {
          _fetchedPolylinePoints = res.points;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fitRouteBounds();
          }
        });
      }
    } catch (_) {
    } finally {
      _isFetchingRealRoute = false;
    }
  }

  bool _isValidCoord(ll.LatLng coord) {
    return coord.latitude != 0.0 &&
        coord.longitude != 0.0 &&
        coord.latitude >= -90.0 &&
        coord.latitude <= 90.0 &&
        coord.longitude >= -180.0 &&
        coord.longitude <= 180.0 &&
        !coord.latitude.isNaN &&
        !coord.longitude.isNaN &&
        !coord.latitude.isInfinite &&
        !coord.longitude.isInfinite;
  }

  void _fitRouteBounds() {
    if (!_isMapReady) return;
    try {
      if (widget.bounds != null) {
        final sw = toLatLong(widget.bounds.southwest);
        final ne = toLatLong(widget.bounds.northeast);
        if (_isValidCoord(sw) && _isValidCoord(ne)) {
          final latDiff = (ne.latitude - sw.latitude).abs();
          final lngDiff = (ne.longitude - sw.longitude).abs();
          if (latDiff < 0.005 && lngDiff < 0.005) {
            final center = ll.LatLng(
              (sw.latitude + ne.latitude) / 2,
              (sw.longitude + ne.longitude) / 2,
            );
            _mapController.move(center, 13.5);
            return;
          }
          final safeLatMargin = latDiff < 0.02 ? 0.015 : 0.0;
          final safeLngMargin = lngDiff < 0.02 ? 0.015 : 0.0;
          _mapController.fitCamera(
            fmap.CameraFit.bounds(
              bounds: fmap.LatLngBounds(
                ll.LatLng(
                  sw.latitude - safeLatMargin,
                  sw.longitude - safeLngMargin,
                ),
                ll.LatLng(
                  ne.latitude + safeLatMargin,
                  ne.longitude + safeLngMargin,
                ),
              ),
              padding: const EdgeInsets.all(50.0),
              maxZoom: 16.5,
              minZoom: 4.0,
            ),
          );
          return;
        }
      }
      final points = _effectivePolylinePoints.where(_isValidCoord).toList();
      if (points.length >= 2) {
        _mapController.fitCamera(
          fmap.CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(50.0),
            maxZoom: 16.5,
            minZoom: 4.0,
          ),
        );
        return;
      }
      final p1 = ll.LatLng(widget.origin.latitude, widget.origin.longitude);
      final p2 = ll.LatLng(
        widget.destination.latitude,
        widget.destination.longitude,
      );
      final hasP1 = _isValidCoord(p1);
      final hasP2 = _isValidCoord(p2);

      if (hasP1 && hasP2) {
        final latDiff = (p1.latitude - p2.latitude).abs();
        final lngDiff = (p1.longitude - p2.longitude).abs();
        if (latDiff < 0.005 && lngDiff < 0.005) {
          _mapController.move(p1, 13.5);
          return;
        }
        _mapController.fitCamera(
          fmap.CameraFit.coordinates(
            coordinates: [p1, p2],
            padding: const EdgeInsets.all(50.0),
            maxZoom: 16.5,
            minZoom: 4.0,
          ),
        );
      } else if (hasP1) {
        _mapController.move(p1, 13.5);
      } else if (hasP2) {
        _mapController.move(p2, 13.5);
      } else {
        _mapController.move(const ll.LatLng(23.0225, 72.5714), 10.5);
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

    // 3D Moving Vehicle Marker with Isometric Heading
    if (_simVehiclePos != null) {
      markers.add(
        fmap.Marker(
          point: _simVehiclePos!,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Sahyan3DVehicleMarker(
            vehicleTypeCode: widget.vehicleTypeCode ?? 'sedan',
            heading: _simVehicleHeading,
            isStopped: _isVehicleStopped,
            speedKmh: _isVehicleStopped ? 0.0 : 68.0,
            size: 60.0,
          ),
        ),
      );
    }

    return markers;
  }

  List<fmap.Polyline> _buildPolylines() {
    final points = _effectivePolylinePoints;
    if (points.isEmpty) return [];
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
    final o = ll.LatLng(widget.origin.latitude, widget.origin.longitude);
    final d =
        ll.LatLng(widget.destination.latitude, widget.destination.longitude);
    final hasO = _isValidCoord(o);
    final hasD = _isValidCoord(d);

    if (hasO && hasD) {
      final latDiff = (o.latitude - d.latitude).abs();
      final lngDiff = (o.longitude - d.longitude).abs();
      if (latDiff < 0.0001 && lngDiff < 0.0001) {
        return o;
      }
      return ll.LatLng(
        (o.latitude + d.latitude) / 2,
        (o.longitude + d.longitude) / 2,
      );
    } else if (hasO) {
      return o;
    } else if (hasD) {
      return d;
    }
    return const ll.LatLng(23.0225, 72.5714);
  }

  void _showCartoKeyDialog() {
    final controller = TextEditingController(text: MapProviderConfig.cartoApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: SahyanColors.primaryDark, size: 22),
            SizedBox(width: 8),
            Text(
              'CARTO Basemaps Key',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SahyanColors.primaryDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your CARTO API Key to unlock commercial CARTO Voyager, Positron, and Dark vector basemaps.',
              style: TextStyle(
                fontSize: 12.5,
                color: SahyanColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Paste CARTO API Key',
                filled: true,
                fillColor: SahyanColors.canvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: SahyanColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: SahyanColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final key = controller.text.trim();
              MapProviderConfig.setCartoApiKey(key);
              Navigator.of(ctx).pop();
              if (key.isNotEmpty) {
                MapProviderConfig.setProvider(MapProviderType.cartoVoyager);
                setState(() {
                  _selectedProviderType = MapProviderType.cartoVoyager;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CARTO API Key activated. Switched to Sahyān Road.'),
                    backgroundColor: SahyanColors.primaryDark,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SahyanColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Apply Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 42,
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isActive ? SahyanColors.primaryMint : SahyanColors.primaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: Stack(
        children: [
          // ─── 1. Full-Canvas FlutterMap with Optional 3D Perspective Tilt ─────
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
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateX(_is3DTilt ? 42.0 * math.pi / 180.0 : 0.0),
                    child: fmap.FlutterMap(
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
                          key: ValueKey(_selectedProviderType),
                          urlTemplate: _activeTileConfig.urlTemplate,
                          fallbackUrl:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: _activeTileConfig.subdomains,
                          userAgentPackageName:
                              _activeTileConfig.userAgentPackageName,
                          maxZoom: _activeTileConfig.maxZoom.toDouble(),
                          tileProvider: SahyanTileProvider.create(),
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint('TILE LOAD ERROR in full_screen_map: $error');
                          },
                        ),
                        fmap.PolylineLayer(polylines: _buildPolylines()),
                        fmap.MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
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

                    // Close button (Dedicated space, clean circle)
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

          // ─── 3. Right Floating Unified Action Dock ──────────────────────────
          Positioned(
            right: 16,
            top: 96,
            child: Container(
              width: 44,
              decoration: BoxDecoration(
                color: SahyanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SahyanColors.border,
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1E14241C),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 3D Tilt Perspective Toggle
                  _buildDockButton(
                    icon: _is3DTilt
                        ? Icons.view_in_ar_rounded
                        : Icons.threed_rotation_rounded,
                    tooltip: _is3DTilt ? 'Reset 2D View' : '3D Driving Tilt (45°)',
                    isActive: _is3DTilt,
                    onTap: () {
                      setState(() {
                        _is3DTilt = !_is3DTilt;
                      });
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: SahyanColors.border),

                  // 2. Map Style Switcher
                  PopupMenuButton<String>(
                    tooltip: 'Map Layer & Styling',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    offset: const Offset(-210, 0),
                    onSelected: (choice) {
                      if (choice == 'config_carto') {
                        _showCartoKeyDialog();
                      } else {
                        final type = MapProviderType.values.firstWhere(
                          (e) => e.name == choice,
                        );
                        MapProviderConfig.setProvider(type);
                        setState(() {
                          _selectedProviderType = type;
                        });
                      }
                    },
                    itemBuilder: (ctx) => [
                      _buildPopupItem(
                        MapProviderType.osmStandard,
                        'OpenStreetMap',
                        Icons.map_rounded,
                      ),
                      _buildPopupItem(
                        MapProviderType.osmHot,
                        'Sahyān High-Contrast',
                        Icons.traffic_rounded,
                      ),
                      _buildPopupItem(
                        MapProviderType.satellite,
                        'Satellite Aerial',
                        Icons.satellite_alt_rounded,
                      ),
                      _buildPopupItem(
                        MapProviderType.cyclosm,
                        'Topographic Terrain',
                        Icons.terrain_rounded,
                      ),
                      _buildPopupItem(
                        MapProviderType.cartoVoyager,
                        'Sahyān Road',
                        Icons.navigation_rounded,
                      ),
                      _buildPopupItem(
                        MapProviderType.cartoPositron,
                        'Clean Light',
                        Icons.wb_sunny_outlined,
                      ),
                      _buildPopupItem(
                        MapProviderType.cartoDark,
                        'Night Voyage',
                        Icons.dark_mode_outlined,
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'config_carto',
                        child: Row(
                          children: [
                            Icon(Icons.key_rounded, size: 18, color: SahyanColors.primaryDark),
                            SizedBox(width: 10),
                            Text(
                              'Configure CARTO Key...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: SahyanColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const SizedBox(
                      width: 44,
                      height: 42,
                      child: Icon(
                        Icons.layers_rounded,
                        size: 20,
                        color: SahyanColors.primaryDark,
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.8, color: SahyanColors.border),

                  // 3. Fit Route Bounds Button
                  _buildDockButton(
                    icon: Icons.center_focus_strong_rounded,
                    tooltip: 'Fit Route Bounds',
                    onTap: _fitRouteBounds,
                  ),
                  const Divider(height: 1, thickness: 0.8, color: SahyanColors.border),

                  // 4. Zoom In
                  _buildDockButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom In',
                    onTap: _zoomIn,
                  ),
                  const Divider(height: 1, thickness: 0.8, color: SahyanColors.border),

                  // 5. Zoom Out
                  _buildDockButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom Out',
                    onTap: _zoomOut,
                  ),
                ],
              ),
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

                    // ─── Prominent "Start Navigation" Button ────────────────
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => LiveRideTrackingScreen(
                                originName: widget.origin.name.isNotEmpty
                                    ? widget.origin.name
                                    : 'ISCON Cross Road, Ahmedabad',
                                destinationName: widget.destination.name.isNotEmpty
                                    ? widget.destination.name
                                    : 'Kalawad Road, Rajkot',
                                driverName: 'Rohit Patel',
                                driverRating: 4.92,
                                vehicleInfo: 'Honda City ZX · GJ03AB1234',
                                vehicleType: VehicleType.sedan,
                                rideId: 'demo-ahmedabad-rajkot-corridor',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Start Navigation',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SahyanColors.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0x3314241C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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
  }

  PopupMenuItem<String> _buildPopupItem(
    MapProviderType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedProviderType == type;
    return PopupMenuItem<String>(
      value: type.name,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isSelected ? SahyanColors.primaryDark : SahyanColors.textMuted,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color:
                  isSelected ? SahyanColors.primaryDark : SahyanColors.textMain,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: SahyanColors.primaryDark,
            ),
          ],
        ],
      ),
    );
  }
}

