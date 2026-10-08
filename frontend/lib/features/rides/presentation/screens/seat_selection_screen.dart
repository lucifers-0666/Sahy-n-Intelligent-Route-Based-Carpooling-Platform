import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../core/widgets/seat_selector.dart';
import '../../../../core/widgets/vehicles/vehicle_icon.dart';
import '../../../../features/vehicles/domain/vehicle_type.dart';
import '../rides_provider.dart';

class SeatSelectionScreen extends ConsumerWidget {
  const SeatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(selectedRideProvider);
    final selectedSeats = ref.watch(selectedSeatsProvider);

    if (ride == null) {
      return const Scaffold(
        appBar: SahyanAppBar(title: 'Select Vehicle Seats'),
        body: Center(child: Text('No ride selected')),
      );
    }

    final totalAmount = ride.contributionPerSeat * selectedSeats.length;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Select Vehicle Seats',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerMargin,
          vertical: AppSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Corridor Header Pill
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.softForest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
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
                          '${ride.origin.city} \u2192 ${ride.destination.city}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepForest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Departure: ${ride.departureTime} \u2022 Driver: ${ride.driverName}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Vehicle Info Card with VehicleIcon
            SahyanCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 52,
                    padding: const EdgeInsets.all(6),
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
                        Text(
                          ride.vehicle.fullName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride.vehicle.type.displayName} \u2022 Open: ${ride.availableSeats} of ${ride.totalSeats} seats',
                          style: AppTypography.secondary,
                        ),
                        if (ride.vehicle.registrationNumber.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            ride.vehicle.registrationNumber,
                            style: AppTypography.caption.copyWith(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Interactive Seat Selector
            SeatSelector(
              totalSeats: ride.totalSeats,
              availableSeats: ride.availableSeats,
              selectedSeats: selectedSeats,
              onSeatsChanged: (newSeats) {
                ref.read(selectedSeatsProvider.notifier).state = newSeats;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Legend
            SahyanCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    AppColors.white,
                    AppColors.border,
                    'Available',
                  ),
                  _buildLegendItem(
                    AppColors.softForest,
                    AppColors.primaryForest,
                    'Selected',
                  ),
                  _buildLegendItem(
                    AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                    AppColors.border.withValues(alpha: 0.6),
                    'Occupied',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Contribution Summary Bento Card
            SahyanCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contribution Calculation',
                    style: AppTypography.sectionHeader.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPricingRow(
                    'Contribution Per Seat',
                    '\u20B9${ride.contributionPerSeat.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildPricingRow(
                    'Seats Selected',
                    selectedSeats.isNotEmpty
                        ? '${selectedSeats.length} (${selectedSeats.join(', ')})'
                        : '0 seats',
                  ),
                  const Divider(height: AppSpacing.lg, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Contribution',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepForest,
                        ),
                      ),
                      Text(
                        '\u20B9${totalAmount.toStringAsFixed(0)}',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
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
                  Text(
                    'Contribution (${selectedSeats.length} seat${selectedSeats.length > 1 ? 's' : ''})',
                    style: AppTypography.caption,
                  ),
                  Text(
                    '\u20B9${totalAmount.toStringAsFixed(0)}',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppColors.primaryForest,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: PrimaryButton(
                  text: 'Review Request',
                  isDisabled: selectedSeats.isEmpty,
                  onPressed: () {
                    context.push('/confirm-pay');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color bg, Color border, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.secondary),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
