import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/core/widgets/verification_badge.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/features/rides/presentation/widgets/route_map_preview.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/widgets/auth_gate_dialog.dart';
import '../rides_provider.dart';

class RideDetailsScreen extends ConsumerWidget {
  const RideDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(selectedRideProvider);
    final searchResult = ref.watch(selectedSearchResultProvider);

    if (ride == null) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: AppBar(
          title: Text('Ride Overview', style: AppTypography.sectionHeader),
        ),
        body: const Center(child: Text('No ride selected')),
      );
    }

    final driverInitial = ride.driverName.isNotEmpty
        ? ride.driverName.substring(0, 1).toUpperCase()
        : 'D';

    final departureFormatted = DateFormat(
      'EEE, dd MMM yyyy',
    ).format(ride.dateTime);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Ride Overview', style: AppTypography.sectionHeader),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preliminary match info from search (if available)
            if (searchResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softForest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryForest.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preliminary Proximity Match',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            searchResult.matchPreview,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.deepForest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Route Map Preview Canvas
            RouteMapPreview(
              origin: ride.origin,
              destination: ride.destination,
              route: ride.route,
              height: 200,
            ),

            const SizedBox(height: 16),

            // Driver Profile Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.softForest,
                      child: Text(
                        driverInitial,
                        style: AppTypography.screenTitle.copyWith(
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ),
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
                          RatingDisplay(rating: ride.driverRating),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Journey Route Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Journey Route',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(departureFormatted, style: AppTypography.caption),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.radio_button_checked,
                              size: 18,
                              color: AppColors.primaryForest,
                            ),
                            Container(
                              width: 2,
                              height: 48,
                              color: AppColors.border,
                            ),
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppColors.mutedSage,
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
                                  color: AppColors.primaryForest,
                                ),
                              ),
                              Text(
                                ride.origin.address.isNotEmpty
                                    ? ride.origin.address
                                    : ride.origin.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (ride.origin.city.isNotEmpty)
                                Text(
                                  ride.origin.city,
                                  style: AppTypography.secondary,
                                ),
                              const SizedBox(height: 16),
                              Text(
                                ride.estimatedArrival,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                ride.destination.address.isNotEmpty
                                    ? ride.destination.address
                                    : ride.destination.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (ride.destination.city.isNotEmpty)
                                Text(
                                  ride.destination.city,
                                  style: AppTypography.secondary,
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
                          Text(
                            'Estimated Distance',
                            style: AppTypography.secondary,
                          ),
                          Text(
                            ride.route!.formattedDistance,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Travel Time',
                            style: AppTypography.secondary,
                          ),
                          Text(
                            ride.route!.formattedDuration,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vehicle Information Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warmBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: AppColors.primaryForest,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.vehicle.fullName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Plate: ${ride.vehicle.registrationNumber} • ${ride.vehicle.color}',
                            style: AppTypography.secondary,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ride.availableSeats} of ${ride.totalSeats} seats open',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryForest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pickup Policy Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ride.pickupPolicy == PickupPolicy.exact
                            ? Icons.pin_drop_rounded
                            : Icons.near_me_rounded,
                        color: AppColors.primaryForest,
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
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.pickupPolicy == PickupPolicy.exact
                                ? 'Driver meets passenger at the exact requested address.'
                                : 'Driver meets passenger at the nearest designated hub or highway landmark.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (ride.amenities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride Amenities',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
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
                              color: AppColors.warmBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              amenity,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (ride.notes != null && ride.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Notes',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(ride.notes!, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
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
                Text('Seat Contribution', style: AppTypography.caption),
                Text(
                  '₹${ride.contributionPerSeat.toStringAsFixed(0)}',
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: PrimaryButton(
                text: 'Request Seat',
                onPressed: () {
                  final isGuest = ref.read(userModeProvider).isGuest;
                  if (isGuest) {
                    AuthGateDialog.show(
                      context,
                      title: 'Sign In to Request Seat',
                      message:
                          'To reserve seats and communicate with verified drivers, please sign in or register.',
                      intendedRoute: '/home',
                    );
                    return;
                  }

                  // Placeholder action for Phase 8 booking
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Seat booking will be enabled in Phase 8 (Booking Engine).',
                      ),
                      backgroundColor: AppColors.primaryForest,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
