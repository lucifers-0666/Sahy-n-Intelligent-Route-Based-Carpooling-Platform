import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Request Confirmation', style: AppTypography.screenTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softBrass,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending Driver Approval',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedBrass,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Route',
                          '$routeOrigin → $routeDest',
                          isBold: true,
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow('Departure', departure),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow('Driver', driverName),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow('Vehicle', vehicleName),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow(
                          'Seats Requested',
                          '${booking.requestedSeats} seat${booking.requestedSeats > 1 ? 's' : ''}',
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow(
                          'Contribution Per Seat',
                          '₹${booking.contributionPerSeat.toStringAsFixed(0)}',
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow(
                          'Total Contribution',
                          '₹${booking.totalContribution.toStringAsFixed(0)}',
                          highlight: true,
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow('Pickup Point', booking.pickup.name),
                        const Divider(height: 16, color: AppColors.border),
                        _buildDetailRow('Drop Point', booking.drop.name),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              PrimaryButton(
                text: 'View My Bookings',
                onPressed: () {
                  context.go('/my-bookings');
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Back to Home',
                onPressed: () {
                  context.go('/home');
                },
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
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: (isBold || highlight)
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: highlight
                  ? AppColors.primaryForest
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
