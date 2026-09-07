import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/auth_gate_dialog.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../bookings/presentation/bookings_provider.dart';

class RequestSeatBottomSheet extends ConsumerStatefulWidget {
  final RideModel ride;

  const RequestSeatBottomSheet({super.key, required this.ride});

  static Future<bool?> show(BuildContext context, RideModel ride) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => RequestSeatBottomSheet(ride: ride),
    );
  }

  @override
  ConsumerState<RequestSeatBottomSheet> createState() =>
      _RequestSeatBottomSheetState();
}

class _RequestSeatBottomSheetState
    extends ConsumerState<RequestSeatBottomSheet> {
  int _selectedSeats = 1;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _totalContribution =>
      _selectedSeats * widget.ride.contributionPerSeat;

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      Navigator.of(context).pop(false);
      AuthGateDialog.show(
        context,
        title: 'Sign In to Request Seat',
        message:
            'To reserve seats and communicate with verified drivers, please sign in or register.',
        intendedRoute: '/home',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final booking = await ref
          .read(bookingsNotifierProvider.notifier)
          .createBookingRequest(
            rideId: widget.ride.id,
            requestedSeats: _selectedSeats,
            passengerNote: _noteController.text.trim(),
            pickup: widget.ride.origin,
            drop: widget.ride.destination,
          );

      if (!mounted) return;

      // Close bottom sheet with success
      Navigator.of(context).pop(true);

      // Set as selected booking and navigate to booking details
      ref.read(selectedBookingProvider.notifier).state = booking;

      // Show confirmation dialog/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request Sent. Status: Pending Driver Approval. The driver needs to approve your request.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.primaryForest,
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate to booking details
      context.push('/booking-details', extra: booking);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final formattedDeparture = dateFormat.format(widget.ride.dateTime);
    final maxSeats = widget.ride.availableSeats > 0
        ? widget.ride.availableSeats
        : 1;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Request a Seat',
                style: AppTypography.screenTitle.copyWith(
                  color: AppColors.primaryForest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send a seat reservation request to the driver.',
                style: AppTypography.secondary,
              ),

              const SizedBox(height: 20),

              // Route & Departure Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warmBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route
                    Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          size: 18,
                          color: AppColors.primaryForest,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.ride.origin.city} → ${widget.ride.destination.city}',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Departure
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Departure',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                formattedDeparture,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Available seats note
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.ride.availableSeats} seats currently available',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seat Counter Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seats Requested',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Max $maxSeats available',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.warmBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 20),
                          color: _selectedSeats > 1
                              ? AppColors.primaryForest
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                          onPressed: _selectedSeats > 1
                              ? () => setState(() => _selectedSeats--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_selectedSeats',
                            style: AppTypography.sectionHeader.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          color: _selectedSeats < maxSeats
                              ? AppColors.primaryForest
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                          onPressed: _selectedSeats < maxSeats
                              ? () => setState(() => _selectedSeats++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Contribution Breakdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softForest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Contribution',
                            style: AppTypography.secondary.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${widget.ride.contributionPerSeat.toStringAsFixed(0)} per seat',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total Estimated',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${_totalContribution.toStringAsFixed(0)}',
                          style: AppTypography.sectionHeader.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Passenger Note (Optional)
              Text(
                'Note for Driver (Optional)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g. I will be waiting near the highway bus stand',
                  hintStyle: AppTypography.secondary,
                  filled: true,
                  fillColor: AppColors.warmBackground,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryForest,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.caption.copyWith(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons: Cancel and Send Request
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: _isSubmitting ? 'Sending...' : 'Send Request',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submitRequest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
