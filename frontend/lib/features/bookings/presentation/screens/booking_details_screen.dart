import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/rating_display.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_avatar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../core/widgets/sahyan_status_badge.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBooking();
    });
  }

  Future<void> _refreshBooking() async {
    if (_booking.id.isEmpty) return;
    try {
      final fresh = await ref
          .read(bookingsNotifierProvider.notifier)
          .fetchBookingById(_booking.id);
      if (mounted) {
        setState(() {
          _booking = fresh;
        });
        ref.read(selectedBookingProvider.notifier).state = fresh;
      }
    } catch (_) {
      // Keep existing data on transient offline error
    }
  }

  Future<void> _handleCancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Cancel Seat Request?',
            style: AppTypography.sectionHeader,
          ),
          content: Text(
            'Are you sure you want to cancel this booking request? Your reserved capacity will be released back to the driver.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Keep Request',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mutedRust,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                elevation: 0,
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
          backgroundColor: AppColors.mutedRust,
        ),
      );
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
      appBar: const SahyanAppBar(
        title: 'Booking Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshBooking,
          color: AppColors.primaryForest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerMargin,
              vertical: AppSpacing.base,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                SahyanCard(
                  padding: AppSpacing.paddingCardLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking Status Row
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Text(
                            'Booking Status',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SahyanStatusBadge.fromBookingStatus(
                            _booking.status,
                            label: _booking.statusDisplayName,
                          ),
                        ],
                      ),

                      // Trip Status Row (if ride is present)
                      if (ride != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text(
                              'Trip Status',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SahyanStatusBadge.fromRideStatus(
                              ride.status,
                              label: ride.statusDisplayName,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _getStatusExplanation(_booking, ride),
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.base),

                // Route & Schedule Card
                SahyanCard(
                  padding: AppSpacing.paddingCardLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Overview',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Departure time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
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
                      const Divider(
                        height: AppSpacing.xl,
                        color: AppColors.border,
                      ),

                      // Pickup
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
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
                      const SizedBox(height: AppSpacing.md),

                      // Drop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.mutedBrass,
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
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

                const SizedBox(height: AppSpacing.base),

                // Driver & Vehicle Card (if ride populated)
                if (ride != null) ...[
                  SahyanCard(
                    padding: AppSpacing.paddingCardLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver & Vehicle',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            SahyanAvatar(
                              name: ride.driverName,
                              radius: 22,
                              isVerified: ride.isDriverVerified,
                            ),
                            const SizedBox(width: AppSpacing.md),
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
                                  const SizedBox(height: 2),
                                  RatingDisplay(rating: ride.driverRating),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: AppSpacing.xl,
                          color: AppColors.border,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 20,
                              color: AppColors.primaryForest,
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
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
                  const SizedBox(height: AppSpacing.base),
                ],

                // Seats & Contribution Card
                SahyanCard(
                  padding: AppSpacing.paddingCardLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contribution Details',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Seats Requested',
                              style: AppTypography.secondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${_booking.requestedSeats} seat${_booking.requestedSeats > 1 ? 's' : ''}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Contribution Per Seat',
                              style: AppTypography.secondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '₹${_booking.contributionPerSeat.toStringAsFixed(0)}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: AppSpacing.lg,
                        color: AppColors.border,
                      ),
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
                          const SizedBox(width: AppSpacing.sm),
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

                if (_booking.passengerNote.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  SahyanCard(
                    padding: AppSpacing.paddingCardLarge,
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
                ],

                const SizedBox(height: AppSpacing.base),

                // Request timestamp note
                Center(
                  child: Text(
                    'Request placed on $formattedRequestDate',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Active journey button for accepted bookings
                if (_booking.isAccepted) ...[
                  SahyanButton(
                    text: 'View Active Journey & Boarding PIN',
                    icon: Icons.directions_car_rounded,
                    onPressed: () {
                      context.push('/active-journey', extra: _booking);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SahyanButton(
                    text: 'Message Driver',
                    icon: Icons.chat_bubble_outline_rounded,
                    variant: SahyanButtonVariant.secondary,
                    onPressed: () => context.push('/messages'),
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],

                // Completed summary for finished bookings
                if (_booking.isCompleted) ...[
                  SahyanButton(
                    text: 'View Journey Summary & Receipt',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      context.push('/journey-completed', extra: _booking);
                    },
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],

                // Cancel button for pending bookings
                if (_booking.isPending) ...[
                  SahyanButton(
                    text: 'Cancel Request',
                    variant: SahyanButtonVariant.destructive,
                    isLoading: _isCancelling,
                    onPressed: _handleCancelBooking,
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
