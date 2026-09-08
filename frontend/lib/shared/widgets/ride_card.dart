import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/rating_display.dart';
import '../../core/widgets/sahyan_avatar.dart';
import '../../core/widgets/sahyan_card.dart';
import '../../core/widgets/verification_badge.dart';
import '../../features/rides/domain/ride_search_result.dart';
import '../../features/rides/presentation/widgets/route_match_breakdown_widget.dart';
import '../models/ride_model.dart';

/// Redesigned Sahyān Ride Card matching Figma & Stitch design specifications.
/// Presents ride details, intelligent match breakdown, route timeline, driver credentials, and pricing.
class RideCard extends StatelessWidget {
  final RideModel ride;
  final RideSearchResult? searchResult;
  final VoidCallback onTap;

  const RideCard({
    super.key,
    required this.ride,
    this.searchResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final match = searchResult?.match;
    final proximityBadge = searchResult != null
        ? (searchResult!.pickupDistanceKm <= 1.0
              ? 'Direct Pickup'
              : 'Pickup ~${searchResult!.pickupDistanceKm} km')
        : 'Direct Route';

    return SahyanCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingCard,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Match / Proximity Badges & Price
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (match != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryForest,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match.score}% Match',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        match.grade,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryForest,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            proximityBadge,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (searchResult != null &&
                        searchResult!.departureDifferenceMinutes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmBackground,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${searchResult!.departureDifferenceMinutes}m diff',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              // Pricing Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softForest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '₹${ride.contributionPerSeat.toStringAsFixed(0)} / seat',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryForest,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Journey Route Timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual timeline indicators
              Column(
                children: [
                  const SizedBox(height: 2),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryForest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 2, height: 28, color: AppColors.border),
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.mutedBrass,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Route names & departure/arrival times
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ride.origin.city.isNotEmpty
                                ? ride.origin.city
                                : ride.origin.address,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          ride.departureTime,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ride.destination.city.isNotEmpty
                                ? ride.destination.city
                                : ride.destination.address,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          ride.estimatedArrival,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Route Match Breakdown Link
          if (match != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.warmBackground,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 280;
                  final breakdownButton = InkWell(
                    onTap: () =>
                        RouteMatchBreakdownWidget.showModal(context, match),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Why this match?',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryForest,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: AppColors.primaryForest,
                          ),
                        ],
                      ),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.primaryForest,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                match.reasons.isNotEmpty
                                    ? match.reasons.first
                                    : '${match.metrics.routeOverlapPercentage}% route overlap · ${match.metrics.pickupDistanceKm} km pickup deviation',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.deepForest,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: breakdownButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.primaryForest,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.reasons.isNotEmpty
                              ? match.reasons.first
                              : '${match.metrics.routeOverlapPercentage}% route overlap · ${match.metrics.pickupDistanceKm} km pickup deviation',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.deepForest,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      breakdownButton,
                    ],
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Footer: Driver Identity & Seats Badge
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;
              final seatsLeftWidget = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warmBackground,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 14,
                      color: AppColors.primaryForest,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ride.availableSeats} seat(s) left',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );

              final driverInfoWidget = Row(
                children: [
                  SahyanAvatar(name: ride.driverName, radius: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ride.driverName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            VerificationBadge(
                              isVerified: ride.isDriverVerified,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            RatingDisplay(rating: ride.driverRating),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '• ${ride.vehicle.fullName}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
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
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    driverInfoWidget,
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: seatsLeftWidget,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: driverInfoWidget),
                  const SizedBox(width: AppSpacing.sm),
                  seatsLeftWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
