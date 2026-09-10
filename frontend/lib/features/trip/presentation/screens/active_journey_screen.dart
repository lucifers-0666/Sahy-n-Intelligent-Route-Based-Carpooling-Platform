import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../bookings/presentation/bookings_provider.dart';

class ActiveJourneyScreen extends ConsumerWidget {
  final BookingModel? initialBooking;

  const ActiveJourneyScreen({super.key, this.initialBooking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BookingModel? booking = initialBooking;

    if (booking == null) {
      final bookingsAsync = ref.watch(bookingsNotifierProvider);
      bookingsAsync.whenData((bookings) {
        final activeList = bookings
            .where(
              (b) =>
                  b.status == BookingStatus.accepted ||
                  (b.ride != null &&
                      (b.ride!.status.name == 'active' ||
                          b.ride!.status.name == 'boarding')),
            )
            .toList();
        if (activeList.isNotEmpty) {
          booking = activeList.first;
        }
      });
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: const SahyanAppBar(title: 'Your Journey', showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SahyanEmptyState(
                  title: 'No Active Journey',
                  description:
                      'You do not have any confirmed or ongoing carpool rides right now.',
                  icon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                SahyanButton(
                  text: 'Find a Ride',
                  icon: Icons.search_rounded,
                  onPressed: () => context.go('/search-results'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SahyanButton(
                  text: 'View My Bookings',
                  variant: SahyanButtonVariant.outline,
                  onPressed: () => context.go('/my-bookings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeBooking = booking!;
    final ride = activeBooking.ride;
    final driverName = ride?.driverName ?? 'Driver';
    final vehicle = ride?.vehicle;
    final originName = activeBooking.pickup.name.isNotEmpty
        ? activeBooking.pickup.name
        : (ride?.origin.name ?? 'Pickup Location');
    final destinationName = activeBooking.drop.name.isNotEmpty
        ? activeBooking.drop.name
        : (ride?.destination.name ?? 'Destination');

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Active Journey',
        subtitle: 'Confirmed Carpool Ride',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryForest,
              size: 22,
            ),
            tooltip: 'Safety',
            onPressed: () => context.push('/trip-safety'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status & Boarding PIN Card
              SahyanCard(
                backgroundColor: AppColors.deepForest,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryForest,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'BOARDING ACTIVE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${activeBooking.requestedSeats} Seat${activeBooking.requestedSeats > 1 ? 's' : ''}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Ready for Departure',
                      style: AppTypography.screenTitle.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your boarding verification PIN with the driver.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BOARDING PIN',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '7 4 1 9',
                            style: AppTypography.screenTitle.copyWith(
                              color: AppColors.softForest,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4.0,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Route Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE TIMELINE',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryForest,
                                  width: 3,
                                ),
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 42,
                              color: AppColors.border,
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                originName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Drop-off Destination',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                destinationName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
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

              const SizedBox(height: AppSpacing.md),

              // Driver & Vehicle Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SahyanAvatar(name: driverName, radius: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    driverName,
                                    style: AppTypography.cardTitle.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.mutedBrass,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vehicle != null
                                    ? '${vehicle.make} ${vehicle.model} • ${vehicle.registrationNumber}'
                                    : 'Registered Carpool Vehicle',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SahyanButton(
                            text: 'Call Driver',
                            icon: Icons.phone_outlined,
                            variant: SahyanButtonVariant.outline,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contacting driver...'),
                                  backgroundColor: AppColors.deepForest,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SahyanButton(
                            text: 'Chat',
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: () => context.push('/messages'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              SahyanButton(
                text: 'Open Live Route Map',
                icon: Icons.map_outlined,
                isFullWidth: true,
                onPressed: () => context.push('/live-tracking'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SahyanButton(
                text: 'Safety Assistance & Contacts',
                icon: Icons.health_and_safety_outlined,
                variant: SahyanButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => context.push('/trip-safety'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SahyanButton(
                text: 'Mark as Completed (Demo Preview)',
                variant: SahyanButtonVariant.ghost,
                isFullWidth: true,
                onPressed: () {
                  context.push('/journey-completed', extra: activeBooking);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
