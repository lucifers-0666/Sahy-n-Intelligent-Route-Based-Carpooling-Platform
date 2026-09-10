import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../../bookings/domain/booking_model.dart';

class JourneyCompletedScreen extends StatelessWidget {
  final BookingModel? booking;

  const JourneyCompletedScreen({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    final origin = booking?.pickup.name.isNotEmpty == true
        ? booking!.pickup.name
        : (booking?.ride?.origin.name ?? 'Ahmedabad');
    final destination = booking?.drop.name.isNotEmpty == true
        ? booking!.drop.name
        : (booking?.ride?.destination.name ?? 'Vadodara');
    final driverName = booking?.ride?.driverName ?? 'Karan Patel';
    final amount = booking?.totalContribution ?? 250.0;
    final seats = booking?.requestedSeats ?? 1;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Journey Completed',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Success Icon Circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.softForest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryForest.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primaryForest,
                  size: 40,
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Text(
                'Arrived Safely',
                style: AppTypography.screenTitle.copyWith(
                  color: AppColors.deepForest,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thank you for traveling responsibly with Sahyān.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Summary Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route Traveled',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$origin → $destination',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(color: AppColors.border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Driver',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          driverName,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(color: AppColors.border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seats Reserved',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$seats Seat${seats > 1 ? 's' : ''}',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(color: AppColors.border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shared Contribution',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 18,
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Green Impact Badge
              SahyanCard(
                backgroundColor: AppColors.softForest.withValues(alpha: 0.6),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.primaryForest,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eco Impact',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Saved ~3.2 kg CO2 emissions by carpooling.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.deepForest,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Navigation Actions
              SahyanButton(
                text: 'Rate & Review Driver',
                icon: Icons.star_outline_rounded,
                variant: SahyanButtonVariant.outline,
                isFullWidth: true,
                onPressed: () => context.push('/reviews'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SahyanButton(
                text: 'Return to Home',
                icon: Icons.home_outlined,
                isFullWidth: true,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
