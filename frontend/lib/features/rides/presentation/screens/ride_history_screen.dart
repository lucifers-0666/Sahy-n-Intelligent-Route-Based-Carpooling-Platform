import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../bookings/presentation/bookings_provider.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  String _activeFilter = 'all'; // 'all', 'completed', 'cancelled'

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Ride History',
        subtitle: 'Past completed and cancelled carpools',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip('Completed', 'completed'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Content
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(
                  child: SahyanLoadingState(message: 'Loading ride history...'),
                ),
                error: (err, _) => Center(
                  child: SahyanErrorState(
                    title: 'Failed to load history',
                    message: err.toString(),
                    onRetry: () => ref
                        .read(bookingsNotifierProvider.notifier)
                        .fetchMyBookings(),
                  ),
                ),
                data: (allBookings) {
                  // History typically contains completed or cancelled bookings
                  final historyList = allBookings.where((b) {
                    final isHistoryStatus =
                        b.status == BookingStatus.completed ||
                        b.status == BookingStatus.cancelled ||
                        b.status == BookingStatus.rejected;
                    if (!isHistoryStatus && _activeFilter != 'all') {
                      return false;
                    }

                    if (_activeFilter == 'completed') {
                      return b.status == BookingStatus.completed;
                    }
                    if (_activeFilter == 'cancelled') {
                      return b.status == BookingStatus.cancelled ||
                          b.status == BookingStatus.rejected;
                    }
                    return true;
                  }).toList();

                  if (historyList.isEmpty) {
                    return Center(
                      child: SahyanEmptyState(
                        title: 'No past rides found',
                        description:
                            'Your completed and cancelled carpool journeys will be organized here.',
                        icon: Icons.history_rounded,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: historyList.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = historyList[index];
                      return _buildHistoryCard(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _activeFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryForest : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, BookingModel booking) {
    final origin = booking.pickup.name.isNotEmpty
        ? booking.pickup.name
        : (booking.ride?.origin.name ?? 'Pickup Location');
    final destination = booking.drop.name.isNotEmpty
        ? booking.drop.name
        : (booking.ride?.destination.name ?? 'Destination');
    final driverName = booking.ride?.driverName ?? 'Carpool Driver';
    final date = booking.createdAt;

    return InkWell(
      onTap: () {
        context.push('/booking-details', extra: booking);
      },
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SahyanCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SahyanStatusBadge.fromBookingStatus(booking.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$origin → $destination',
              style: AppTypography.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Driver: $driverName • ${booking.requestedSeats} Seat${booking.requestedSeats > 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '₹${booking.totalContribution.toStringAsFixed(0)}',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 15,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
