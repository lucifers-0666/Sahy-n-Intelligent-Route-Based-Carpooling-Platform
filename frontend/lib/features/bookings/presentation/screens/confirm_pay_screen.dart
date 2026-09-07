import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/auth_gate_dialog.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../rides/presentation/rides_provider.dart';
import '../bookings_provider.dart';

class ConfirmPayScreen extends ConsumerStatefulWidget {
  const ConfirmPayScreen({super.key});

  @override
  ConsumerState<ConfirmPayScreen> createState() => _ConfirmPayScreenState();
}

class _ConfirmPayScreenState extends ConsumerState<ConfirmPayScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  void _handleConfirmBooking() async {
    final authState = ref.read(authProvider);

    // Strictly enforce real authentication: no fake synthetic user fallbacks
    if (!authState.isAuthenticated || authState.user == null) {
      AuthGateDialog.show(
        context,
        title: 'Sign In to Request Seat',
        message:
            'To reserve seats and communicate with verified drivers, please sign in or register.',
        intendedRoute: '/confirm-pay',
      );
      return;
    }

    final ride = ref.read(selectedRideProvider);
    final selectedSeats = ref.read(selectedSeatsProvider);

    if (ride == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Authoritative booking creation via live API
      final booking = await ref
          .read(bookingsNotifierProvider.notifier)
          .createBookingRequest(
            rideId: ride.id,
            requestedSeats: selectedSeats.length,
            pickup: ride.origin,
            drop: ride.destination,
          );

      ref.read(selectedBookingProvider.notifier).state = booking;
      ref.read(activeBookingProvider.notifier).state = booking;

      if (!mounted) return;

      setState(() => _isProcessing = false);

      context.go('/booking-confirmation');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage ?? 'Failed to submit seat request',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(selectedRideProvider);
    final selectedSeats = ref.watch(selectedSeatsProvider);

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No ride selected')),
      );
    }

    final totalContribution = ride.contributionPerSeat * selectedSeats.length;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Booking Request Summary',
          style: AppTypography.sectionHeader,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journey Overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Journey Details', style: AppTypography.sectionHeader),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car_filled,
                          color: AppColors.primaryForest,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${ride.origin.city} → ${ride.destination.city}',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Driver: ${ride.driverName} (${ride.vehicle.fullName})',
                      style: AppTypography.secondary,
                    ),
                    Text(
                      'Seats Requested: ${selectedSeats.length} (${selectedSeats.join(', ')})',
                      style: AppTypography.secondary,
                    ),
                    Text(
                      'Departure: ${ride.departureTime}',
                      style: AppTypography.secondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contribution Breakdown Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contribution Details',
                      style: AppTypography.sectionHeader,
                    ),
                    const SizedBox(height: 16),
                    _buildContributionRow(
                      'Seat Contribution (${selectedSeats.length} seat${selectedSeats.length > 1 ? 's' : ''})',
                      '₹${totalContribution.toStringAsFixed(0)}',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: AppColors.border),
                    ),
                    _buildContributionRow(
                      'Total Contribution',
                      '₹${totalContribution.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Request Policy Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softForest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryForest.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryForest,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Driver Approval',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryForest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your request will be sent to the driver for approval. Cost-sharing contribution is shared directly for fuel expenses.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: PrimaryButton(
          text: 'Send Request',
          isLoading: _isProcessing,
          onPressed: _handleConfirmBooking,
        ),
      ),
    );
  }

  Widget _buildContributionRow(
    String title,
    String amount, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: isTotal
                ? AppTypography.sectionHeader
                : AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: isTotal
              ? AppTypography.screenTitle.copyWith(
                  color: AppColors.primaryForest,
                )
              : AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
