import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/ride_model.dart';
import '../../domain/booking_model.dart';
import '../bookings_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'cancelled'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsNotifierProvider.notifier).fetchMyBookings();
    });
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
    final bookingsAsync = ref.watch(bookingsNotifierProvider);
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('My Bookings', style: AppTypography.screenTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Selector Bar
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
                    _buildFilterChip('Cancelled', 'cancelled'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Accepted', 'accepted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Bookings List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryForest,
                onRefresh: () => ref
                    .read(bookingsNotifierProvider.notifier)
                    .fetchMyBookings(
                      status: _selectedFilter == 'all' ? null : _selectedFilter,
                    ),
                child: bookingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryForest,
                    ),
                  ),
                  error: (error, stack) => Center(
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
                            'Unable to load bookings',
                            style: AppTypography.sectionHeader,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            error.toString().replaceAll('Exception: ', ''),
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
                            onPressed: () => ref
                                .read(bookingsNotifierProvider.notifier)
                                .fetchMyBookings(
                                  status: _selectedFilter == 'all'
                                      ? null
                                      : _selectedFilter,
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (bookings) {
                    final filtered = bookings.where((b) {
                      if (_selectedFilter == 'pending') {
                        return b.status == BookingStatus.pending;
                      }
                      if (_selectedFilter == 'accepted') {
                        return b.status == BookingStatus.accepted;
                      }
                      if (_selectedFilter == 'rejected') {
                        return b.status == BookingStatus.rejected;
                      }
                      if (_selectedFilter == 'cancelled') {
                        return b.status == BookingStatus.cancelled;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 56,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _selectedFilter == 'pending'
                                        ? 'No pending booking requests'
                                        : _selectedFilter == 'cancelled'
                                        ? 'No cancelled bookings'
                                        : 'No ride bookings yet',
                                    style: AppTypography.sectionHeader,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Find and request seats on planned rides to travel together.',
                                    style: AppTypography.secondary,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final booking = filtered[index];
                        final ride = booking.ride;
                        final originName = ride != null
                            ? ride.origin.city
                            : booking.pickup.name;
                        final destinationName = ride != null
                            ? ride.destination.city
                            : booking.drop.name;
                        final departureText = ride != null
                            ? dateFormat.format(ride.dateTime)
                            : dateFormat.format(booking.createdAt);

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              ref.read(selectedBookingProvider.notifier).state =
                                  booking;
                              context.push('/booking-details', extra: booking);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Status badges + Total contribution
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusBg(
                                                booking.status,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              booking.statusDisplayName,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: _getStatusText(
                                                      booking.status,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          if (ride != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getRideStatusBg(
                                                  ride.status,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Trip: ${ride.statusDisplayName}',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: _getRideStatusText(
                                                        ride.status,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '₹${booking.totalContribution.toStringAsFixed(0)}',
                                        style: AppTypography.sectionHeader
                                            .copyWith(
                                              color: AppColors.primaryForest,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Route
                                  Text(
                                    '$originName → $destinationName',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),

                                  // Departure
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          departureText,
                                          style: AppTypography.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Driver and seats
                                  Row(
                                    children: [
                                      if (ride != null) ...[
                                        const Icon(
                                          Icons.person_rounded,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            ride.driverName,
                                            style: AppTypography.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      const Icon(
                                        Icons.event_seat_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${booking.requestedSeats} seat${booking.requestedSeats > 1 ? 's' : ''}',
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
              .read(bookingsNotifierProvider.notifier)
              .fetchMyBookings(status: value == 'all' ? null : value);
        }
      },
    );
  }
}
