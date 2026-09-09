import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
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

  Future<void> _handleAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Accept',
              style: TextStyle(color: AppColors.white),
            ),
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
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Decline',
              style: TextStyle(color: AppColors.white),
            ),
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
          backgroundColor: Colors.red.shade800,
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
      appBar: AppBar(
        title: Text('Request Details', style: AppTypography.screenTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshRequest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & Decision Banner
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(_request.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _request.statusDisplayName,
                              style: AppTypography.caption.copyWith(
                                color: _getStatusTextColor(_request.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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

                const SizedBox(height: 16),

                // Passenger Profile Card
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
                          'Passenger Profile',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.softForest,
                              child: Text(
                                passengerName.isNotEmpty
                                    ? passengerName[0].toUpperCase()
                                    : 'P',
                                style: AppTypography.cardTitle.copyWith(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
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
                ),

                const SizedBox(height: 16),

                // Journey & Route Card
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
                              Icons.trip_origin_rounded,
                              size: 18,
                              color: AppColors.primaryForest,
                            ),
                            const SizedBox(width: 10),
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
                        const SizedBox(height: 14),

                        // Drop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 18,
                              color: AppColors.mutedRust,
                            ),
                            const SizedBox(width: 10),
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
                ),

                const SizedBox(height: 16),

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
                          'Seats & Contribution Details',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

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
                ),

                if (_request.passengerNote.isNotEmpty) ...[
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
                          Text('Passenger Note', style: AppTypography.caption),
                          const SizedBox(height: 6),
                          Text(
                            _request.passengerNote,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                Center(
                  child: Text(
                    'Request placed on $formattedRequestDate',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons for Pending Requests
                if (_request.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.red.shade300),
                          ),
                          onPressed: _isProcessing ? null : _handleReject,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : Text(
                                  'Decline Request',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryForest,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
