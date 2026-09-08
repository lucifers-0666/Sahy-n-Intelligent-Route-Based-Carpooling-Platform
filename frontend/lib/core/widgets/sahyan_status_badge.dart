import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/ride_model.dart';

enum SahyanBadgeVariant { success, warning, neutral, danger, info }

/// Standardized Sahyān Status Badge component.
/// Renders consistent status pills across rides, bookings, and verified profiles.
class SahyanStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final BorderSide? border;

  const SahyanStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.border,
  });

  /// Factory constructor for RideStatus
  factory SahyanStatusBadge.fromRideStatus(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return const SahyanStatusBadge(
          label: 'Scheduled',
          backgroundColor: AppColors.softForest,
          textColor: AppColors.primaryForest,
          icon: Icons.calendar_today_outlined,
        );
      case RideStatus.boarding:
        return const SahyanStatusBadge(
          label: 'Boarding',
          backgroundColor: AppColors.softBrass,
          textColor: AppColors.mutedBrass,
          icon: Icons.access_time_rounded,
        );
      case RideStatus.active:
        return const SahyanStatusBadge(
          label: 'Trip in Progress',
          backgroundColor: AppColors.softForest,
          textColor: AppColors.deepForest,
          icon: Icons.navigation_rounded,
        );
      case RideStatus.completed:
        return SahyanStatusBadge(
          label: 'Completed',
          backgroundColor: AppColors.border.withValues(alpha: 0.6),
          textColor: AppColors.textSecondary,
          icon: Icons.check_circle_outline_rounded,
        );
      case RideStatus.cancelled:
        return SahyanStatusBadge(
          label: 'Cancelled',
          backgroundColor: AppColors.mutedRust.withValues(alpha: 0.12),
          textColor: AppColors.mutedRust,
          icon: Icons.cancel_outlined,
        );
    }
  }

  /// Factory constructor for BookingStatus
  factory SahyanStatusBadge.fromBookingStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const SahyanStatusBadge(
          label: 'Pending Approval',
          backgroundColor: AppColors.softBrass,
          textColor: AppColors.mutedBrass,
          icon: Icons.hourglass_top_rounded,
        );
      case BookingStatus.accepted:
        return const SahyanStatusBadge(
          label: 'Confirmed',
          backgroundColor: AppColors.softForest,
          textColor: AppColors.primaryForest,
          icon: Icons.check_circle_rounded,
        );
      case BookingStatus.completed:
        return const SahyanStatusBadge(
          label: 'Completed',
          backgroundColor: AppColors.softForest,
          textColor: AppColors.deepForest,
          icon: Icons.task_alt_rounded,
        );
      case BookingStatus.rejected:
        return SahyanStatusBadge(
          label: 'Declined',
          backgroundColor: AppColors.border.withValues(alpha: 0.6),
          textColor: AppColors.textSecondary,
          icon: Icons.block_rounded,
        );
      case BookingStatus.cancelled:
        return SahyanStatusBadge(
          label: 'Cancelled',
          backgroundColor: AppColors.mutedRust.withValues(alpha: 0.12),
          textColor: AppColors.mutedRust,
          icon: Icons.cancel_outlined,
        );
    }
  }

  /// Factory constructor for Generic Semantic Variants
  factory SahyanStatusBadge.variant({
    required String label,
    required SahyanBadgeVariant variant,
    IconData? icon,
  }) {
    switch (variant) {
      case SahyanBadgeVariant.success:
        return SahyanStatusBadge(
          label: label,
          backgroundColor: AppColors.softForest,
          textColor: AppColors.primaryForest,
          icon: icon,
        );
      case SahyanBadgeVariant.warning:
        return SahyanStatusBadge(
          label: label,
          backgroundColor: AppColors.softBrass,
          textColor: AppColors.mutedBrass,
          icon: icon,
        );
      case SahyanBadgeVariant.danger:
        return SahyanStatusBadge(
          label: label,
          backgroundColor: AppColors.mutedRust.withValues(alpha: 0.12),
          textColor: AppColors.mutedRust,
          icon: icon,
        );
      case SahyanBadgeVariant.info:
        return SahyanStatusBadge(
          label: label,
          backgroundColor: AppColors.surfaceContainerHigh,
          textColor: AppColors.textPrimary,
          icon: icon,
        );
      case SahyanBadgeVariant.neutral:
        return SahyanStatusBadge(
          label: label,
          backgroundColor: AppColors.border.withValues(alpha: 0.6),
          textColor: AppColors.textSecondary,
          icon: icon,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.radiusPill,
        border: border != null ? Border.fromBorderSide(border!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
