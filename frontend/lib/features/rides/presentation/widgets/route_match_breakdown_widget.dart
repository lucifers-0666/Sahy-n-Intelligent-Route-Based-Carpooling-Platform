import 'package:flutter/material.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';

class RouteMatchBreakdownWidget extends StatelessWidget {
  final RouteMatchDetails match;
  final bool isCompact;

  const RouteMatchBreakdownWidget({
    super.key,
    required this.match,
    this.isCompact = false,
  });

  static void showModal(BuildContext context, RouteMatchDetails match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (sheetContext, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route Match Analysis',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RouteMatchBreakdownWidget(match: match),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Done',
                          style: AppTypography.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.primaryForest;
    if (score >= 80) return const Color(0xFF337357);
    if (score >= 70) return const Color(0xFF5E8C70);
    if (score >= 60) return AppColors.mutedBrass;
    return AppColors.mutedRust;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(match.score);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score and Grade Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softForest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${match.score}%',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match.score}% Match',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepForest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          match.grade,
                          style: AppTypography.caption.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Explainable reasons list
          if (match.reasons.isNotEmpty) ...[
            Text(
              'Why this ride matches you:',
              style: AppTypography.fieldLabel.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepForest,
              ),
            ),
            const SizedBox(height: 10),
            ...match.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primaryForest,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
          ],

          // Factor breakdown list
          Text(
            'Scoring Factor Breakdown',
            style: AppTypography.fieldLabel.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.deepForest,
            ),
          ),
          const SizedBox(height: 12),

          _buildFactorRow(
            label: 'Route Overlap',
            weightDesc: '40% weight',
            score: match.factors.routeOverlap,
            metricText: '${match.metrics.routeOverlapPercentage}% route',
            icon: Icons.alt_route_rounded,
          ),
          const SizedBox(height: 10),
          _buildFactorRow(
            label: 'Pickup Deviation',
            weightDesc: '20% weight',
            score: match.factors.pickupDeviation,
            metricText: '${match.metrics.pickupDistanceKm} km',
            icon: Icons.my_location_rounded,
          ),
          const SizedBox(height: 10),
          _buildFactorRow(
            label: 'Destination Deviation',
            weightDesc: '15% weight',
            score: match.factors.destinationDeviation,
            metricText: '${match.metrics.destinationDistanceKm} km',
            icon: Icons.pin_drop_outlined,
          ),
          const SizedBox(height: 10),
          _buildFactorRow(
            label: 'Time Compatibility',
            weightDesc: '10% weight',
            score: match.factors.timeCompatibility,
            metricText: '${match.metrics.departureDifferenceMinutes} min diff',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 10),
          _buildFactorRow(
            label: 'Driver Reliability',
            weightDesc: '10% weight',
            score: match.factors.driverReliability,
            metricText: '${match.factors.driverReliability}%',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 10),
          _buildFactorRow(
            label: 'Seat Availability',
            weightDesc: '5% weight',
            score: match.factors.seatAvailability,
            metricText: '${match.factors.seatAvailability}%',
            icon: Icons.event_seat_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow({
    required String label,
    required String weightDesc,
    required int score,
    required String metricText,
    required IconData icon,
  }) {
    final factorColor = _getScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.mutedSage),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              metricText,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score%',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: factorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.warmBackground,
            valueColor: AlwaysStoppedAnimation<Color>(factorColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
