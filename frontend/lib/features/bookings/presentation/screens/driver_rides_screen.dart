import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class DriverRidesScreen extends ConsumerStatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  ConsumerState<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends ConsumerState<DriverRidesScreen> {
  String _selectedFilter = 'all';
  String? _actionLoadingRideId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && !authState.isGuest) {
      await Future.wait([
        ref.read(myRidesProvider.notifier).refresh(),
        ref
            .read(driverRequestsNotifierProvider.notifier)
            .fetchDriverRequests(
              status: _selectedFilter == 'all' ? null : _selectedFilter,
            ),
      ]);
    }
  }

  Color _getStatusBg(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.softBrass;
      case BookingStatus.accepted:
        return AppColors.softForest;
      case BookingStatus.cancelled:
        return AppColors.mutedRust.withValues(alpha: 0.12);
      case BookingStatus.rejected:
        return AppColors.border.withValues(alpha: 0.6);
      case BookingStatus.completed:
        return AppColors.softForest;
    }
  }

  Color _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.mutedBrass;
      case BookingStatus.accepted:
        return AppColors.primaryForest;
      case BookingStatus.cancelled:
        return AppColors.mutedRust;
      case BookingStatus.rejected:
        return AppColors.textSecondary;
      case BookingStatus.completed:
        return AppColors.primaryForest;
    }
  }

  Color _getRideStatusBg(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return AppColors.softForest;
      case RideStatus.boarding:
        return AppColors.softBrass;
      case RideStatus.active:
        return AppColors.softForest;
      case RideStatus.completed:
        return AppColors.border.withValues(alpha: 0.6);
      case RideStatus.cancelled:
        return AppColors.mutedRust.withValues(alpha: 0.12);
    }
  }

  Color _getRideStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return AppColors.primaryForest;
      case RideStatus.boarding:
        return AppColors.mutedBrass;
      case RideStatus.active:
        return AppColors.deepForest;
      case RideStatus.completed:
        return AppColors.textSecondary;
      case RideStatus.cancelled:
        return AppColors.mutedRust;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated || authState.isGuest) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: AppBar(
          title: Text('Driver Ride Requests', style: AppTypography.screenTitle),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 54,
                  color: AppColors.mutedSage,
                ),
                const SizedBox(height: 16),
                Text(
                  'Authentication Required',
                  style: AppTypography.sectionHeader,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to view and manage passenger booking requests for your offered rides.',
                  style: AppTypography.secondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => context.push('/login'),
                  child: const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final requestsAsync = ref.watch(driverRequestsNotifierProvider);
    final myRidesAsync = ref.watch(myRidesProvider);
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text(
          'Offered Rides & Requests',
          style: AppTypography.screenTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter bar
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Requests', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending Approval', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Accepted', 'accepted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content list
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryForest,
                onRefresh: _refreshData,
                child: requestsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryForest,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load requests',
                            style: AppTypography.sectionHeader,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString().replaceAll('Exception: ', ''),
                            style: AppTypography.secondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _refreshData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (requests) {
                    final filteredRequests = requests.where((r) {
                      if (_selectedFilter == 'pending') {
                        return r.status == BookingStatus.pending;
                      }
                      if (_selectedFilter == 'accepted') {
                        return r.status == BookingStatus.accepted;
                      }
                      if (_selectedFilter == 'rejected') {
                        return r.status == BookingStatus.rejected;
                      }
                      return true;
                    }).toList();

                    final pendingCount = requests
                        .where((r) => r.status == BookingStatus.pending)
                        .length;

                    return ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      children: [
                        // Summary Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: pendingCount > 0
                                      ? AppColors.softBrass
                                      : AppColors.softForest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  pendingCount > 0
                                      ? Icons.hourglass_top_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 24,
                                  color: pendingCount > 0
                                      ? AppColors.mutedBrass
                                      : AppColors.primaryForest,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pendingCount == 1
                                          ? '1 Pending Request'
                                          : '$pendingCount Pending Requests',
                                      style: AppTypography.cardTitle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pendingCount > 0
                                          ? 'Review and respond to passenger seat requests'
                                          : 'All passenger requests are up to date',
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Active Rides Overview
                        myRidesAsync.when(
                          data: (rides) {
                            if (rides.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Offered Rides',
                                  style: AppTypography.sectionHeader.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...rides.map((ride) {
                                  final ridePendingCount = requests
                                      .where(
                                        (r) =>
                                            r.rideId == ride.id &&
                                            r.status == BookingStatus.pending,
                                      )
                                      .length;

                                  return _buildOfferedRideCard(
                                    context,
                                    ride,
                                    ridePendingCount,
                                    dateFormat,
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),

                        // Section Title for Requests
                        Text(
                          'Passenger Requests (${filteredRequests.length})',
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (filteredRequests.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 36,
                              horizontal: 20,
                            ),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inbox_outlined,
                                  size: 44,
                                  color: AppColors.mutedSage,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Booking Requests Found',
                                  style: AppTypography.cardTitle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedFilter == 'pending'
                                      ? 'You have no pending booking requests right now.'
                                      : 'No passenger booking requests match this filter.',
                                  style: AppTypography.secondary,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...filteredRequests.map(
                            (req) =>
                                _buildRequestCard(context, req, dateFormat),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    BookingModel request,
    DateFormat dateFormat,
  ) {
    final passengerName = request.passenger?.name ?? 'Passenger';
    final passengerRating = request.passenger?.rating ?? 5.0;
    final ride = request.ride;
    final originCity = ride?.origin.city ?? request.pickup.name;
    final destCity = ride?.destination.city ?? request.drop.name;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openRequestDetails(context, request),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Passenger Info & Status Badge
              LayoutBuilder(
                builder: (context, cardConstraints) {
                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: cardConstraints.maxWidth > 60
                              ? cardConstraints.maxWidth
                              : double.infinity,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.softForest,
                              child: Text(
                                passengerName.isNotEmpty
                                    ? passengerName[0].toUpperCase()
                                    : 'P',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passengerName,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  RatingDisplay(rating: passengerRating),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBg(request.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.statusDisplayName,
                          style: AppTypography.caption.copyWith(
                            color: _getStatusText(request.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 20, color: AppColors.border),

              // Route & Seats Row
              Text(
                '$originCity → $destCity',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.airline_seat_recline_normal_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${request.requestedSeats} seat${request.requestedSeats > 1 ? 's' : ''}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.currency_rupee_rounded,
                        size: 14,
                        color: AppColors.primaryForest,
                      ),
                      Text(
                        '₹${request.totalContribution.toStringAsFixed(0)} total',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ],
                  ),
                  if (ride != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateFormat.format(ride.dateTime),
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              if (request.passengerNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: "${request.passengerNote}"',
                  style: AppTypography.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons row
              if (request.isPending)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 340) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  onPressed: () => _confirmReject(request),
                                  child: Text(
                                    'Reject',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryForest,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _confirmAccept(request),
                                  child: Text(
                                    'Accept',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            onPressed: () =>
                                _openRequestDetails(context, request),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: AppColors.primaryForest,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'View Full Details',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryForest,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            onPressed: () => _confirmReject(request),
                            child: Text(
                              'Reject',
                              style: AppTypography.caption.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _confirmAccept(request),
                            child: Text(
                              'Accept',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.mutedSage,
                          ),
                          onPressed: () =>
                              _openRequestDetails(context, request),
                          tooltip: 'View Details',
                        ),
                      ],
                    );
                  },
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.primaryForest,
                    ),
                    label: Text(
                      'View Details',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _openRequestDetails(context, request),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRequestDetails(BuildContext context, BookingModel request) {
    ref.read(selectedDriverRequestProvider.notifier).state = request;
    context.push('/driver/request-details', extra: request);
  }

  Future<void> _confirmAccept(BookingModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Accept Booking Request?', style: AppTypography.cardTitle),
        content: Text(
          'Accepting will book ${request.requestedSeats} seat(s) for ${request.passenger?.name ?? 'the passenger'}.',
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
              'Accept Request',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(driverRequestsNotifierProvider.notifier)
            .acceptRequest(request.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request accepted successfully.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        ref.read(myRidesProvider.notifier).refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _confirmReject(BookingModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Decline Booking Request?', style: AppTypography.cardTitle),
        content: Text(
          'Declining will release the ${request.requestedSeats} reserved seat(s) back to available capacity.',
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

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(driverRequestsNotifierProvider.notifier)
            .rejectRequest(request.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request declined. Seats released.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        ref.read(myRidesProvider.notifier).refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: AppTypography.caption.copyWith(
        color: isSelected ? AppColors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: AppColors.primaryForest,
      backgroundColor: AppColors.warmBackground,
      side: BorderSide(
        color: isSelected ? AppColors.primaryForest : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
          ref
              .read(driverRequestsNotifierProvider.notifier)
              .fetchDriverRequests(status: value == 'all' ? null : value);
        }
      },
    );
  }

  Widget _buildOfferedRideCard(
    BuildContext context,
    RideModel ride,
    int ridePendingCount,
    DateFormat dateFormat,
  ) {
    final isActionLoading = _actionLoadingRideId == ride.id;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Origin -> Dest + Status Badges
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 80
                            ? constraints.maxWidth - 20
                            : double.infinity,
                      ),
                      child: Text(
                        '${ride.origin.city} → ${ride.destination.city}',
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRideStatusBg(ride.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ride.statusDisplayName,
                            style: AppTypography.caption.copyWith(
                              color: _getRideStatusText(ride.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (ridePendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softBrass,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$ridePendingCount pending',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.mutedBrass,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // Metadata: date, available seats
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dateFormat.format(ride.dateTime),
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${ride.availableSeats} of ${ride.totalSeats} seats available',
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Action Buttons / Status Indicator
            if (isActionLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryForest,
                    ),
                  ),
                ),
              )
            else
              _buildRideActions(context, ride),
          ],
        ),
      ),
    );
  }

  Widget _buildRideActions(BuildContext context, RideModel ride) {
    if (ride.isScheduled) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          final cancelBtn = OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: AppColors.mutedRust.withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _confirmCancelRide(ride),
            child: Text(
              'Cancel Ride',
              style: AppTypography.caption.copyWith(
                color: AppColors.mutedRust,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          final boardingBtn = ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.directions_walk_rounded, size: 16),
            label: Text(
              'Start Boarding',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _confirmStartBoarding(ride),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [boardingBtn, const SizedBox(height: 6), cancelBtn],
            );
          }

          return Row(
            children: [
              Expanded(child: cancelBtn),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: boardingBtn),
            ],
          );
        },
      );
    }

    if (ride.isBoarding) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          final cancelBtn = OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: AppColors.mutedRust.withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _confirmCancelRide(ride),
            child: Text(
              'Cancel Ride',
              style: AppTypography.caption.copyWith(
                color: AppColors.mutedRust,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          final startTripBtn = ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: Text(
              'Start Trip',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _confirmStartTrip(ride),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [startTripBtn, const SizedBox(height: 6), cancelBtn],
            );
          }

          return Row(
            children: [
              Expanded(child: cancelBtn),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: startTripBtn),
            ],
          );
        },
      );
    }

    if (ride.isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryForest,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: Text(
            'Complete Trip',
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => _confirmCompleteTrip(ride),
        ),
      );
    }

    if (ride.isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.primaryForest,
          ),
          const SizedBox(width: 6),
          Text(
            'Trip completed successfully',
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryForest,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Ride is cancelled
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cancel_outlined, size: 16, color: AppColors.mutedRust),
        const SizedBox(width: 6),
        Text(
          'Ride has been cancelled',
          style: AppTypography.caption.copyWith(
            color: AppColors.mutedRust,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmStartBoarding(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start Boarding?', style: AppTypography.cardTitle),
        content: Text(
          'Passengers will be notified to proceed to their pickup locations for departure.',
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
              'Start Boarding',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _actionLoadingRideId = ride.id);
      try {
        await ref.read(myRidesProvider.notifier).startBoarding(ride.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boarding commenced successfully.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        ref.read(driverRequestsNotifierProvider.notifier).fetchDriverRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _actionLoadingRideId = null);
        }
      }
    }
  }

  Future<void> _confirmStartTrip(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start Trip?', style: AppTypography.cardTitle),
        content: Text(
          'This will transition the ride to active in progress.',
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
              'Start Trip',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _actionLoadingRideId = ride.id);
      try {
        await ref.read(myRidesProvider.notifier).startTrip(ride.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        ref.read(driverRequestsNotifierProvider.notifier).fetchDriverRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _actionLoadingRideId = null);
        }
      }
    }
  }

  Future<void> _confirmCompleteTrip(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete Trip?', style: AppTypography.cardTitle),
        content: Text(
          'This will complete the ride and transition all accepted passenger bookings to completed.',
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
              'Complete Trip',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _actionLoadingRideId = ride.id);
      try {
        await ref.read(myRidesProvider.notifier).completeTrip(ride.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip completed! All accepted bookings finalized.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        ref.read(driverRequestsNotifierProvider.notifier).fetchDriverRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _actionLoadingRideId = null);
        }
      }
    }
  }

  Future<void> _confirmCancelRide(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Ride?', style: AppTypography.cardTitle),
        content: Text(
          'Are you sure you want to cancel this ride? All pending and accepted booking requests will be cancelled, and reserved seats returned.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedRust,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cancel Ride',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _actionLoadingRideId = ride.id);
      try {
        await ref.read(myRidesProvider.notifier).cancelRide(ride.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled. Bookings updated.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        ref.read(driverRequestsNotifierProvider.notifier).fetchDriverRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.mutedRust,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _actionLoadingRideId = null);
        }
      }
    }
  }
}
