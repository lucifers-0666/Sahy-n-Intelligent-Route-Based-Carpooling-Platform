import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/location/data/providers/geolocator_provider.dart';
import 'package:sahyan/core/services/map_provider_config.dart';
import 'package:sahyan/core/services/sahyan_tile_provider.dart';
import 'package:sahyan/features/rides/presentation/widgets/location_search_bottom_sheet.dart';
import 'package:sahyan/shared/models/location_model.dart';

/// Full-screen interactive map location picker for precise pin selection.
///
/// Features a tactile center target pin, live nearest-hub identification,
/// optional Nominatim reverse-geocoding with debounce, GPS auto-centering,
/// and smooth camera controls.
class LocationMapPickerSheet extends StatefulWidget {
  final String title;
  final LocationModel? initialLocation;
  final bool isPickup;

  const LocationMapPickerSheet({
    super.key,
    this.title = 'Choose on Map',
    this.initialLocation,
    this.isPickup = true,
  });

  static Future<LocationModel?> show({
    required BuildContext context,
    String title = 'Choose on Map',
    LocationModel? initialLocation,
    bool isPickup = true,
  }) {
    return Navigator.of(context).push<LocationModel>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => LocationMapPickerSheet(
          title: title,
          initialLocation: initialLocation,
          isPickup: isPickup,
        ),
      ),
    );
  }

  @override
  State<LocationMapPickerSheet> createState() => _LocationMapPickerSheetState();
}

class _LocationMapPickerSheetState extends State<LocationMapPickerSheet>
    with SingleTickerProviderStateMixin {
  late final fmap.MapController _mapController;
  final GeolocatorProvider _gpsProvider = GeolocatorProvider();

  late ll.LatLng _currentCenter;
  bool _isMapReady = false;
  bool _isLocatingGps = false;
  bool _isMapMoving = false;
  MapProviderType _selectedProviderType = MapProviderType.osmStandard;

  String _resolvedTitle = 'Selected Location';
  String _resolvedAddress = 'Locating on map...';
  String _resolvedCity = 'Gujarat';
  Timer? _reverseGeocodeDebounce;

  late final AnimationController _pinAnimController;
  late final Animation<double> _pinBounceAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = fmap.MapController();
    _selectedProviderType = MapProviderConfig.currentProvider;

    final initLat = widget.initialLocation?.latitude ?? 0.0;
    final initLng = widget.initialLocation?.longitude ?? 0.0;
    if (_isValid(initLat, initLng)) {
      _currentCenter = ll.LatLng(initLat, initLng);
      _resolvedTitle = widget.initialLocation!.name;
      _resolvedAddress = widget.initialLocation!.address;
      _resolvedCity = widget.initialLocation!.city;
    } else {
      // Default center: Ahmedabad, Gujarat
      _currentCenter = const ll.LatLng(23.0225, 72.5714);
      _resolveNearestHub(_currentCenter);
    }

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _pinBounceAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _pinAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  bool _isValid(double lat, double lng) {
    return lat != 0.0 &&
        lng != 0.0 &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lng >= -180.0 &&
        lng <= 180.0 &&
        !lat.isNaN &&
        !lng.isNaN &&
        !lat.isInfinite &&
        !lng.isInfinite;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  void _resolveNearestHub(ll.LatLng pos) {
    LocationModel? nearest;
    var minDistance = double.infinity;

    for (final hub in IndiaPopularHubs.popularHubs) {
      final dist = _haversineKm(
        pos.latitude,
        pos.longitude,
        hub.latitude,
        hub.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = hub;
      }
    }

    if (nearest != null && minDistance < 1.8) {
      if (mounted) {
        setState(() {
          _resolvedTitle = nearest!.name;
          _resolvedAddress = minDistance < 0.3
              ? nearest.address
              : 'Near ${nearest.name} (~${(minDistance * 1000).round()}m)';
          _resolvedCity = nearest.city;
        });
      }
    } else {
      final latStr = pos.latitude.toStringAsFixed(4);
      final lngStr = pos.longitude.toStringAsFixed(4);
      if (mounted) {
        setState(() {
          _resolvedTitle =
              nearest != null && minDistance < 15.0
                  ? '${nearest.city} Area'
                  : 'Selected Pin ($latStr, $lngStr)';
          _resolvedAddress = 'Coordinates: $latStr, $lngStr';
          _resolvedCity = nearest?.city ?? 'Gujarat';
        });
      }
    }

    // Schedule background reverse geocode for rich address
    _scheduleReverseGeocode(pos);
  }

  void _scheduleReverseGeocode(ll.LatLng pos) {
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 750), () async {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}',
        );
        final res = await http.get(
          url,
          headers: {'User-Agent': 'SahyanApp/1.0 (contact@sahyan.app)'},
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final displayName = data['display_name'] as String?;
          final addr = data['address'] as Map<String, dynamic>?;
          if (mounted && displayName != null) {
            final road =
                addr?['road'] ??
                addr?['suburb'] ??
                addr?['neighbourhood'] ??
                displayName.split(',').first.trim();
            final city =
                addr?['city'] ??
                addr?['town'] ??
                addr?['county'] ??
                addr?['state'] ??
                _resolvedCity;
            setState(() {
              _resolvedTitle = road.toString();
              _resolvedAddress = displayName;
              _resolvedCity = city.toString();
            });
          }
        }
      } catch (_) {
        // Fallback already populated by nearest hub
      }
    });
  }

  Future<void> _handleGpsLocate() async {
    if (_isLocatingGps) return;
    setState(() => _isLocatingGps = true);

    try {
      final pos = await _gpsProvider.getCurrentPosition();
      if (pos != null && mounted) {
        final target = ll.LatLng(pos.latitude, pos.longitude);
        _currentCenter = target;
        _mapController.move(target, 15.5);
        _resolveNearestHub(target);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not obtain GPS location: $e'),
            backgroundColor: SahyanColors.urgentCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  void _confirmSelection() {
    final location = LocationModel(
      name: _resolvedTitle,
      address: _resolvedAddress,
      city: _resolvedCity,
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      placeId: 'map_pin_${_currentCenter.latitude}_${_currentCenter.longitude}',
    );
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final tileConfig =
        MapProviderConfig.providers[_selectedProviderType] ??
        MapProviderConfig.providers[MapProviderType.osmStandard]!;

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      body: Stack(
        children: [
          // ─── 1. FlutterMap Viewport ───────────────────────────────────────
          fmap.FlutterMap(
            mapController: _mapController,
            options: fmap.MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.5,
              interactionOptions: const fmap.InteractionOptions(
                flags: fmap.InteractiveFlag.all,
              ),
              onMapReady: () {
                _isMapReady = true;
              },
              onPositionChanged: (position, hasGesture) {
                final c = position.center;
                if (_isValid(c.latitude, c.longitude)) {
                  _currentCenter = c;
                  if (hasGesture) {
                    if (!_isMapMoving) {
                      _isMapMoving = true;
                      _pinAnimController.forward();
                    }
                  }
                }
              },
              onMapEvent: (event) {
                if (event is fmap.MapEventMoveEnd) {
                  if (_isMapMoving) {
                    _isMapMoving = false;
                    _pinAnimController.reverse();
                    _resolveNearestHub(_currentCenter);
                  }
                }
              },
            ),
            children: [
              fmap.TileLayer(
                key: ValueKey(_selectedProviderType),
                urlTemplate: tileConfig.urlTemplate,
                fallbackUrl: tileConfig.fallbackUrl,
                subdomains: tileConfig.subdomains,
                userAgentPackageName: tileConfig.userAgentPackageName,
                maxZoom: tileConfig.maxZoom.toDouble(),
                tileProvider: SahyanTileProvider.create(),
                tileBuilder: (context, tileWidget, tile) {
                  return tileWidget;
                },
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('MAP PICKER TILE ERROR: $error');
                },
              ),
            ],
          ),

          // ─── 2. Fixed Tactile Center Target Pin ───────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _pinBounceAnimation,
              builder: (context, child) {
                return FractionalTranslation(
                  translation: Offset(0, -0.5 + (_pinBounceAnimation.value / 60)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Pin Head
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isPickup
                                ? [
                                    SahyanColors.primaryDark,
                                    const Color(0xFF1B4D3E),
                                  ]
                                : [
                                    SahyanColors.goldStar,
                                    const Color(0xFFD97706),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Icon(
                          widget.isPickup
                              ? Icons.my_location_rounded
                              : Icons.location_on_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      // Pin Stem
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: widget.isPickup
                              ? SahyanColors.primaryDark
                              : SahyanColors.goldStar,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Shadow on ground
                      Container(
                        width: _isMapMoving ? 10 : 16,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: _isMapMoving ? 0.15 : 0.35,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ─── 3. Top Floating App Bar ──────────────────────────────────────
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
                    // Back/Dismiss Button
                    Material(
                      color: SahyanColors.surface,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 22,
                            color: SahyanColors.textMain,
                          ),
                        ),
                      ),
                    ),

                    // Title Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: SahyanColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: SahyanColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.isPickup
                                  ? SahyanColors.primaryDark
                                  : SahyanColors.goldStar,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Layer Switcher Menu Button
                    PopupMenuButton<MapProviderType>(
                      initialValue: _selectedProviderType,
                      elevation: 4,
                      color: SahyanColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      icon: Material(
                        color: SahyanColors.surface,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.layers_rounded,
                            size: 20,
                            color: SahyanColors.primaryDark,
                          ),
                        ),
                      ),
                      onSelected: (type) {
                        setState(() => _selectedProviderType = type);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: MapProviderType.osmStandard,
                          child: Text('OpenStreetMap Standard'),
                        ),
                        const PopupMenuItem(
                          value: MapProviderType.osmHot,
                          child: Text('Sahyān High-Contrast'),
                        ),
                        const PopupMenuItem(
                          value: MapProviderType.satellite,
                          child: Text('Satellite Aerial'),
                        ),
                        const PopupMenuItem(
                          value: MapProviderType.cyclosm,
                          child: Text('Topographic Terrain'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 4. Floating Map Controls (Right Side) ─────────────────────────
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GPS Locate Me Button
                Material(
                  color: SahyanColors.surface,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _handleGpsLocate,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isLocatingGps
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: SahyanColors.primaryDark,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              size: 22,
                              color: SahyanColors.primaryDark,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Zoom Controls Group
                Container(
                  decoration: BoxDecoration(
                    color: SahyanColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        color: SahyanColors.textMain,
                        onPressed: () {
                          if (_isMapReady) {
                            final current = _mapController.camera.zoom;
                            _mapController.move(_currentCenter, current + 1.0);
                          }
                        },
                      ),
                      Container(
                        width: 24,
                        height: 1,
                        color: SahyanColors.border,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        color: SahyanColors.textMain,
                        onPressed: () {
                          if (_isMapReady) {
                            final current = _mapController.camera.zoom;
                            _mapController.move(_currentCenter, current - 1.0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── 5. Bottom Confirmation Card ───────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: SahyanColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag indicator handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: SahyanColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Location Info Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.isPickup
                                ? SahyanColors.primaryMint.withValues(alpha: 0.2)
                                : SahyanColors.goldStar.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.isPickup
                                ? Icons.storefront_rounded
                                : Icons.flag_rounded,
                            size: 22,
                            color: widget.isPickup
                                ? SahyanColors.primaryDark
                                : SahyanColors.goldStar,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _resolvedTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: SahyanColors.textMain,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _resolvedAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: SahyanColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Primary Action Button
                    ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SahyanColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm ${widget.isPickup ? "Pickup Point" : "Destination"}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
}
