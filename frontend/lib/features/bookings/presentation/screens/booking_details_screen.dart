import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/location_model.dart';
import '../../../../shared/models/ride_model.dart';
import '../../domain/booking_model.dart';
import '../bookings_provider.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final BookingModel? initialBooking;

  const BookingDetailsScreen({super.key, this.initialBooking});

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  late BookingModel _booking;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _booking =
        widget.initialBooking ??
        ref.read(selectedBookingProvider) ??
        BookingModel(
          id: '',
          rideId: '',
          passengerId: '',
          requestedSeats: 1,
          contributionPerSeat: 0,
          totalContribution: 0,
          status: BookingStatus.pending,
          pickup: LocationModel.fromCoordinates(
            name: 'Origin',
            latitude: 0,
            longitude: 0,
          ),
          drop: LocationModel.fromCoordinates(
            name: 'Destination',
            latitude: 0,
            longitude: 0,
          ),
          createdAt: DateTime.now(),
        );
  }

  Future<void> _handleCancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Cancel Seat Request?', style: AppTypography.screenTitle),
          content: Text(
            'Are you sure you want to cancel this booking request? Your reserved capacity will be released back to the driver.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Keep Request',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final cancelled = await ref
          .read(bookingsNotifierProvider.notifier)
          .cancelBooking(_booking.id);

      if (!mounted) return;

      setState(() {
        _isCancelling = false;
        _booking = cancelled;
      });

      ref.read(selectedBookingProvider.notifier).state = cancelled;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking request cancelled. Reserved seats released.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Color _getStatusBgColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.softBrass;
      case BookingStatus.accepted:
        return AppColors.softForest;
      case BookingStatus.cancelled:
        return Colors.red.shade50;
      case BookingStatus.rejected:
        return Colors.grey.shade200;
      case BookingStatus.completed:
        return AppColors.softForest;
    }
  }

  Color _getStatusTextColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.mutedBrass;
      case BookingStatus.accepted:
        return AppColors.primaryForest;
      case BookingStatus.cancelled:
        return Colors.red.shade800;
      case BookingStatus.rejected:
        return Colors.grey.shade700;
      case BookingStatus.completed:
        return AppColors.primaryForest;
    }
  }

  Color _getRideStatusBgColor(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return AppColors.softForest;
      case RideStatus.boarding:
        return AppColors.softBrass;
      case RideStatus.active:
        return Colors.blue.shade50;
      case RideStatus.completed:
        return Colors.grey.shade200;
      case RideStatus.cancelled:
        return Colors.red.shade50;
    }
  }

  Color _getRideStatusTextColor(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return AppColors.primaryForest;
      case RideStatus.boarding:
        return AppColors.mutedBrass;
      case RideStatus.active:
        return Colors.blue.shade800;
      case RideStatus.completed:
        return Colors.grey.shade800;
      case RideStatus.cancelled:
        return Colors.red.shade800;
    }
  }

  String _getStatusExplanation(BookingModel booking, RideModel? ride) {
    if (booking.isPending) {
      return 'The driver will review and decide on your seat request shortly.';
    }
    if (booking.isCompleted) {
      return 'Booking and trip completed successfully.';
    }
    if (booking.isAccepted) {
      if (ride != null) {
        if (ride.isBoarding) {
          return 'Boarding in progress! Please be at your pickup point for departure.';
        }
        if (ride.isActive) {
          return 'Trip is currently in progress.';
        }
        if (ride.isCompleted) {
          return 'Trip completed. Thank you for carpooling with Sahyān!';
        }
        if (ride.isCancelled) {
          return 'This ride was cancelled by the driver.';
        }
      }
      return 'The driver has accepted your booking request. Your seats are confirmed.';
    }
    if (booking.isRejected) {
      return 'The driver was unable to accept your request. Reserved seats have been released.';
    }
    if (booking.isCancelled) {
      return 'This booking request was cancelled. Reserved seats were returned.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final formattedRequestDate = dateFormat.format(_booking.createdAt);
    final ride = _booking.ride;
    final formattedDeparture = ride != null
        ? dateFormat.format(ride.dateTime)
        : 'Scheduled Trip';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text('Booking Details', style: AppTypography.screenTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Booking Status',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(_booking.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _booking.statusDisplayName,
                              style: AppTypography.caption.copyWith(
                                color: _getStatusTextColor(_booking.status),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Trip Status Row (if ride is present)
                    if (ride != null) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Trip Status',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _getRideStatusBgColor(ride.status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ride.statusDisplayName,
                                style: AppTypography.caption.copyWith(
                                  color: _getRideStatusTextColor(ride.status),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      _getStatusExplanation(_booking, ride),
                      style: AppTypography.secondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Route & Schedule Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Overview',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Departure time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Departure Time',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  formattedDeparture,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.border),

                      // Pickup
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup Point',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  _booking.pickup.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Drop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drop Point',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  _booking.drop.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Driver & Vehicle Card (if ride populated)
              if (ride != null) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver & Vehicle',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.softForest,
                              child: Text(
                                ride.driverName.isNotEmpty
                                    ? ride.driverName[0].toUpperCase()
                                    : 'D',
                                style: AppTypography.sectionHeader.copyWith(
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ride.driverName,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Rating: ${ride.driverRating.toStringAsFixed(1)} / 5.0',
                                    style: AppTypography.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ride.vehicle.fullName,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Plate: ${ride.vehicle.registrationNumber} • ${ride.vehicle.color}',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Seats & Contribution Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contribution Details',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Seats Requested',
                              style: AppTypography.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_booking.requestedSeats} seat${_booking.requestedSeats > 1 ? 's' : ''}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Contribution Per Seat',
                              style: AppTypography.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${_booking.contributionPerSeat.toStringAsFixed(0)}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Total Contribution',
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${_booking.totalContribution.toStringAsFixed(0)}',
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
              ),

              if (_booking.passengerNote.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Note', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          _booking.passengerNote,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Request timestamp note
              Center(
                child: Text(
                  'Request placed on $formattedRequestDate',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Cancel button for pending bookings
              if (_booking.isPending) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    onPressed: _isCancelling ? null : _handleCancelBooking,
                    child: _isCancelling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : Text(
                            'Cancel Request',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
