import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_avatar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/booking_model.dart';
import '../bookings_provider.dart';

class CancelBookingScreen extends ConsumerStatefulWidget {
  final BookingModel? initialBooking;

  const CancelBookingScreen({super.key, this.initialBooking});

  @override
  ConsumerState<CancelBookingScreen> createState() =>
      _CancelBookingScreenState();
}

class _CancelBookingScreenState extends ConsumerState<CancelBookingScreen> {
  late BookingModel _booking;
  String _selectedReason = 'Change of travel plans';
  final _noteController = TextEditingController();
  bool _isCancelling = false;

  final List<String> _reasons = [
    'Change of travel plans',
    'Found another shared ride',
    'Driver rescheduled departure',
    'Personal emergency',
    'Other reason',
  ];

  @override
  void initState() {
    super.initState();
    _booking =
        widget.initialBooking ??
        ref.read(selectedBookingProvider) ??
        BookingModel(
          id: 'BOOK-DEMO-01',
          rideId: 'RIDE-DEMO',
          passengerId: 'USER-01',
          requestedSeats: 1,
          contributionPerSeat: 350,
          totalContribution: 350,
          status: BookingStatus.pending,
          pickup: LocationModel.fromCoordinates(
            name: 'Ahmedabad Highway Junction',
            latitude: 23.0225,
            longitude: 72.5714,
          ),
          drop: LocationModel.fromCoordinates(
            name: 'Rajkot Central Toll',
            latitude: 22.3039,
            longitude: 70.8022,
          ),
          createdAt: DateTime.now(),
        );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCancel() async {
    setState(() => _isCancelling = true);

    try {
      await ref
          .read(bookingsNotifierProvider.notifier)
          .cancelBooking(_booking.id);

      if (!mounted) return;
      setState(() => _isCancelling = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking cancelled. 100% fair-share contribution refunded.',
          ),
          backgroundColor: AppColors.primaryForest,
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/my-bookings');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.mutedRust,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _booking.ride;
    final driverName = ride?.driverName ?? 'Driver Host';
    final vehicle = ride?.vehicle;
    final dateFormat = DateFormat('EEE, d MMM yyyy · h:mm a');
    final formattedDate = ride != null
        ? dateFormat.format(ride.dateTime)
        : dateFormat.format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Cancel Booking',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reassurance Micro-Banner
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.softForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
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
                            'Change of plans? We understand.',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cancel with zero penalty fees. Your contribution hold is released in real-time.',
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

              const SizedBox(height: AppSpacing.lg),

              // Trip Summary Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Summary',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_booking.pickup.name} to ${_booking.drop.name}',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    Row(
                      children: [
                        SahyanAvatar(name: driverName, radius: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (vehicle != null)
                                Text(
                                  '${vehicle.fullName} • ${vehicle.registrationNumber}',
                                  style: AppTypography.caption,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${_booking.totalContribution.toStringAsFixed(0)}',
                          style: AppTypography.cardTitle.copyWith(
                            color: AppColors.primaryForest,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reason Selector
              Text(
                'Why are you cancelling?',
                style: AppTypography.sectionHeader.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Help us maintain corridor reliability for the Sahyan carpool community.',
                style: AppTypography.secondary,
              ),
              const SizedBox(height: AppSpacing.md),

              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _reasons.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return InkWell(
                      onTap: () => setState(() => _selectedReason = reason),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryForest
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryForest,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                reason,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primaryForest
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Optional Remarks
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Additional notes for the driver (optional)',
                  hintStyle: AppTypography.secondary,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(
                      color: AppColors.primaryForest,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Transparent Refund Breakdown
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
                            'Refund Breakdown',
                            style: AppTypography.cardTitle.copyWith(fontSize: 14),
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
                            '100% Refundable',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Paid Contribution',
                            style: AppTypography.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '₹${_booking.totalContribution.toStringAsFixed(0)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Cancellation Fee',
                            style: AppTypography.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '₹0.00',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryForest,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total Refund',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '₹${_booking.totalContribution.toStringAsFixed(0)}',
                          style: AppTypography.cardTitle.copyWith(
                            color: AppColors.primaryForest,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Credits returned instantly to your original payment method or UPI balance.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Confirm and Cancel Actions
              SahyanButton(
                text: 'Confirm Cancellation',
                variant: SahyanButtonVariant.destructive,
                icon: Icons.cancel_outlined,
                isLoading: _isCancelling,
                isFullWidth: true,
                onPressed: _handleConfirmCancel,
              ),

              const SizedBox(height: AppSpacing.sm),

              SahyanButton(
                text: 'Keep My Booking',
                variant: SahyanButtonVariant.outline,
                isFullWidth: true,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/my-bookings');
                  }
                },
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
