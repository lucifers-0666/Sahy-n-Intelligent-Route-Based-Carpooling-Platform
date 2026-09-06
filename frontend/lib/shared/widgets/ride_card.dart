import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/ride_model.dart';
import '../../core/widgets/verification_badge.dart';
import '../../core/widgets/rating_display.dart';

import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/rides/presentation/widgets/route_match_breakdown_widget.dart';

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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Match Badge / Proximity Badge & Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (match != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryForest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 13,
                                  color: AppColors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${match.score}% Match',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softForest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              match.grade,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryForest,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softForest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 13,
                                  color: AppColors.primaryForest,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  proximityBadge,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryForest,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (searchResult != null &&
                              searchResult!.departureDifferenceMinutes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${searchResult!.departureDifferenceMinutes}m diff',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${ride.contributionPerSeat.toStringAsFixed(0)} / seat',
                    style: AppTypography.sectionHeader.copyWith(
                      color: AppColors.primaryForest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Journey Route Timeline
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline graphic
                  Column(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 16,
                        color: AppColors.primaryForest,
                      ),
                      Container(width: 2, height: 32, color: AppColors.border),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.mutedSage,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Route details text
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
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ride.departureTime,
                              style: AppTypography.bodyMedium,
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
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ride.estimatedArrival,
                              style: AppTypography.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (match != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.primaryForest,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.reasons.isNotEmpty
                              ? match.reasons.first
                              : '${match.metrics.routeOverlapPercentage}% route overlap · ${match.metrics.pickupDistanceKm} km pickup deviation',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.deepForest,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
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
                              Text(
                                'Why this match?',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
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
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              // Footer: Driver Info & Seats Available
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.softForest,
                    child: Text(
                      ride.driverName.isNotEmpty
                          ? ride.driverName.substring(0, 1).toUpperCase()
                          : 'D',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                                  fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            RatingDisplay(rating: ride.driverRating),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '• ${ride.vehicle.fullName}',
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                      color: AppColors.warmBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${ride.availableSeats} seat(s) left',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
