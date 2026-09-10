import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../shared/models/ride_model.dart';

class RidePublishedScreen extends StatelessWidget {
  final RideModel? publishedRide;

  const RidePublishedScreen({super.key, this.publishedRide});

  @override
  Widget build(BuildContext context) {
    final ride = publishedRide;
    final originName = ride?.origin.name ?? 'Ahmedabad Highway Junction';
    final destName = ride?.destination.name ?? 'Rajkot Central Toll';
    final vehicle = ride?.vehicle;
    final dateFormat = DateFormat('EEE, d MMM yyyy · h:mm a');
    final formattedDate = ride != null
        ? dateFormat.format(ride.dateTime)
        : dateFormat.format(DateTime.now().add(const Duration(hours: 3)));
    final seats = ride?.availableSeats ?? 3;
    final price = ride?.contributionPerSeat ?? 350;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Ride Published',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Celebratory Ripple Indicator
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.softForest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryForest,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Ride Published Successfully!',
                style: AppTypography.screenTitle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Your vacant seats are now discoverable by verified co-travelers on the express corridor.',
                style: AppTypography.secondary,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Published Journey Details Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'CORRIDOR SCHEDULE',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(
                            'Active',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Origin & Destination
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primaryForest,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Origin', style: AppTypography.caption),
                              Text(
                                originName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Divider(color: AppColors.border),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.mutedBrass,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Destination', style: AppTypography.caption),
                              Text(
                                destName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.border, height: 24),

                    // Departure Time
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.primaryForest,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.border, height: 24),

                    // Vehicle & Seats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Vehicle',
                                style: AppTypography.caption,
                              ),
                              Text(
                                vehicle?.fullName ?? 'Registered Vehicle',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Available Seats',
                              style: AppTypography.caption,
                            ),
                            Text(
                              '$seats Seat${seats > 1 ? 's' : ''}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: AppColors.warmBackground,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Passenger Contribution',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '₹${price.toStringAsFixed(0)} / seat',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryForest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Guidance Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.softForest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.primaryForest.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          color: AppColors.primaryForest,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'What happens next?',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepForest,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '• You will receive notifications when verified members request seats.\n• Review profiles and passenger ratings before accepting.\n• On departure day, verify passenger boarding PINs before starting.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.deepForest,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              SahyanButton(
                text: 'View in My Offered Rides',
                icon: Icons.directions_car_rounded,
                isFullWidth: true,
                onPressed: () => context.go('/driver/rides'),
              ),

              const SizedBox(height: AppSpacing.sm),

              SahyanButton(
                text: 'Return to Home',
                variant: SahyanButtonVariant.outline,
                isFullWidth: true,
                onPressed: () => context.go('/home'),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
