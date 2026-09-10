import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsNotifierProvider);
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('My Bookings', style: AppTypography.screenTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryForest,
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text(
              'Driver Trips',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            onPressed: () => context.push('/driver/rides'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Selector Bar
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
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Pending Approval', 'pending'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Cancelled', 'cancelled'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Accepted', 'accepted'),
                    const SizedBox(width: AppSpacing.sm),
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
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: SahyanErrorState(
                        message: error.toString().replaceAll('Exception: ', ''),
                        onRetry: () => ref
                            .read(bookingsNotifierProvider.notifier)
                            .fetchMyBookings(
                              status: _selectedFilter == 'all'
                                  ? null
                                  : _selectedFilter,
                            ),
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
                      final emptyTitle = _selectedFilter == 'pending'
                          ? 'No pending booking requests'
                          : _selectedFilter == 'cancelled'
                          ? 'No cancelled bookings'
                          : 'No ride bookings yet';
                      final emptySubtitle = _selectedFilter == 'pending'
                          ? 'Pending driver confirmations will be listed here.'
                          : _selectedFilter == 'cancelled'
                          ? 'Cancelled ride bookings will be listed here.'
                          : 'Find and request seats on planned rides to travel together.';

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: SahyanEmptyState(
                              icon: Icons.confirmation_number_outlined,
                              title: emptyTitle,
                              description: emptySubtitle,
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SahyanCard(
                            onTap: () {
                              ref.read(selectedBookingProvider.notifier).state =
                                  booking;
                              context.push('/booking-details', extra: booking);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Status badges + Total contribution
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        SahyanStatusBadge.fromBookingStatus(
                                          booking.status,
                                          label: booking.statusDisplayName,
                                        ),
                                        if (ride != null)
                                          SahyanStatusBadge.fromRideStatus(
                                            ride.status,
                                            label:
                                                'Trip: ${ride.statusDisplayName}',
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '₹${booking.totalContribution.toStringAsFixed(0)}',
                                      style: AppTypography.cardTitle.copyWith(
                                        color: AppColors.primaryForest,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),

                                // Route
                                Text(
                                  '$originName → $destinationName',
                                  style: AppTypography.cardTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),

                                // Departure
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        departureText,
                                        style: AppTypography.secondary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),

                                // Driver and seats
                                Row(
                                  children: [
                                    if (ride != null) ...[
                                      const Icon(
                                        Icons.person_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: Text(
                                          ride.driverName,
                                          style: AppTypography.secondary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                    ],
                                    const Icon(
                                      Icons.event_seat_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '${booking.requestedSeats} seat${booking.requestedSeats > 1 ? 's' : ''}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: AppColors.primaryForest,
      backgroundColor: AppColors.white,
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
              .read(bookingsNotifierProvider.notifier)
              .fetchMyBookings(status: value == 'all' ? null : value);
        }
      },
    );
  }
}
