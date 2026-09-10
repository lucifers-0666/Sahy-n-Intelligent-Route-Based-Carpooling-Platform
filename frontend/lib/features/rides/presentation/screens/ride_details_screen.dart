import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/sahyan_avatar.dart';
import 'package:sahyan/core/widgets/sahyan_card.dart';
import 'package:sahyan/core/widgets/sahyan_match_score_badge.dart';
import 'package:sahyan/core/widgets/sahyan_status_badge.dart';
import 'package:sahyan/core/widgets/verification_badge.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/rides/presentation/widgets/request_seat_bottom_sheet.dart';
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
        appBar: const SahyanAppBar(title: 'Ride Overview'),
        body: const Center(child: Text('No ride selected')),
      );
    }

    final departureFormatted = DateFormat(
      'EEE, dd MMM yyyy',
    ).format(ride.dateTime);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
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
                  color: AppColors.softForest,
                  borderRadius: BorderRadius.circular(AppRadii.card),
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        searchResult.matchPreview,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.deepForest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Route Map Preview Canvas
            RouteMapPreview(
              origin: ride.origin,
              destination: ride.destination,
              route: ride.route,
              height: 200,
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SahyanStatusBadge.fromRideStatus(ride.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(departureFormatted, style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.md),
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

            const SizedBox(height: AppSpacing.md),

            // Vehicle Information Card with Sahyān Vehicle System
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
                                  color: AppColors.softForest,
                                  borderRadius: BorderRadius.circular(AppRadii.full),
                                ),
                                child: Text(
                                  'EV',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
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
                          style: AppTypography.secondary,
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
                      color: AppColors.softForest,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      '${ride.availableSeats} of ${ride.totalSeats} open',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryForest,
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
                    decoration: const BoxDecoration(
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
                            borderRadius: BorderRadius.circular(AppRadii.sm),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(ride.notes!, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ],

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
                  Text('Seat Contribution', style: AppTypography.caption),
                  Text(
                    '\u20B9${ride.contributionPerSeat.toStringAsFixed(0)}',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppColors.primaryForest,
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
