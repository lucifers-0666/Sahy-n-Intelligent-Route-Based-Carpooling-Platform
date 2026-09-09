import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/sahyan_avatar.dart';
import 'package:sahyan/core/widgets/sahyan_card.dart';
import 'package:sahyan/core/widgets/sahyan_status_badge.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';

class DriverRequestDetailsScreen extends ConsumerStatefulWidget {
  final BookingModel? initialRequest;

  const DriverRequestDetailsScreen({super.key, this.initialRequest});

  @override
  ConsumerState<DriverRequestDetailsScreen> createState() =>
      _DriverRequestDetailsScreenState();
}

class _DriverRequestDetailsScreenState
    extends ConsumerState<DriverRequestDetailsScreen> {
  late BookingModel _request;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _request =
        widget.initialRequest ??
        ref.read(selectedDriverRequestProvider) ??
        BookingModel.fromJson(const {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRequest();
    });
  }

  Future<void> _refreshRequest() async {
    if (_request.id.isEmpty) return;
    try {
      final fresh = await ref
          .read(driverRequestsNotifierProvider.notifier)
          .fetchRequestById(_request.id);
      if (mounted) {
        setState(() {
          _request = fresh;
        });
      }
    } catch (_) {
      // Retain current state on error
    }
  }

  Future<void> _handleAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text('Accept Booking Request?', style: AppTypography.cardTitle),
        content: Text(
          'Confirm acceptance for ${_request.requestedSeats} seat(s) by ${_request.passenger?.name ?? 'the passenger'}.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final updated = await ref
          .read(driverRequestsNotifierProvider.notifier)
          .acceptRequest(_request.id);
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _request = updated;
      });
      ref.read(selectedDriverRequestProvider.notifier).state = updated;
      ref.read(myRidesProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request accepted successfully.'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.mutedRust,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text('Decline Booking Request?', style: AppTypography.cardTitle),
        content: Text(
          'Declining will release ${_request.requestedSeats} reserved seat(s) back to your ride capacity.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedRust,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final updated = await ref
          .read(driverRequestsNotifierProvider.notifier)
          .rejectRequest(_request.id);
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _request = updated;
      });
      ref.read(selectedDriverRequestProvider.notifier).state = updated;
      ref.read(myRidesProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request declined. Reserved seats released.'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
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
    final passenger = _request.passenger;
    final passengerName = passenger?.name ?? 'Passenger';
    final passengerRating = passenger?.rating ?? 5.0;
    final ride = _request.ride;

    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final formattedDeparture = ride != null
        ? dateFormat.format(ride.dateTime)
        : 'Scheduled Departure';
    final formattedRequestDate = dateFormat.format(_request.createdAt);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Request Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: _refreshRequest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & Decision Banner
                SahyanCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Request Status',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SahyanStatusBadge.fromBookingStatus(
                            _request.status,
                            label: _request.statusDisplayName,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_request.isPending)
                        Text(
                          'Review this passenger request and make your decision below.',
                          style: AppTypography.secondary,
                        )
                      else if (_request.isAccepted)
                        Text(
                          'You accepted this booking. Seats are booked for this passenger.',
                          style: AppTypography.secondary,
                        )
                      else if (_request.isRejected)
                        Text(
                          'You declined this booking request. Reserved seats have been released.',
                          style: AppTypography.secondary,
                        )
                      else if (_request.isCancelled)
                        Text(
                          'The passenger cancelled this request.',
                          style: AppTypography.secondary,
                        ),
                    ],
                  ),
                ),

                // Passenger Profile Card
                SahyanCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passenger Profile',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          SahyanAvatar(name: passengerName, radius: 24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passengerName,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                RatingDisplay(rating: passengerRating),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Journey & Route Card
                SahyanCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Overview',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Departure time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: AppSpacing.sm),
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
                            Icons.trip_origin_rounded,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requested Pickup',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  _request.pickup.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Drop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 18,
                            color: AppColors.mutedRust,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requested Drop-off',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  _request.drop.name,
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

                // Seats & Contribution Card
                SahyanCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seats & Contribution Details',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Requested Seats',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            '${_request.requestedSeats} seat${_request.requestedSeats > 1 ? 's' : ''}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Contribution per Seat',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            '₹${_request.contributionPerSeat.toStringAsFixed(0)}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.border),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Passenger Contribution',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${_request.totalContribution.toStringAsFixed(0)}',
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

                if (_request.passengerNote.isNotEmpty) ...[
                  SahyanCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Passenger Note', style: AppTypography.caption),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _request.passengerNote,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xs),

                Center(
                  child: Text(
                    'Request placed on $formattedRequestDate',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons for Pending Requests
                if (_request.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            side: const BorderSide(color: AppColors.mutedRust),
                          ),
                          onPressed: _isProcessing ? null : _handleReject,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.mutedRust,
                                  ),
                                )
                              : Text(
                                  'Decline Request',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mutedRust,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryForest,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                          ),
                          onPressed: _isProcessing ? null : _handleAccept,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  'Accept Request',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
