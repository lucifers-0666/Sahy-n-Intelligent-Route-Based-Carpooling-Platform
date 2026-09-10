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
      appBar: const SahyanAppBar(title: 'Select Vehicle Seats'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Info Card with VehicleIcon
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.vehicle.fullName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride.vehicle.type.displayName} \u2022 Open: ${ride.availableSeats} of ${ride.totalSeats} seats',
                          style: AppTypography.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Interactive Seat Selector
            SeatSelector(
              totalSeats: ride.totalSeats,
              availableSeats: ride.availableSeats,
              selectedSeats: selectedSeats,
              onSeatsChanged: (newSeats) {
                ref.read(selectedSeatsProvider.notifier).state = newSeats;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Legend
            SahyanCard(
              padding: AppSpacing.paddingCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    AppColors.warmBackground,
                    AppColors.border,
                    'Available',
                  ),
                  _buildLegendItem(
                    AppColors.softForest,
                    AppColors.primaryForest,
                    'Selected',
                  ),
                  _buildLegendItem(
                    AppColors.border.withValues(alpha: 0.4),
                    AppColors.border,
                    'Occupied',
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
