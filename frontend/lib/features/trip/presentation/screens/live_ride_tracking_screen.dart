import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import 'package:sahyan/core/widgets/design_system.dart';
import 'package:sahyan/core/network/socket_client.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/rides/domain/services/route_geometry_service.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/trip/presentation/widgets/sos_action_bottom_sheet.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sahyan_route_map.dart';

class LiveRideTrackingScreen extends StatefulWidget {
  final String? originName;
  final String? destinationName;
  final String? driverName;
  final double? driverRating;
  final String? vehicleInfo;
  final VehicleType vehicleType;
  final BookingModel? booking;

  /// The active ride ID used to subscribe to the Socket.IO room.
  final String? rideId;

  /// The current user ID (passenger) for joining the socket room.
  final String? userId;

  const LiveRideTrackingScreen({
    super.key,
    this.originName,
    this.destinationName,
    this.driverName,
    this.driverRating,
    this.vehicleInfo,
    this.vehicleType = VehicleType.sedan,
    this.booking,
    this.rideId,
    this.userId,
  });

  @override
  State<LiveRideTrackingScreen> createState() => _LiveRideTrackingScreenState();
}

class _LiveRideTrackingScreenState extends State<LiveRideTrackingScreen>
    with SingleTickerProviderStateMixin {
  // ── Location init ────────────────────────────────────────────────────────
  late LocationModel _origin;
  late LocationModel _destination;

  // ── Route geometry ───────────────────────────────────────────────────────
  List<LatLng> _polylinePoints = [];
  fmap.LatLngBounds? _bounds;
  String _highwayCorridor = 'via NH47';
  double _totalDistanceKm = 219.0;
  int _totalDurationMins = 195;
  bool _isLoadingRoute = true;

  // ── Real-time driver state ───────────────────────────────────────────────
  LatLng? _driverPosition;
  double _driverHeading = 0.0;
  double _liveSpeedKmh = 0.0;
  double _remainingKm = 219.0;
  int _remainingMins = 195;
  DateTime? _lastPacketAt;
  StreamSubscription<DriverLocationPayload>? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _gpsInterruptedSub;
  String? _driverGpsWarning;

  // ── Simulation fallback (web / no socket) ────────────────────────────────
  AnimationController? _simController;
  bool _useSimulation = false;

  // ── Connection health ────────────────────────────────────────────────
  StreamSubscription<SocketConnectionState>? _connectionSub;

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _followVehicle = true;
  bool _is3DTilt = false;

  // ── Stop / Halt Detection Engine ──────────────────────────────────────────
  DateTime? _haltStartedAt;
  bool _isVehicleHalted = false;
  bool _manualSimHalt = false;

  @override
  void initState() {
    super.initState();
    _initLocations();
    _loadRouteGeometry();
    _initTelematics();
  }

  // ── Location setup ───────────────────────────────────────────────────────

  void _initLocations() {
    final b = widget.booking;
    if (b != null) {
      _origin = LocationModel(
        name: b.pickup.address.isNotEmpty
            ? b.pickup.address
            : (widget.originName ?? 'Iscon Cross Roads, Ahmedabad'),
        latitude: b.pickup.latitude != 0 ? b.pickup.latitude : 23.0225,
        longitude: b.pickup.longitude != 0 ? b.pickup.longitude : 72.5714,
        address: b.pickup.address,
        city: b.pickup.city.isNotEmpty ? b.pickup.city : 'Ahmedabad',
      );
      _destination = LocationModel(
        name: b.drop.address.isNotEmpty
            ? b.drop.address
            : (widget.destinationName ?? 'Kalawad Road, Rajkot'),
        latitude: b.drop.latitude != 0 ? b.drop.latitude : 22.3039,
        longitude: b.drop.longitude != 0 ? b.drop.longitude : 70.8022,
        address: b.drop.address,
        city: b.drop.city.isNotEmpty ? b.drop.city : 'Rajkot',
      );
    } else {
      _origin = LocationModel.fromCoordinates(
        name: widget.originName ?? 'Iscon Cross Roads, Ahmedabad',
        latitude: 23.0225,
        longitude: 72.5714,
      );
      _destination = LocationModel.fromCoordinates(
        name: widget.destinationName ?? 'Kalawad Road, Rajkot',
        latitude: 22.3039,
        longitude: 70.8022,
      );
    }
  }

  // ── Route geometry ───────────────────────────────────────────────────────

  Future<void> _loadRouteGeometry() async {
    try {
      final result = await RouteGeometryService.calculateRoute(
        origin: _origin,
        destination: _destination,
      );
      if (!mounted) return;
      setState(() {
        _polylinePoints = result.polylinePoints;
        _bounds = result.bounds;
        _highwayCorridor = result.highwayCorridor;
        _totalDistanceKm = result.distanceKm;
        _totalDurationMins = result.durationMinutes;
        _remainingKm = result.distanceKm;
        _remainingMins = result.durationMinutes;
        _isLoadingRoute = false;
      });

      // If simulation was already started, seed initial position on route
      if (_useSimulation && _simController != null) {
        _updateSimPosition(_simController!.value);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route unavailable. Please try again.'),
          backgroundColor: SahyanColors.urgentCoral,
        ),
      );
    }
  }

  // ── Telematics: socket or simulation fallback ────────────────────────────

  void _initTelematics() {
    final rideId = widget.rideId ?? widget.booking?.id;

    // On web there's no native GPS — always use simulation
    if (kIsWeb || rideId == null) {
      _startSimulation();
      return;
    }

    // Try to connect and subscribe
    try {
      final socketClient = SocketClient.instance;
      socketClient.connect();

      _connectionSub = socketClient.connectionState.listen((state) {
        // Connection state changes are reflected via _lastPacketAt and health dot
        if (kDebugMode) {
          debugPrint('[LiveTracking] Socket: $state');
        }
      });

      socketClient.joinRideRoom(
        rideId,
        widget.userId ?? 'passenger-anon',
        'passenger',
      );

      _locationSub = socketClient
          .onDriverLocation(rideId)
          .listen(
            _onDriverLocationPayload,
            onError: (_) {
              if (widget.rideId?.startsWith('demo') == true) {
                _startSimulationIfNoData();
              }
            },
          );

      _gpsInterruptedSub = socketClient
          .onGpsInterrupted(rideId)
          .listen((data) {
            if (!mounted) return;
            setState(() {
              _driverGpsWarning =
                  data['reason']?.toString() ??
                  'Safety Warning: Driver GPS telemetry interrupted.';
            });
          });

      // Do not fabricate live activity or moving telemetry for real rides
      // Only start simulation preview if explicitly in a demo/preview ride
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _driverPosition == null && widget.rideId?.startsWith('demo') == true) {
          _startSimulationIfNoData();
        }
      });
    } catch (e) {
      debugPrint('[LiveRideTracking] Socket init failed: $e');
      if (widget.rideId?.startsWith('demo') == true) {
        _startSimulation();
      }
    }
  }

  void _onDriverLocationPayload(DriverLocationPayload payload) {
    if (!mounted) return;

    // Deactivate simulation if socket starts delivering data
    if (_useSimulation) {
      _simController?.stop();
      _useSimulation = false;
    }

    final newPos = LatLng(payload.latitude, payload.longitude);
    final remaining = _haversineDistanceKm(
      newPos.latitude,
      newPos.longitude,
      _destination.latitude,
      _destination.longitude,
    );
    final speed = payload.speed >= 0 ? payload.speed : 0.0;
    final etaMins = ((remaining / (speed > 5.0 ? speed : 40.0)) * 60).round().clamp(
      1,
      _totalDurationMins,
    );

    _updateHaltState(speed);

    setState(() {
      _driverPosition = newPos;
      _driverHeading = payload.heading;
      _liveSpeedKmh = speed;
      _remainingKm = remaining;
      _remainingMins = etaMins;
      _lastPacketAt = DateTime.now();
    });
  }

  void _updateHaltState(double speed) {
    final now = DateTime.now();
    if (speed < 3.0 || _manualSimHalt) {
      _haltStartedAt ??= now;
      final elapsedSec = now.difference(_haltStartedAt!).inSeconds;
      if (elapsedSec >= 20 || _manualSimHalt) {
        _isVehicleHalted = true;
      }
    } else if (speed > 10.0) {
      _haltStartedAt = null;
      _isVehicleHalted = false;
      _manualSimHalt = false;
    }
  }

  void _startSimulationIfNoData() {
    if (!mounted || _driverPosition != null) return;
    _startSimulation();
  }

  void _startSimulation() {
    if (_useSimulation) return;
    _useSimulation = true;

    _simController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _simController!.addListener(() {
      _updateSimPosition(_simController!.value);
    });
    _simController!.repeat();
  }

  void _updateSimPosition(double progress) {
    if (_polylinePoints.length < 2) return;
    final effectiveProgress = (0.35 + progress * 0.60) % 1.0;
    final totalPoints = _polylinePoints.length;
    final floatIndex = effectiveProgress * (totalPoints - 1);
    final baseIndex = floatIndex.floor().clamp(0, totalPoints - 2);
    final frac = floatIndex - baseIndex;

    final p1 = _polylinePoints[baseIndex];
    final p2 = _polylinePoints[baseIndex + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

    final dLat = p2.latitude - p1.latitude;
    final dLng = p2.longitude - p1.longitude;
    final headingRad = math.atan2(dLng, dLat);
    final headingDeg = (headingRad * 180.0 / math.pi + 360.0) % 360.0;

    final simPos = LatLng(lat, lng);
    final remaining = _haversineDistanceKm(
      lat,
      lng,
      _destination.latitude,
      _destination.longitude,
    );
    final etaMins = ((_totalDurationMins * (1.0 - effectiveProgress)).clamp(
      4.0,
      _totalDurationMins.toDouble(),
    )).toInt();

    final simSpeed = _manualSimHalt
        ? 0.0
        : (42.0 + (math.sin(progress * math.pi * 4) * 8));

    _updateHaltState(simSpeed);

    setState(() {
      _driverPosition = simPos;
      _driverHeading = headingDeg;
      _liveSpeedKmh = simSpeed;
      _remainingKm = remaining;
      _remainingMins = etaMins;
    });
  }

  // ── ETA / Haversine ──────────────────────────────────────────────────────

  double _haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0; // Earth radius km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (r * c).clamp(0.1, _totalDistanceKm);
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  // ── Connection & Stale GPS health ─────────────────────────────────────────

  /// Calculates telemetry age in seconds
  int get _locationAgeSeconds {
    if (_lastPacketAt == null) return 999999;
    return DateTime.now().difference(_lastPacketAt!).inSeconds;
  }

  /// Live GPS fix: received within 10 seconds
  bool get _isLiveGps {
    if (_useSimulation) return false;
    return _locationAgeSeconds < 10;
  }

  /// Degraded GPS fix: received between 10 and 30 seconds ago
  bool get _isDegradedGps {
    if (_useSimulation) return false;
    return _locationAgeSeconds >= 10 && _locationAgeSeconds <= 30;
  }

  /// Stale GPS fix: no update received for > 30 seconds
  bool get _isStaleGps {
    if (_useSimulation) return false;
    return _lastPacketAt != null && _locationAgeSeconds > 30;
  }

  /// Calculates perpendicular distance from coordinate to polyline segment in km
  double _distanceToSegmentKm(LatLng p, LatLng a, LatLng b) {
    final x = p.longitude;
    final y = p.latitude;
    final x1 = a.longitude;
    final y1 = a.latitude;
    final x2 = b.longitude;
    final y2 = b.latitude;

    final dx = x2 - x1;
    final dy = y2 - y1;
    if (dx == 0 && dy == 0) {
      return _haversineDistanceKm(y, x, y1, x1);
    }

    final t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);
    final projLat = y1 + clampedT * dy;
    final projLng = x1 + clampedT * dx;

    return _haversineDistanceKm(y, x, projLat, projLng);
  }

  /// Detects whether the active vehicle has drifted off the designated highway route corridor (> 450m)
  bool get _isOffRoute {
    if (_driverPosition == null || _polylinePoints.length < 2) return false;
    double minDistance = double.infinity;
    for (int i = 0; i < _polylinePoints.length - 1; i++) {
      final d = _distanceToSegmentKm(
        _driverPosition!,
        _polylinePoints[i],
        _polylinePoints[i + 1],
      );
      if (d < minDistance) minDistance = d;
    }
    return minDistance > 0.45;
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _gpsInterruptedSub?.cancel();
    _connectionSub?.cancel();
    _simController?.dispose();

    final rideId = widget.rideId ?? widget.booking?.id;
    if (rideId != null && !kIsWeb) {
      SocketClient.instance.leaveRideRoom(rideId);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver =
        widget.driverName ??
        widget.booking?.ride?.driverName ??
        'Verified Driver';
    final vehicle =
        widget.vehicleInfo ??
        (widget.booking?.ride != null
            ? '${widget.booking!.ride!.vehicle.make} ${widget.booking!.ride!.vehicle.model} \u2022 ${widget.booking!.ride!.vehicle.registrationNumber}'
            : 'Vehicle Confirmed');
    final rating =
        widget.driverRating ?? widget.booking?.ride?.driverRating ?? 4.92;

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: SahyanAppBar(
        title: 'Live Tracking',
        subtitle: '$_highwayCorridor \u2022 Real-time Corridor Mesh',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryForest,
              size: 22,
            ),
            tooltip: 'Safety Center',
            onPressed: () => context.push('/trip-safety'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen Map View
            Positioned.fill(
              child: SahyanRouteMap(
                origin: _origin,
                destination: _destination,
                polylinePoints: _polylinePoints,
                bounds: _bounds,
                driverPosition: _driverPosition,
                driverHeading: _driverHeading,
                showControls: true,
                interactive: true,
                vehicleTypeCode: widget.vehicleType.code,
                followVehicle: _followVehicle,
                onFollowToggle: (val) => setState(() => _followVehicle = val),
                isVehicleStopped: _isVehicleHalted,
                liveSpeedKmh: _liveSpeedKmh,
                tiltAngle: _is3DTilt ? 42.0 : 0.0,
              ),
            ),

            if (_isLoadingRoute)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  color: SahyanColors.primaryMint,
                  backgroundColor: Colors.transparent,
                ),
              ),

            // Top Floating Glass Card: Driver & Live ETA
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: _buildFloatingGlassTopCard(
                driver: driver,
                rating: rating,
                vehicle: vehicle,
              ),
            ),

            if (_driverGpsWarning != null)
              Positioned(
                top: 136,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SahyanColors.urgentCoral.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _driverGpsWarning!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isOffRoute)
              Positioned(
                top: 136,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.alt_route_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Route Deviation: Vehicle has departed from scheduled route corridor.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isStaleGps)
              Positioned(
                top: 136,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sync_problem_rounded,
                        color: Color(0xFFFBBF24),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'GPS Signal Delayed \u2022 Awaiting telematics update',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Floating Telematics & Camera Controls (3D Tilt & Simulation Halt)
            Positioned(
              right: 16,
              bottom: 110,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'tilt_btn',
                    backgroundColor:
                        _is3DTilt ? SahyanColors.primaryDark : SahyanColors.surface,
                    foregroundColor:
                        _is3DTilt ? SahyanColors.primaryMint : SahyanColors.primaryDark,
                    elevation: 3,
                    tooltip: _is3DTilt
                        ? 'Reset to 2D Top View'
                        : '3D Driving View (45° Tilt)',
                    onPressed: () {
                      setState(() {
                        _is3DTilt = !_is3DTilt;
                      });
                    },
                    child: Icon(
                      _is3DTilt
                          ? Icons.view_in_ar_rounded
                          : Icons.threed_rotation_rounded,
                      size: 20,
                    ),
                  ),
                  if (_useSimulation) ...[
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'halt_btn',
                      backgroundColor: _isVehicleHalted
                          ? const Color(0xFFF59E0B)
                          : SahyanColors.surface,
                      foregroundColor: _isVehicleHalted
                          ? Colors.white
                          : const Color(0xFFF59E0B),
                      elevation: 3,
                      tooltip: _isVehicleHalted
                          ? 'Resume Transit Simulation'
                          : 'Simulate Stop / Halt',
                      onPressed: () {
                        setState(() {
                          _manualSimHalt = !_manualSimHalt;
                          if (!_manualSimHalt) {
                            _haltStartedAt = null;
                            _isVehicleHalted = false;
                          }
                        });
                      },
                      child: Icon(
                        _isVehicleHalted
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 22,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Contact Action Dock
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomContactActionDock(driver: driver),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top card ─────────────────────────────────────────────────────────────

  Widget _buildFloatingGlassTopCard({
    required String driver,
    required double rating,
    required String vehicle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SahyanColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SahyanColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SahyanAvatar(name: driver, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driver,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: SahyanColors.primaryMint,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: SahyanColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: SahyanColors.goldStar,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: SahyanColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: SahyanColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              VehicleIcon.illustration(
                type: widget.vehicleType,
                width: 38,
                height: 22,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Live ETA + speed / stop telematics banner ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isVehicleHalted
                  ? const Color(0xFF78350F) // Deep amber-brown for stop alert
                  : SahyanColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
              border: _isVehicleHalted
                  ? Border.all(color: const Color(0xFFF59E0B), width: 1.2)
                  : null,
            ),
            child: Row(
              children: [
                // Stop/Halt pulsing badge or connection health dot
                if (_isVehicleHalted)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  _buildConnectionHealthDot(),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _isVehicleHalted
                        ? 'Vehicle Halted · Limbdi Toll'
                        : (_liveSpeedKmh > 15
                            ? 'In Transit · ${_liveSpeedKmh.toStringAsFixed(0)} km/h · ETA $_remainingMins mins'
                            : (_driverPosition != null
                                ? '${_remainingKm.toStringAsFixed(1)} km away · $_remainingMins mins'
                                : 'Awaiting driver location update...')),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Live speed or Stop indicator pill
                if (_isVehicleHalted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'HALTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else if (_liveSpeedKmh > 15)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SahyanColors.primaryMint.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: SahyanColors.primaryMint.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'In Transit · ${_liveSpeedKmh.toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        color: SahyanColors.primaryMint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge indicating GPS stream health and freshness.
  Widget _buildConnectionHealthDot() {
    Color color;
    String label;

    if (_useSimulation) {
      color = SahyanColors.primaryMint.withValues(alpha: 0.7);
      label = 'Simulated Preview';
    } else if (_isLiveGps) {
      color = const Color(0xFF10B981); // Emerald Green
      label = 'Live GPS';
    } else if (_isDegradedGps) {
      color = const Color(0xFFF59E0B); // Amber Warning
      label = 'Degraded (${_locationAgeSeconds}s ago)';
    } else if (_isStaleGps) {
      color = const Color(0xFFEF4444); // Red Stale
      label = 'Stale GPS (${_locationAgeSeconds}s ago)';
    } else {
      color = SahyanColors.textMuted;
      label = 'Awaiting GPS Fix';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── Bottom dock ──────────────────────────────────────────────────────────

  Widget _buildBottomContactActionDock({required String driver}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: SahyanColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route timeline bar
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SahyanColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 1.5, height: 18, color: SahyanColors.border),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SahyanColors.primaryMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _origin.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _destination.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Action Buttons: Call, Chat, Share, SOS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling driver ($driver)...'),
                        backgroundColor: SahyanColors.primaryDark,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SahyanColors.primaryDark,
                    side: const BorderSide(
                      color: SahyanColors.border,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/messages/${widget.booking?.id ?? "conv-1"}',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SahyanColors.primaryDark,
                    side: const BorderSide(
                      color: SahyanColors.border,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final bookingId = widget.booking?.id ?? 'active-trip';
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'https://sahyan.app/live-tracking/track-live?bookingId=$bookingId',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Live tracking link copied to clipboard.',
                        ),
                        backgroundColor: SahyanColors.primaryDark,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SahyanColors.primaryDark,
                    side: const BorderSide(
                      color: SahyanColors.border,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => SosActionBottomSheet.show(
                    context,
                    booking: widget.booking,
                  ),
                  icon: const Icon(
                    Icons.emergency_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SahyanColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
