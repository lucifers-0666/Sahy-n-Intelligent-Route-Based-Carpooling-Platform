import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/rides/domain/ride_search_result.dart';

/// Compact Match Score Badge for ride cards and list items.
class SahyanMatchScoreBadge extends StatelessWidget {
  final int score;
  final String? grade;
  final VoidCallback? onTap;
  final bool isCompact;

  const SahyanMatchScoreBadge({
    super.key,
    required this.score,
    this.grade,
    this.onTap,
    this.isCompact = false,
  });

  Color get _badgeColor {
    if (score >= 85) return AppColors.primary;
    if (score >= 70) return AppColors.mutedSage;
    return AppColors.mutedBrass;
  }

  Color get _containerColor {
    if (score >= 85) return AppColors.softForest;
    if (score >= 70) return AppColors.surfaceContainer;
    return AppColors.softBrass;
  }

  @override
  Widget build(BuildContext context) {
    final badgeWidget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: isCompact ? 3 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _containerColor,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: _badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route_rounded,
            size: isCompact ? 12 : 14,
            color: _badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$score% Match',
            style: AppTypography.caption.copyWith(
              color: _badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.full),
        child: badgeWidget,
      );
    }
    return badgeWidget;
  }
}

/// Detailed visualization card explaining WHY the ride received its score.
class SahyanMatchScoreBreakdownCard extends StatelessWidget {
  final RouteMatchDetails matchDetails;
  final bool isExpandable;

  const SahyanMatchScoreBreakdownCard({
    super.key,
    required this.matchDetails,
    this.isExpandable = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = matchDetails.score;
    final metrics = matchDetails.metrics;
    final factors = matchDetails.factors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.softForest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score%',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gradeTitle(matchDetails.grade, score),
                      style: AppTypography.bodySmallBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _gradeSubtitle(score),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.md),

          // Metrics breakdown rows
          _buildMetricRow(
            label: 'Route Overlap',
            value: '${metrics.routeOverlapPercentage}%',
            progress: (metrics.routeOverlapPercentage / 100.0).clamp(0.0, 1.0),
            icon: Icons.alt_route_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),

          _buildMetricRow(
            label: 'Pickup Deviation',
            value: '${metrics.pickupDistanceKm.toStringAsFixed(1)} km',
            progress: (1.0 - (metrics.pickupDistanceKm / 5.0)).clamp(0.1, 1.0),
            icon: Icons.fmd_good_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),

          _buildMetricRow(
            label: 'Drop Deviation',
            value: '${metrics.destinationDistanceKm.toStringAsFixed(1)} km',
            progress: (1.0 - (metrics.destinationDistanceKm / 5.0)).clamp(0.1, 1.0),
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),

          _buildMetricRow(
            label: 'Time Difference',
            value: '${metrics.departureDifferenceMinutes.abs()} min',
            progress: (1.0 - (metrics.departureDifferenceMinutes.abs() / 60.0)).clamp(0.1, 1.0),
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),

          _buildMetricRow(
            label: 'Driver Reliability',
            value: '${(factors.driverReliability / 20.0).clamp(1.0, 5.0).toStringAsFixed(1)} / 5',
            progress: (factors.driverReliability / 100.0).clamp(0.2, 1.0),
            icon: Icons.verified_user_rounded,
          ),

          if (matchDetails.reasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: AppSpacing.sm),
            ...matchDetails.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required double progress,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.mutedSage),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.7 ? AppColors.primary : AppColors.mutedBrass,
            ),
          ),
        ),
      ],
    );
  }

  static String _gradeTitle(String grade, int score) {
    if (score >= 90) return 'Exceptional Match';
    if (score >= 80) return 'High Route Compatibility';
    if (score >= 70) return 'Good Route Match';
    return 'Partial Route Match';
  }

  static String _gradeSubtitle(int score) {
    if (score >= 90) return 'Minimal deviation and optimal departure timing.';
    if (score >= 80) return 'Direct route overlap with minor pickup distance.';
    if (score >= 70) return 'Convenient shared route corridor.';
    return 'Acceptable detour along your route corridor.';
  }
}
