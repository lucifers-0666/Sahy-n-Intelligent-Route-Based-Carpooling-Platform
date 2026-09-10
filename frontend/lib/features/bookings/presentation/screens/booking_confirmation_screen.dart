import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../core/widgets/sahyan_status_badge.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/vehicles/vehicle_icon.dart';
import '../bookings_provider.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(activeBookingProvider);
    final ride = booking?.ride ?? booking?.rideDetails;

    final routeOrigin = booking != null
        ? (booking.pickup.name.isNotEmpty
              ? booking.pickup.name
              : ride?.origin.city ?? 'Origin')
        : 'Origin';
    final routeDest = booking != null
        ? (booking.drop.name.isNotEmpty
              ? booking.drop.name
              : ride?.destination.city ?? 'Destination')
        : 'Destination';

    final driverName = ride?.driverName ?? 'the driver';
    final vehicleName = ride?.vehicle.fullName ?? 'Vehicle';
    final departure = ride != null ? ride.departureTime : 'Scheduled Departure';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Request Confirmation',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Success / Pending Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.softForest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 44,
                  color: AppColors.primaryForest,
                ),
              ),
              const SizedBox(height: 20),

              Text('Request Sent', style: AppTypography.screenTitle),
              const SizedBox(height: 10),
              booking != null
                  ? SahyanStatusBadge.fromBookingStatus(
                      booking.status,
                      label: booking.statusDisplayName,
                    )
                  : SahyanStatusBadge.variant(
                      label: 'Pending Approval',
                      variant: SahyanBadgeVariant.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
              const SizedBox(height: 12),
              Text(
                'The driver needs to approve your request. You will be notified once $driverName confirms.',
                style: AppTypography.secondary,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Comprehensive Details Card
              if (booking != null)
                SahyanCard(
                  padding: AppSpacing.paddingCardLarge,
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Route',
                        '$routeOrigin \u2192 $routeDest',
                        isBold: true,
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow('Departure', departure),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow('Driver', driverName),
                      const Divider(height: 16, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text('Vehicle', style: AppTypography.secondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (ride != null) ...[
                                  VehicleIcon.illustration(
                                    type: ride.vehicle.type,
                                    width: 32,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    vehicleName,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow(
                        'Seats Requested',
                        '${booking.requestedSeats} seat${booking.requestedSeats > 1 ? 's' : ''}',
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow(
                        'Contribution Per Seat',
                        '\u20B9${booking.contributionPerSeat.toStringAsFixed(0)}',
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow(
                        'Total Contribution',
                        '\u20B9${booking.totalContribution.toStringAsFixed(0)}',
                        highlight: true,
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow('Pickup Point', booking.pickup.name),
                      const Divider(height: 16, color: AppColors.border),
                      _buildDetailRow('Drop Point', booking.drop.name),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              PrimaryButton(
                text: 'Track Booking Request',
                onPressed: () {
                  context.push('/booking-request', extra: booking);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'View My Bookings',
                onPressed: () {
                  context.go('/my-bookings');
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.go('/home');
                },
                child: Text(
                  'Back to Home',
                  style: AppTypography.button.copyWith(
                    color: AppColors.primaryForest,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTypography.secondary)),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold || highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.primaryForest : AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
