import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../../shared/models/ride_model.dart';
import '../widgets/rate_trip_sheet.dart';

class JourneyCompletedScreen extends StatelessWidget {
  final BookingModel? booking;
  final RideModel? ride;

  const JourneyCompletedScreen({super.key, this.booking, this.ride});

  bool get isDriver => ride != null;

  @override
  Widget build(BuildContext context) {
    final String origin;
    final String destination;
    final String personOrVehicleLabel;
    final String personOrVehicleValue;
    final String seatsLabel;
    final String seatsValue;
    final String contributionLabel;
    final double amount;
    final double co2SavedKg;

    if (ride != null) {
      origin = ride!.origin.name.isNotEmpty
          ? ride!.origin.name
          : ride!.origin.city;
      destination = ride!.destination.name.isNotEmpty
          ? ride!.destination.name
          : ride!.destination.city;
      personOrVehicleLabel = 'Vehicle';
      personOrVehicleValue = ride!.vehicle.fullName.isNotEmpty
          ? '${ride!.vehicle.fullName} (${ride!.vehicle.registrationNumber})'
          : ride!.vehicle.registrationNumber;
      final filledSeats = (ride!.totalSeats - ride!.availableSeats).clamp(
        1,
        ride!.totalSeats,
      );
      seatsLabel = 'Seats Shared';
      seatsValue = '$filledSeats of ${ride!.totalSeats} Seats';
      contributionLabel = 'Escrow Earnings';
      amount = filledSeats * ride!.contributionPerSeat;
      co2SavedKg = filledSeats * 3.2;
    } else {
      origin = booking?.pickup.name.isNotEmpty == true
          ? booking!.pickup.name
          : (booking?.ride?.origin.name ?? 'Ahmedabad');
      destination = booking?.drop.name.isNotEmpty == true
          ? booking!.drop.name
          : (booking?.ride?.destination.name ?? 'Vadodara');
      personOrVehicleLabel = 'Driver';
      personOrVehicleValue = booking?.ride?.driverName ?? 'Karan Patel';
      final seats = booking?.requestedSeats ?? 1;
      seatsLabel = 'Seats Reserved';
      seatsValue = '$seats Seat${seats > 1 ? 's' : ''}';
      contributionLabel = 'Shared Contribution';
      amount = booking?.totalContribution ?? 250.0;
      co2SavedKg = seats * 3.2;
    }

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
                    color: AppColors.primaryForest.withValues(alpha: 0.25),
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
                isDriver
                    ? 'All passengers have safely completed their journey.'
                    : 'Thank you for traveling responsibly with Sahyān.',
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
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '$origin → $destination',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          personOrVehicleLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            personOrVehicleValue,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          seatsLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            seatsValue,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          contributionLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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
                            'Saved ~${co2SavedKg.toStringAsFixed(1)} kg CO2 emissions by carpooling.',
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
              if (isDriver) ...[
                SahyanButton(
                  text: 'View Driver Rides',
                  icon: Icons.list_alt_rounded,
                  variant: SahyanButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: () => context.go('/driver/rides'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ] else ...[
                SahyanButton(
                  text: 'Rate & Review Driver',
                  icon: Icons.star_outline_rounded,
                  variant: SahyanButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: () => RateTripSheet.show(
                    context,
                    booking: booking,
                    driverName: personOrVehicleValue,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
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
