import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/sahyan_avatar.dart';
import 'package:sahyan/core/widgets/sahyan_button.dart';
import 'package:sahyan/core/widgets/sahyan_card.dart';
import 'package:sahyan/core/widgets/sahyan_status_badge.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated || authState.isGuest) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: const SahyanAppBar(
          title: 'Driver Ride Requests',
          showBackButton: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: SahyanCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.softForest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 32,
                      color: AppColors.primaryForest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Authentication Required',
                    style: AppTypography.screenTitle.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please sign in to view and manage passenger booking requests for your offered rides.',
                    style: AppTypography.secondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SahyanButton(
                    text: 'Log In',
                    variant: SahyanButtonVariant.primary,
                    size: SahyanButtonSize.regular,
                    onPressed: () => context.push('/login'),
                  ),
                ],
              ),
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
      appBar: SahyanAppBar(
        title: 'Offered Rides & Requests',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryForest,
            ),
            tooltip: 'Payout & Earnings',
            onPressed: () => context.push('/driver/payout'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryForest),
            tooltip: 'Offer a Ride',
            onPressed: () => context.go('/offer-ride'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter bar
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Requests', 'all'),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Pending Approval', 'pending'),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Accepted', 'accepted'),
                    const SizedBox(width: AppSpacing.xs),
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
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.mutedRust,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Unable to load requests',
                            style: AppTypography.sectionHeader,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            err.toString().replaceAll('Exception: ', ''),
                            style: AppTypography.secondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SahyanButton(
                            text: 'Retry',
                            variant: SahyanButtonVariant.primary,
                            size: SahyanButtonSize.small,
                            onPressed: _refreshData,
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
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      children: [
                        // Summary Banner
                        SahyanCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
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
                                  size: 22,
                                  color: pendingCount > 0
                                      ? AppColors.mutedBrass
                                      : AppColors.primaryForest,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
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
                                const SizedBox(height: AppSpacing.sm),
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
                                const SizedBox(height: AppSpacing.md),
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
                        const SizedBox(height: AppSpacing.sm),

                        if (filteredRequests.isEmpty)
                          SahyanCard(
                            margin: const EdgeInsets.only(top: AppSpacing.xs),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxl,
                              horizontal: AppSpacing.lg,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: AppColors.softForest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inbox_outlined,
                                    size: 28,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No Booking Requests Found',
                                  style: AppTypography.cardTitle,
                                ),
                                const SizedBox(height: AppSpacing.xs),
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

    return SahyanCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _openRequestDetails(context, request),
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
                      maxWidth: cardConstraints.maxWidth > 80
                          ? cardConstraints.maxWidth - 20
                          : double.infinity,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SahyanAvatar(name: passengerName, radius: 18),
                        const SizedBox(width: AppSpacing.sm),
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
                  SahyanStatusBadge.fromBookingStatus(
                    request.status,
                    label: request.statusDisplayName,
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
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
                                ),
                                side: const BorderSide(
                                  color: AppColors.mutedRust,
                                ),
                              ),
                              onPressed: () => _confirmReject(request),
                              child: Text(
                                'Reject',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedRust,
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
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
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
                        onPressed: () => _openRequestDetails(context, request),
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
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          side: const BorderSide(color: AppColors.mutedRust),
                        ),
                        onPressed: () => _confirmReject(request),
                        child: Text(
                          'Reject',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedRust,
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
                            borderRadius: BorderRadius.circular(AppRadii.sm),
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
                      onPressed: () => _openRequestDetails(context, request),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
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
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept Request'),
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
            backgroundColor: AppColors.mutedRust,
          ),
        );
      }
    }
  }

  Future<void> _confirmReject(BookingModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
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
              backgroundColor: AppColors.mutedRust,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Decline'),
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
            backgroundColor: AppColors.mutedRust,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
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

    return SahyanCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
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
                      SahyanStatusBadge.fromRideStatus(ride.status),
                      if (ridePendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softBrass,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VehicleIcon.illustration(
                    type: ride.vehicle.type,
                    width: 32,
                    height: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${ride.vehicle.fullName} (${ride.vehicle.registrationNumber})',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepForest,
                      ),
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
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 280;
          final hudBtn = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              side: const BorderSide(color: AppColors.primaryForest),
            ),
            icon: const Icon(Icons.navigation_rounded, size: 16, color: AppColors.primaryForest),
            label: Text(
              'Drive HUD',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryForest,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => context.push('/driver/active-ride', extra: ride),
          );

          final completeBtn = ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hudBtn,
                const SizedBox(height: 6),
                completeBtn,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: hudBtn),
              const SizedBox(width: 8),
              Expanded(child: completeBtn),
            ],
          );
        },
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
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
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start Boarding'),
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

  Future<void> _confirmStartTrip(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
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
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start Trip'),
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
        context.push('/driver/active-ride', extra: ride);
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

  Future<void> _confirmCompleteTrip(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
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
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete Trip'),
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

  Future<void> _confirmCancelRide(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
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
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Ride'),
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
