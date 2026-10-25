import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/services/map_provider_config.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/core/services/sahyan_tile_provider.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sahyan_3d_vehicle_marker.dart';

/// Helper to convert any LatLng-like coordinate object to latlong2.LatLng
ll.LatLng toLatLong(dynamic point) {
  if (point is ll.LatLng) return point;
  return ll.LatLng(
    (point.latitude as num).toDouble(),
    (point.longitude as num).toDouble(),
  );
}

/// Canonical Sahyān Route Map widget with real-time polyline rendering,
/// live vehicle marker animation, provider abstraction, and camera tracking.
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

  /// Optional override map style (retained for backward compatibility).
  final dynamic useGoogleMaps;

  /// Stop/Halt indicator state
  final bool isVehicleStopped;

  /// Current telemetry speed in km/h
  final double liveSpeedKmh;

  /// 3D perspective tilt angle in degrees (0.0 for 2D, ~42.0 for 3D)
  final double tiltAngle;

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
    this.useGoogleMaps,
    this.isVehicleStopped = false,
    this.liveSpeedKmh = 0.0,
    this.tiltAngle = 0.0,
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
  late MapProviderType _selectedProviderType;

  // ── Interpolation state ──────────────────────────────────────────────────
  late AnimationController _interpolationController;
  late Animation<double> _interpolationAnim;

  ll.LatLng? _prevDriverPos;
  ll.LatLng? _currentDriverPos;
  double _prevHeading = 0.0;
  double _currentHeading = 0.0;
  ll.LatLng? _displayDriverPos;
  double _displayHeading = 0.0;

  List<ll.LatLng> _fetchedPolylinePoints = [];
  bool _isFetchingRealRoute = false;
  double _tiltDegrees = 0.0;

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
    _selectedProviderType = MapProviderConfig.currentProvider;
    _mapController = fmap.MapController();
    _tiltDegrees = widget.tiltAngle;

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

    // Mandatory fetch 1,000+ turn-by-turn road points if input points are rough (< 50)
    if (widget.polylinePoints.length < 50) {
      _fetchRoadRouteIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant SahyanRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tiltAngle != oldWidget.tiltAngle) {
      _tiltDegrees = widget.tiltAngle;
    }

    if (_mapController != null && _isMapReady && widget.bounds != null) {
      _fitBounds();
    }

    final originChanged =
        widget.origin.latitude != oldWidget.origin.latitude ||
        widget.origin.longitude != oldWidget.origin.longitude;
    final destChanged =
        widget.destination.latitude != oldWidget.destination.latitude ||
        widget.destination.longitude != oldWidget.destination.longitude;
    final polyChanged = widget.polylinePoints != oldWidget.polylinePoints;

    if (polyChanged && widget.polylinePoints.length >= 50) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitBounds();
        }
      });
    } else if (originChanged ||
        destChanged ||
        (widget.polylinePoints.length < 50 && _fetchedPolylinePoints.isEmpty)) {
      _fetchRoadRouteIfNeeded();
    }

    // New driver position received — start interpolation
    if (widget.driverPosition != null &&
        widget.driverPosition != oldWidget.driverPosition) {
      final newPos = toLatLong(widget.driverPosition);
      _prevDriverPos = _displayDriverPos ?? newPos;
      _prevHeading = _displayHeading;
      _currentDriverPos = newPos;
      _currentHeading = _shortestHeading(
        _prevHeading,
        widget.driverHeading ?? 0.0,
      );

      _interpolationController.forward(from: 0.0);
    }
  }

  Future<void> _fetchRoadRouteIfNeeded() async {
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
            _fitBounds();
          }
        });
      }
    } catch (_) {
    } finally {
      _isFetchingRealRoute = false;
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
    // Spherical linear interpolation between heading angles along the road
    final heading = _slerpHeading(_prevHeading, _currentHeading, t);

    setState(() {
      _displayDriverPos = ll.LatLng(lat, lng);
      _displayHeading = heading;
    });

    // Camera follow
    if (widget.followVehicle && _isMapReady && _mapController != null) {
      try {
        _mapController!.move(
          ll.LatLng(lat, lng),
          _mapController!.camera.zoom,
        );
      } catch (_) {}
    }
  }

  /// Trigonometric Slerp interpolation between heading angles without wrapping jumps
  double _slerpHeading(double fromDeg, double toDeg, double t) {
    final fromRad = fromDeg * math.pi / 180.0;
    final toRad = toDeg * math.pi / 180.0;
    final cs = (1.0 - t) * math.cos(fromRad) + t * math.cos(toRad);
    final sn = (1.0 - t) * math.sin(fromRad) + t * math.sin(toRad);
    final rad = math.atan2(sn, cs);
    return (rad * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Returns the shortest angular delta so heading never wraps 359 to 1 as +358 degrees.
  double _shortestHeading(double from, double to) {
    double delta = (to - from + 360) % 360;
    if (delta > 180) delta -= 360;
    return from + delta;
  }

  // ── Map builders ─────────────────────────────────────────────────────────

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

  void _fitBounds() {
    if (_mapController == null || !_isMapReady) return;
    try {
      fmap.LatLngBounds? boundsToFit;

      if (widget.bounds != null) {
        final sw = toLatLong(widget.bounds.southwest);
        final ne = toLatLong(widget.bounds.northeast);
        if (_isValidCoord(sw) && _isValidCoord(ne)) {
          boundsToFit = fmap.LatLngBounds(sw, ne);
        }
      } else if (_effectivePolylinePoints.isNotEmpty) {
        final validPoints =
            _effectivePolylinePoints.where(_isValidCoord).toList();
        if (validPoints.length >= 2) {
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
          boundsToFit = fmap.LatLngBounds(
            ll.LatLng(minLat, minLng),
            ll.LatLng(maxLat, maxLng),
          );
        } else if (validPoints.length == 1) {
          _mapController!.move(validPoints.first, 13.5);
          return;
        }
      } else {
        final p1 = ll.LatLng(widget.origin.latitude, widget.origin.longitude);
        final p2 = ll.LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        );
        final hasP1 = _isValidCoord(p1);
        final hasP2 = _isValidCoord(p2);

        if (hasP1 && hasP2) {
          boundsToFit = fmap.LatLngBounds(
            ll.LatLng(
              math.min(p1.latitude, p2.latitude),
              math.min(p1.longitude, p2.longitude),
            ),
            ll.LatLng(
              math.max(p1.latitude, p2.latitude),
              math.max(p1.longitude, p2.longitude),
            ),
          );
        } else if (hasP1) {
          _mapController!.move(p1, 13.5);
          return;
        } else if (hasP2) {
          _mapController!.move(p2, 13.5);
          return;
        } else {
          _mapController!.move(const ll.LatLng(23.0225, 72.5714), 10.5);
          return;
        }
      }

      if (boundsToFit == null) {
        _mapController!.move(const ll.LatLng(23.0225, 72.5714), 10.5);
        return;
      }

      final sw = boundsToFit.southWest;
      final ne = boundsToFit.northEast;
      final latDiff = (ne.latitude - sw.latitude).abs();
      final lngDiff = (ne.longitude - sw.longitude).abs();

      if (latDiff < 0.005 && lngDiff < 0.005) {
        final center = ll.LatLng(
          (sw.latitude + ne.latitude) / 2,
          (sw.longitude + ne.longitude) / 2,
        );
        _mapController!.move(center, 13.5);
        return;
      }

      final safeLatMargin = latDiff < 0.02 ? 0.015 : 0.0;
      final safeLngMargin = lngDiff < 0.02 ? 0.015 : 0.0;

      final safeBounds = fmap.LatLngBounds(
        ll.LatLng(sw.latitude - safeLatMargin, sw.longitude - safeLngMargin),
        ll.LatLng(ne.latitude + safeLatMargin, ne.longitude + safeLngMargin),
      );

      _mapController!.fitCamera(
        fmap.CameraFit.bounds(
          bounds: safeBounds,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          maxZoom: 16.5,
          minZoom: 4.0,
        ),
      );
    } catch (_) {}
  }

  List<fmap.Polyline> _buildPolylines() {
    final points = _effectivePolylinePoints;
    if (points.isEmpty) return [];

    final isNight = _selectedProviderType == MapProviderType.cartoDark;
    final primaryRoadColor = isNight
        ? const Color(0xFF10B981)
        : AppColors.deepEmerald;
    final auraColor = isNight
        ? const Color(0xFF059669).withValues(alpha: 0.35)
        : AppColors.softMint.withValues(alpha: 0.40);

    return [
      // Outer glow / route corridor aura
      fmap.Polyline(
        points: points,
        strokeWidth: 9.0,
        color: auraColor,
        borderStrokeWidth: 0,
      ),
      // Inner sharp road core
      fmap.Polyline(
        points: points,
        strokeWidth: 4.8,
        color: primaryRoadColor,
        borderStrokeWidth: 1.0,
        borderColor: Colors.white.withValues(alpha: 0.6),
      ),
    ];
  }

  List<fmap.Marker> _buildMarkers() {
    final markers = <fmap.Marker>[];

    // Pickup Marker
    final p1 = ll.LatLng(widget.origin.latitude, widget.origin.longitude);
    if (_isValidCoord(p1)) {
      markers.add(
        fmap.Marker(
          point: p1,
          width: 38,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.deepEmerald,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.trip_origin_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // Destination Marker
    final p2 = ll.LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );
    if (_isValidCoord(p2)) {
      markers.add(
        fmap.Marker(
          point: p2,
          width: 38,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

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
              border: Border.all(color: Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Driver vehicle marker — uses 3D isometric vehicle engine with Slerp heading
    final driverPos =
        _displayDriverPos ??
        (widget.driverPosition != null
            ? toLatLong(widget.driverPosition)
            : null);
    if (driverPos != null) {
      markers.add(
        fmap.Marker(
          point: driverPos,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Sahyan3DVehicleMarker(
            vehicleTypeCode: widget.vehicleTypeCode ?? 'sedan',
            heading: _displayHeading,
            isStopped: widget.isVehicleStopped,
            speedKmh: widget.liveSpeedKmh,
            size: 60.0,
          ),
        ),
      );
    }

    return markers;
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: _isTestingEnvironment
          ? _buildVectorFallbackPreview()
          : _buildProductionMap(),
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

  Widget _buildProductionMap() {
    final tileConfig =
        MapProviderConfig.providers[_selectedProviderType] ??
        MapProviderConfig.activeConfig;

    return Container(
      color: tileConfig.backgroundColor,
      child: Stack(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(_tiltDegrees * math.pi / 180.0),
            child: fmap.FlutterMap(
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
                  key: ValueKey(
                    '${tileConfig.type.name}_${tileConfig.urlTemplate}',
                  ),
                  urlTemplate: tileConfig.urlTemplate,
                  fallbackUrl:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: tileConfig.subdomains,
                  userAgentPackageName: tileConfig.userAgentPackageName,
                  maxZoom: tileConfig.maxZoom.toDouble(),
                  tileProvider: SahyanTileProvider.create(),
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('TILE LOAD ERROR in sahyan_route_map: $error');
                  },
                ),
                fmap.PolylineLayer(polylines: _buildPolylines()),
                fmap.MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          // Map style selector badge
          _buildMapStyleBadge(tileConfig),

          // Controls (Zoom in / out / overview)
          if (widget.showControls) _buildMapControls(),

          // OpenStreetMap & CARTO Attribution Badge
          _buildAttributionBadge(tileConfig),

          // Vehicle Follow Toggle
          if (widget.driverPosition != null && widget.onFollowToggle != null)
            _buildFollowToggleFab(),
        ],
      ),
    );
  }

  Widget _buildMapStyleBadge(MapTileConfig current) {
    return Positioned(
      top: 12,
      left: 12,
      child: Material(
        color: Colors.transparent,
        child: PopupMenuButton<MapProviderType>(
          onSelected: (type) {
            setState(() {
              _selectedProviderType = type;
              MapProviderConfig.setProvider(type);
            });
          },
          tooltip: 'Select Map Style',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (ctx) => [
            _buildPopupItem(
              MapProviderType.cartoVoyager,
              'Sahyān Road',
              Icons.alt_route_rounded,
            ),
            _buildPopupItem(
              MapProviderType.cartoPositron,
              'Clean Navigation',
              Icons.navigation_rounded,
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
              MapProviderType.osmStandard,
              'OpenStreetMap',
              Icons.map_rounded,
            ),
            _buildPopupItem(
              MapProviderType.cartoDark,
              'Night Voyage',
              Icons.nights_stay_rounded,
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.layers_rounded,
                  size: 14,
                  color: AppColors.deepEmerald,
                ),
                const SizedBox(width: 6),
                Text(
                  current.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<MapProviderType> _buildPopupItem(
    MapProviderType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedProviderType == type;
    return PopupMenuItem<MapProviderType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.deepEmerald : AppColors.mutedText,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.deepEmerald
                  : AppColors.primaryText,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.deepEmerald,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: _tiltDegrees > 0 ? Icons.view_in_ar_rounded : Icons.threed_rotation_rounded,
            tooltip: _tiltDegrees > 0 ? 'Reset 2D View' : '3D Perspective Tilt (45°)',
            onTap: () {
              setState(() {
                _tiltDegrees = _tiltDegrees > 0 ? 0.0 : 42.0;
              });
            },
          ),
          const SizedBox(height: 6),
          _buildControlButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            onTap: () {
              if (_mapController != null) {
                _mapController!.move(
                  _mapController!.camera.center,
                  _mapController!.camera.zoom + 1,
                );
              }
            },
          ),
          const SizedBox(height: 6),
          _buildControlButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            onTap: () {
              if (_mapController != null) {
                _mapController!.move(
                  _mapController!.camera.center,
                  _mapController!.camera.zoom - 1,
                );
              }
            },
          ),
          const SizedBox(height: 6),
          _buildControlButton(
            icon: Icons.crop_free_rounded,
            tooltip: 'Fit Route Bounds',
            onTap: _fitBounds,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 18, color: AppColors.deepEmerald),
          ),
        ),
      ),
    );
  }

  Widget _buildAttributionBadge(MapTileConfig config) {
    return Positioned(
      bottom: 4,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(
          config.attributionText,
          style: const TextStyle(
            fontSize: 8.5,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowToggleFab() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: GestureDetector(
        onTap: () => widget.onFollowToggle!(!widget.followVehicle),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.followVehicle
                ? AppColors.deepEmerald
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.followVehicle
                  ? AppColors.deepEmerald
                  : AppColors.border,
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
                    : AppColors.primaryText,
              ),
              const SizedBox(width: 6),
              Text(
                widget.followVehicle ? 'Following' : 'Free Pan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.followVehicle
                      ? Colors.white
                      : AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              driverPosition:
                  _displayDriverPos ??
                  (widget.driverPosition != null
                      ? toLatLong(widget.driverPosition)
                      : null),
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
                  Icon(
                    Icons.map_outlined,
                    size: 13,
                    color: SahyanColors.primaryDark,
                  ),
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

// ── Vector route painter ───────────────────────────────────────────────────

class _SayanVectorRoutePainter extends CustomPainter {
  final List<dynamic> points;
  final LocationModel origin;
  final LocationModel destination;
  final ll.LatLng? driverPosition;
  final double driverHeading;

  _SayanVectorRoutePainter({
    required this.points,
    required this.origin,
    required this.destination,
    this.driverPosition,
    this.driverHeading = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bgPaint = Paint()..color = const Color(0xFFF1F6F3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final List<ll.LatLng> latLngList = points.map(toLatLong).toList();
    if (latLngList.isEmpty) {
      latLngList.add(ll.LatLng(origin.latitude, origin.longitude));
      latLngList.add(ll.LatLng(destination.latitude, destination.longitude));
    }

    double minLat = latLngList.first.latitude;
    double maxLat = latLngList.first.latitude;
    double minLng = latLngList.first.longitude;
    double maxLng = latLngList.first.longitude;

    for (final p in latLngList) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final dLat = (maxLat - minLat).abs();
    final dLng = (maxLng - minLng).abs();
    final spanLat = dLat < 0.001 ? 0.01 : dLat;
    final spanLng = dLng < 0.001 ? 0.01 : dLng;

    const pad = 36.0;
    final drawW = size.width - pad * 2;
    final drawH = size.height - pad * 2;

    Offset toScreen(double lat, double lng) {
      final x = pad + ((lng - minLng) / spanLng) * drawW;
      final y = size.height - (pad + ((lat - minLat) / spanLat) * drawH);
      return Offset(x, y);
    }

    final path = Path();
    for (int i = 0; i < latLngList.length; i++) {
      final pt = toScreen(latLngList[i].latitude, latLngList[i].longitude);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // Outer Aura
    final auraPaint = Paint()
      ..color = AppColors.softMint.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, auraPaint);

    // Inner Road
    final roadPaint = Paint()
      ..color = AppColors.deepEmerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, roadPaint);

    // Markers
    final originPt = toScreen(origin.latitude, origin.longitude);
    canvas.drawCircle(
      originPt,
      7,
      Paint()..color = AppColors.deepEmerald,
    );
    canvas.drawCircle(
      originPt,
      4,
      Paint()..color = Colors.white,
    );

    final destPt = toScreen(destination.latitude, destination.longitude);
    canvas.drawCircle(
      destPt,
      7,
      Paint()..color = const Color(0xFFE11D48),
    );
    canvas.drawCircle(
      destPt,
      4,
      Paint()..color = Colors.white,
    );

    if (driverPosition != null) {
      final drvPt = toScreen(driverPosition!.latitude, driverPosition!.longitude);
      canvas.drawCircle(
        drvPt,
        9,
        Paint()..color = AppColors.primaryMint,
      );
      canvas.drawCircle(
        drvPt,
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SayanVectorRoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.driverPosition != driverPosition ||
        oldDelegate.driverHeading != driverHeading;
  }
}
