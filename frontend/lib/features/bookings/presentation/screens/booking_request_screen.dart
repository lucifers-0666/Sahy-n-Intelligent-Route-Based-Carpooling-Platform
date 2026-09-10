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
import '../../domain/booking_model.dart';
import '../bookings_provider.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  final BookingModel? initialBooking;

  const BookingRequestScreen({super.key, this.initialBooking});

  @override
  ConsumerState<BookingRequestScreen> createState() =>
      _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  late BookingModel _booking;

  @override
  void initState() {
    super.initState();
    _booking =
        widget.initialBooking ??
        ref.read(selectedBookingProvider) ??
        BookingModel(
          id: 'REQ-DEMO-01',
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatus();
    });
  }

  Future<void> _refreshStatus() async {
    if (_booking.id.isEmpty) return;
    try {
      final fresh = await ref
          .read(bookingsNotifierProvider.notifier)
          .fetchBookingById(_booking.id);
      if (mounted) {
        setState(() => _booking = fresh);
        ref.read(selectedBookingProvider.notifier).state = fresh;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ride = _booking.ride;
    final driverName = ride?.driverName ?? 'Driver Host';
    final vehicle = ride?.vehicle;
    final formattedTime = DateFormat(
      'd MMM, h:mm a',
    ).format(_booking.createdAt);
    final bookingRefCode = _booking.id.isNotEmpty
        ? 'SY-${_booking.id.substring(0, _booking.id.length.clamp(0, 8)).toUpperCase()}'
        : 'SY-PENDING';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Booking Request',
        showBackButton: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          color: AppColors.primaryForest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerMargin,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Hero Card
                SahyanCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Pulsing Status Circle
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _booking.isAccepted
                              ? AppColors.softForest
                              : (_booking.isPending
                                    ? AppColors.softForest.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.warmBackground),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _booking.isAccepted
                              ? Icons.check_circle_rounded
                              : (_booking.isPending
                                    ? Icons.timelapse_rounded
                                    : (_booking.isRejected ||
                                          _booking.isCancelled
                                      ? Icons.cancel_outlined
                                      : Icons.directions_car_rounded)),
                          color: _booking.isAccepted
                              ? AppColors.primaryForest
                              : (_booking.isPending
                                    ? AppColors.primaryForest
                                    : AppColors.mutedRust),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SahyanStatusBadge.fromBookingStatus(
                        _booking.status,
                        label: _booking.statusDisplayName,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _booking.isAccepted
                            ? '$driverName accepted your request!'
                            : (_booking.isPending
                                  ? 'Waiting for $driverName to accept'
                                  : (_booking.isCancelled
                                        ? 'Booking Request Cancelled'
                                        : 'Request was declined')),
                        style: AppTypography.screenTitle.copyWith(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _booking.isAccepted
                            ? 'Boarding PIN is ready. Arrive at pickup 10 minutes prior to departure.'
                            : (_booking.isPending
                                  ? 'Request submitted on $formattedTime. Drivers typically respond within 15 minutes.'
                                  : (_booking.isCancelled
                                        ? 'You cancelled this booking. Seats have been returned.'
                                        : 'The driver could not accommodate this trip. Fair-share holds released.')),
                        style: AppTypography.secondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmBackground,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Booking Reference',
                                style: AppTypography.caption,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              bookingRefCode,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Request Progress Multi-Step Timeline
                SahyanCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Progress',
                        style: AppTypography.cardTitle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildTimelineStep(
                        stepNumber: '1',
                        title: 'Request Sent',
                        subtitle: 'Pickup and drop details delivered to driver',
                        isCompleted: true,
                        isActive: false,
                      ),
                      _buildTimelineStep(
                        stepNumber: '2',
                        title: 'Driver Reviewing',
                        subtitle:
                            'Verifying route compatibility and detour timing',
                        isCompleted: _booking.isAccepted || _booking.isCompleted,
                        isActive: _booking.isPending,
                      ),
                      _buildTimelineStep(
                        stepNumber: '3',
                        title: 'Confirmation & Boarding PIN',
                        subtitle: 'Passcode generated for secure vehicle check-in',
                        isCompleted: _booking.isCompleted,
                        isActive: _booking.isAccepted,
                      ),
                      _buildTimelineStep(
                        stepNumber: '4',
                        title: 'Journey Active',
                        subtitle: 'In transit along the express corridor',
                        isCompleted: _booking.isCompleted,
                        isActive: ride?.isActive ?? false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Driver & Vehicle Summary
                if (ride != null) ...[
                  SahyanCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver & Vehicle',
                          style: AppTypography.cardTitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            SahyanAvatar(
                              name: driverName,
                              radius: 24,
                              isVerified: ride.isDriverVerified,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  RatingDisplay(rating: ride.driverRating),
                                ],
                              ),
                            ),
                            if (vehicle != null)
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      vehicle.fullName,
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.deepForest,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      vehicle.registrationNumber,
                                      style: AppTypography.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Corridor & Contribution Details
                SahyanCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primaryForest,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickup Point', style: AppTypography.caption),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Divider(color: AppColors.border),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.mutedBrass,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Drop Point', style: AppTypography.caption),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Divider(color: AppColors.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Seats Requested', style: AppTypography.caption),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${_booking.requestedSeats} Seat${_booking.requestedSeats > 1 ? 's' : ''}',
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
                            child: Text('Total Contribution', style: AppTypography.caption),
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
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                if (_booking.isAccepted) ...[
                  SahyanButton(
                    text: 'View Active Journey & Boarding PIN',
                    icon: Icons.directions_car_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      context.push('/active-journey', extra: _booking);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                if (_booking.isPending) ...[
                  SahyanButton(
                    text: 'Cancel Booking Request',
                    variant: SahyanButtonVariant.destructive,
                    icon: Icons.cancel_outlined,
                    isFullWidth: true,
                    onPressed: () {
                      context.push('/cancel-booking', extra: _booking);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                SahyanButton(
                  text: 'Message Driver',
                  variant: SahyanButtonVariant.secondary,
                  icon: Icons.chat_bubble_outline_rounded,
                  isFullWidth: true,
                  onPressed: () => context.push('/messages'),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    final color = isCompleted || isActive
        ? AppColors.primaryForest
        : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primaryForest
                    : (isActive ? AppColors.softForest : AppColors.warmBackground),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive || isCompleted
                      ? AppColors.primaryForest
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : Text(
                        stepNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.primaryForest
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? AppColors.primaryForest : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
