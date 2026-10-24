import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:latlong2/latlong.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/sahyan_avatar.dart';
import 'package:sahyan/core/widgets/sahyan_card.dart';
import 'package:sahyan/core/widgets/sahyan_match_score_badge.dart';
import 'package:sahyan/core/widgets/sahyan_status_badge.dart';
import 'package:sahyan/core/widgets/verification_badge.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/rides/domain/services/route_geometry_service.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/rides/presentation/widgets/request_seat_bottom_sheet.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/widgets/auth_gate_dialog.dart';
import 'package:sahyan/shared/widgets/sahyan_route_map.dart';
import 'package:sahyan/shared/widgets/full_screen_route_map_sheet.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import '../rides_provider.dart';

class RideDetailsScreen extends ConsumerWidget {
  final String? rideId;
  final RideModel? initialRide;

  const RideDetailsScreen({
    super.key,
    this.rideId,
    this.initialRide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Prioritize initialRide if provided directly
    RideModel? ride = initialRide;

    // 2. Check selectedRideProvider if available and matches
    if (ride == null) {
      final selectedRide = ref.watch(selectedRideProvider);
      if (selectedRide != null &&
          (rideId == null || rideId!.isEmpty || selectedRide.id == rideId)) {
        ride = selectedRide;
      }
    }

    // 3. If still null and rideId is provided, fetch via rideByIdProvider
    if (ride == null && rideId != null && rideId!.isNotEmpty) {
      final rideAsync = ref.watch(rideByIdProvider(rideId!));
      return rideAsync.when(
        data: (fetchedRide) => _buildScaffold(context, ref, fetchedRide),
        loading: () => const Scaffold(
          backgroundColor: AppColors.lightSurface,
          appBar: SahyanAppBar(title: 'Ride Overview'),
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.deepEmerald,
            ),
          ),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: AppColors.lightSurface,
          appBar: const SahyanAppBar(title: 'Ride Overview'),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load ride details',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(rideByIdProvider(rideId!)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepEmerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (ride == null) {
      return const Scaffold(
        backgroundColor: AppColors.lightSurface,
        appBar: SahyanAppBar(title: 'Ride Overview'),
        body: Center(
          child: Text(
            'No ride selected',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
      );
    }

    return _buildScaffold(context, ref, ride);
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, RideModel ride) {
    final searchResult = ref.watch(selectedSearchResultProvider);
    final departureFormatted = DateFormat(
      'EEE, dd MMM yyyy',
    ).format(ride.dateTime);

    return Scaffold(
      backgroundColor: AppColors.lightSurface,
      appBar: const SahyanAppBar(title: 'Ride Overview'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match breakdown card if search match details are available
            if (searchResult?.match != null) ...[
              SahyanMatchScoreBreakdownCard(matchDetails: searchResult!.match!),
              const SizedBox(height: AppSpacing.md),
            ] else if (searchResult != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.softMint.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: AppColors.deepEmerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.deepEmerald,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        searchResult.matchPreview,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Interactive Route Corridor Map & Detour Telemetry
            Builder(
              builder: (context) {
                final polylinePoints =
                    (ride.route != null &&
                        ride.route!.encodedPolyline.isNotEmpty)
                    ? RouteService.decodePolyline(
                        ride.route!.encodedPolyline,
                      ).map((pt) => LatLng(pt.latitude, pt.longitude)).toList()
                    : <LatLng>[];

                final bounds = polylinePoints.isNotEmpty
                    ? RouteGeometryService.calculateBounds(polylinePoints)
                    : null;

                final corridor = RouteGeometryService.getHighwayCorridor(
                  ride.origin,
                  ride.destination,
                );
                final distanceKm = ride.route != null
                    ? (ride.route!.distanceMeters / 1000).toStringAsFixed(0)
                    : '219';
                final durationSec = ride.route?.durationSeconds ?? 11700;
                final hours = durationSec ~/ 3600;
                final minutes = (durationSec % 3600) ~/ 60;
                final durationText = hours > 0
                    ? '${hours}h ${minutes}m'
                    : '${minutes}m';
                final detourKm = searchResult?.match != null
                    ? (searchResult!.match!.metrics.pickupDistanceKm +
                          searchResult.match!.metrics.destinationDistanceKm)
                    : null;

                return Column(
                  children: [
                    // Dynamic Telemetry & Detour Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkEmerald,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.alt_route_rounded,
                                  color: AppColors.softMint,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$corridor · $distanceKm km · $durationText',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softMint.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              detourKm != null
                                  ? '${detourKm.toStringAsFixed(1)} km detour'
                                  : 'Direct corridor',
                              style: const TextStyle(
                                color: AppColors.softMint,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            SayanRouteMap(
                              origin: ride.origin,
                              destination: ride.destination,
                              polylinePoints: polylinePoints,
                              bounds: bounds,
                            ),
                            // Tap to expand
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    FullScreenRouteMapSheet.show(
                                      context: context,
                                      origin: ride.origin,
                                      destination: ride.destination,
                                      polylinePoints: polylinePoints,
                                      bounds: bounds,
                                      corridorHighway:
                                          'Gujarat Highway Corridor Active',
                                      distanceKm: ride.route?.distanceKm,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Expand Map Button
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: AppColors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    FullScreenRouteMapSheet.show(
                                      context: context,
                                      origin: ride.origin,
                                      destination: ride.destination,
                                      polylinePoints: polylinePoints,
                                      bounds: bounds,
                                      corridorHighway:
                                          'Gujarat Highway Corridor Active',
                                      distanceKm: ride.route?.distanceKm,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.open_in_full_rounded,
                                          size: 12,
                                          color: AppColors.deepEmerald,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Expand Map',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.deepEmerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Driver Profile Header Card
            SahyanCard(
              padding: AppSpacing.paddingCard,
              child: Row(
                children: [
                  SahyanAvatar(name: ride.driverName, radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ride.driverName,
                                style: AppTypography.sectionHeader.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            VerificationBadge(
                              isVerified: ride.isDriverVerified,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingDisplay(rating: ride.driverRating),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Verified Community Driver',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
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
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Journey Route Card
            SahyanCard(
              padding: AppSpacing.paddingCardLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Journey Route',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SahyanStatusBadge.fromRideStatus(ride.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    departureFormatted,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.radio_button_checked,
                            size: 18,
                            color: AppColors.deepEmerald,
                          ),
                          Container(
                            width: 2,
                            height: 48,
                            color: AppColors.border,
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.champagneGold,
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.departureTime,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepEmerald,
                              ),
                            ),
                            Text(
                              ride.origin.address.isNotEmpty
                                  ? ride.origin.address
                                  : ride.origin.name,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            if (ride.origin.city.isNotEmpty)
                              Text(
                                ride.origin.city,
                                style: AppTypography.secondary.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              ride.estimatedArrival,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText,
                              ),
                            ),
                            Text(
                              ride.destination.address.isNotEmpty
                                  ? ride.destination.address
                                  : ride.destination.name,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            if (ride.destination.city.isNotEmpty)
                              Text(
                                ride.destination.city,
                                style: AppTypography.secondary.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (ride.route != null) ...[
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Estimated Distance',
                            style: AppTypography.secondary.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ride.route!.formattedDistance,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Estimated Travel Time',
                            style: AppTypography.secondary.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ride.route!.formattedDuration,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Vehicle Information Card with Sahyan Vehicle System
            SahyanCard(
              padding: AppSpacing.paddingCard,
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: VehicleIcon.illustration(
                      type: ride.vehicle.type,
                      width: 64,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ride.vehicle.fullName,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ride.vehicle.type.isElectric) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softMint.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.full,
                                  ),
                                ),
                                child: Text(
                                  'EV',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.deepEmerald,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride.vehicle.type.displayName} \u2022 Plate: ${ride.vehicle.registrationNumber}',
                          style: AppTypography.secondary.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softMint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      '${ride.availableSeats} of ${ride.totalSeats} open',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.deepEmerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Pickup Policy Card
            SahyanCard(
              padding: AppSpacing.paddingCard,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softMint.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ride.pickupPolicy == PickupPolicy.exact
                          ? Icons.pin_drop_rounded
                          : Icons.near_me_rounded,
                      color: AppColors.deepEmerald,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickupPolicy == PickupPolicy.exact
                              ? 'Exact Pickup Policy'
                              : 'Nearby Hub Meeting Policy',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.pickupPolicy == PickupPolicy.exact
                              ? 'Driver meets passenger at the exact requested address.'
                              : 'Driver meets passenger at the nearest designated hub or highway landmark.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (ride.amenities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SahyanCard(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Amenities',
                      style: AppTypography.sectionHeader.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ride.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            amenity,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            if (ride.notes != null && ride.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SahyanCard(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Notes',
                      style: AppTypography.sectionHeader.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ride.notes!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Transparent Contribution Breakdown Card
            SahyanCard(
              padding: AppSpacing.paddingCardLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: AppColors.deepEmerald,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contribution Breakdown',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Shared Fuel & Vehicle Contribution',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\u20B9${ride.contributionPerSeat.toStringAsFixed(0)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Platform Safety & Facilitation Fee',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\u20B90 (Waived)',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Contribution per Seat',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\u20B9${ride.contributionPerSeat.toStringAsFixed(0)}',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '100% of the shared contribution directly offsets driver fuel and toll costs for this shared journey.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Trust, Safety & Cancellation Guidelines Card
            SahyanCard(
              padding: AppSpacing.paddingCardLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppColors.deepEmerald,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trust, Safety & Policies',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPolicyBullet(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Free Cancellation',
                    subtitle:
                        'Cancel with zero penalty up to 2 hours before scheduled departure time.',
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyBullet(
                    icon: Icons.pin_rounded,
                    title: 'Secure Boarding PIN',
                    subtitle:
                        'Share your confidential 4-digit PIN with the driver only after boarding.',
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyBullet(
                    icon: Icons.emergency_outlined,
                    title: 'Live Journey & SOS Protection',
                    subtitle:
                        'Automated corridor tracking and direct emergency dispatch available throughout.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seat Contribution',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  Text(
                    '\u20B9${ride.contributionPerSeat.toStringAsFixed(0)}',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppColors.deepEmerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildBookingButton(context, ref, ride)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyBullet({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.deepEmerald),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmallBold.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton(
    BuildContext context,
    WidgetRef ref,
    RideModel ride,
  ) {
    if (ride.isBoarding) {
      return const PrimaryButton(
        text: 'Boarding in Progress',
        isDisabled: true,
      );
    }
    if (ride.isActive) {
      return const PrimaryButton(text: 'Trip in Progress', isDisabled: true);
    }
    if (ride.isCompleted) {
      return const PrimaryButton(text: 'Trip Completed', isDisabled: true);
    }
    if (ride.isCancelled) {
      return const PrimaryButton(text: 'Ride Cancelled', isDisabled: true);
    }
    if (ride.availableSeats <= 0) {
      return const PrimaryButton(text: 'Ride Full', isDisabled: true);
    }

    final bookingsAsync = ref.watch(bookingsNotifierProvider);
    final userBookings = bookingsAsync.value ?? [];
    final matchingBooking = userBookings.where((b) {
      return (b.rideId.isNotEmpty && b.rideId == ride.id) ||
          (b.ride != null && b.ride!.id == ride.id);
    }).firstOrNull;

    if (matchingBooking != null) {
      if (matchingBooking.isPending) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Request Under Review (Pending Driver Approval)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      if (matchingBooking.isAccepted) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.softMint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.deepEmerald.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: AppColors.deepEmerald),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Seat Confirmed · Active Booking',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEmerald,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    final isGuest = ref.watch(userModeProvider).isGuest;

    return PrimaryButton(
      text: 'Request Seat',
      onPressed: () async {
        if (isGuest) {
          final authed = await AuthGateDialog.show(
            context,
            title: 'Sign In to Request Seat',
            message:
                'Create or sign in to your Sahy\u0101n profile to request and confirm seats.',
          );
          if (authed && context.mounted) {
            RequestSeatBottomSheet.show(context, ride);
          }
        } else {
          RequestSeatBottomSheet.show(context, ride);
        }
      },
    );
  }
}
