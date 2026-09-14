import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sahyan/core/widgets/design_system.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/rides/domain/services/route_geometry_service.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/trip/presentation/widgets/sos_action_bottom_sheet.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/sayan_route_map.dart';

class LiveRideTrackingScreen extends StatefulWidget {
  final String? originName;
  final String? destinationName;
  final String? driverName;
  final double? driverRating;
  final String? vehicleInfo;
  final VehicleType vehicleType;
  final BookingModel? booking;

  const LiveRideTrackingScreen({
    super.key,
    this.originName,
    this.destinationName,
    this.driverName,
    this.driverRating,
    this.vehicleInfo,
    this.vehicleType = VehicleType.sedan,
    this.booking,
  });

  @override
  State<LiveRideTrackingScreen> createState() => _LiveRideTrackingScreenState();
}

class _LiveRideTrackingScreenState extends State<LiveRideTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late LocationModel _origin;
  late LocationModel _destination;

  List<LatLng> _polylinePoints = [];
  LatLngBounds? _bounds;
  String _highwayCorridor = 'via NH47';
  double _totalDistanceKm = 219.0;
  int _totalDurationMins = 195;
  bool _isLoadingRoute = true;

  LatLng? _driverPosition;
  double _driverHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _initLocations();
    _initAnimation();
    _loadRouteGeometry();
  }

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

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );

    _animController.addListener(() {
      _updateDriverPositionAlongPolyline(_animController.value);
    });

    _animController.repeat();
  }

  Future<void> _loadRouteGeometry() async {
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
      _isLoadingRoute = false;
    });

    _updateDriverPositionAlongPolyline(_animController.value);
  }

  void _updateDriverPositionAlongPolyline(double progress) {
    if (_polylinePoints.length < 2) return;

    // Simulate progress starting around 35% through route and advancing
    final effectiveProgress = (0.35 + progress * 0.60) % 1.0;
    final totalPoints = _polylinePoints.length;
    final floatIndex = effectiveProgress * (totalPoints - 1);
    final baseIndex = floatIndex.floor().clamp(0, totalPoints - 2);
    final frac = floatIndex - baseIndex;

    final p1 = _polylinePoints[baseIndex];
    final p2 = _polylinePoints[baseIndex + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

    // Calculate heading in degrees
    final dLat = p2.latitude - p1.latitude;
    final dLng = p2.longitude - p1.longitude;
    final headingRad = math.atan2(dLng, dLat);
    final headingDeg = (headingRad * 180.0 / math.pi + 360.0) % 360.0;

    setState(() {
      _driverPosition = LatLng(lat, lng);
      _driverHeading = headingDeg;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driverName ??
        widget.booking?.ride?.driverName ??
        'Rohit Patel';
    final vehicle = widget.vehicleInfo ??
        (widget.booking?.ride != null
            ? '${widget.booking!.ride!.vehicle.make} ${widget.booking!.ride!.vehicle.model} \u2022 ${widget.booking!.ride!.vehicle.registrationNumber}'
            : 'Hyundai Creta \u2022 GJ-01-AB-1234');
    final rating = widget.driverRating ??
        widget.booking?.ride?.driverRating ??
        4.92;

    // Calculate live remaining ETA
    final progress = _animController.value;
    final remainingKm = (_totalDistanceKm * (1.0 - (0.35 + progress * 0.60) % 1.0))
        .clamp(1.2, _totalDistanceKm);
    final remainingMins = ((_totalDurationMins * (1.0 - (0.35 + progress * 0.60) % 1.0))
        .clamp(4.0, _totalDurationMins.toDouble()))
        .toInt();

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
              child: SayanRouteMap(
                origin: _origin,
                destination: _destination,
                polylinePoints: _polylinePoints,
                bounds: _bounds,
                driverPosition: _driverPosition,
                driverHeading: _driverHeading,
                showControls: true,
                interactive: true,
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

            // Top Floating Glass Card: Driver & Live ETA Countdown
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: _buildFloatingGlassTopCard(
                driver: driver,
                rating: rating,
                vehicle: vehicle,
                remainingKm: remainingKm,
                remainingMins: remainingMins,
              ),
            ),

            // Bottom Sliding Contact Action Dock & Trip Telemetry
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomContactActionDock(
                driver: driver,
                remainingKm: remainingKm,
                remainingMins: remainingMins,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingGlassTopCard({
    required String driver,
    required double rating,
    required String vehicle,
    required double remainingKm,
    required int remainingMins,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SahyanColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: SahyanColors.primaryMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${remainingKm.toStringAsFixed(1)} km away \u2022 $remainingMins mins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SahyanColors.primaryMint.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ON TRACK',
                    style: TextStyle(
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

  Widget _buildBottomContactActionDock({
    required String driver,
    required double remainingKm,
    required int remainingMins,
  }) {
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
                  Container(
                    width: 1.5,
                    height: 18,
                    color: SahyanColors.border,
                  ),
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

          // 4 Action Buttons Dock: Call, Chat, Share, Emergency SOS
          Row(
            children: [
              // Call Driver
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

              // Chat
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/messages/${widget.booking?.id ?? "conv-1"}'),
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

              // Share Live Trip
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final bookingId = widget.booking?.id ?? 'active-trip';
                    Clipboard.setData(
                      ClipboardData(
                        text: 'https://sahyan.app/live-tracking/track-live?bookingId=$bookingId',
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

              // Emergency SOS
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => SosActionBottomSheet.show(context, booking: widget.booking),
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
