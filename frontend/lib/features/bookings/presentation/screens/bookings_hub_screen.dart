import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/trip/presentation/widgets/rate_trip_sheet.dart';
import 'package:sahyan/features/trip/presentation/widgets/sos_action_bottom_sheet.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';
import 'package:sahyan/core/localization/l10n_extension.dart';

/// Design tokens for Bookings Hub & Digital Boarding Pass
abstract class BookingsHubColors {
  static const Color canvas = Color(0xFFF6F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8E4);
  static const Color pinePrimary = Color(0xFF1B4D3E);
  static const Color mintAccent = Color(0xFF2EC486);
  static const Color amberWarning = Color(0xFFD97706);
  static const Color amberFill = Color(0xFFFEF3C7);
  static const Color textPrimary = Color(0xFF14241C);
  static const Color textMuted = Color(0xFF5C6E64);
  static const Color textSubtle = Color(0xFF8A9A90);
  static const Color coralUrgent = Color(0xFFE05638);
  static const Color softPill = Color(0xFFEEF2EF);
  static const Color softMint = Color(0xFFE8F5EF);
  static const Color inputBg = Color(0xFFF8FAF8);
  static const Color goldStar = Color(0xFFE5A93C);
}

class BookingsHubScreen extends ConsumerStatefulWidget {
  const BookingsHubScreen({super.key});

  @override
  ConsumerState<BookingsHubScreen> createState() => _BookingsHubScreenState();
}

class _BookingsHubScreenState extends ConsumerState<BookingsHubScreen> {
  int _selectedTabIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Future<void> _handleCancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.l10n.cancelRequestConfirmTitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: BookingsHubColors.textPrimary,
          ),
        ),
        content: Text(
          context.l10n.cancelRequestConfirmMessage,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: BookingsHubColors.textMuted,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.keep,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                color: BookingsHubColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.cancelRequest,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                color: BookingsHubColors.coralUrgent,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(bookingsNotifierProvider.notifier).cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.bookingRequestCancelled)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsNotifierProvider);
    final allBookings = bookingsAsync.value ?? [];
    final activeBookings = allBookings.where((b) => b.isAccepted).toList();
    final pendingBookings = allBookings.where((b) => b.isPending).toList();
    final historyBookings = allBookings
        .where((b) => b.isCompleted || b.isCancelled || b.isRejected)
        .toList();

    final dynamicTabs = [
      SegmentedPillBarItem(
        label: context.l10n.tabActive,
        badgeCount: activeBookings.isNotEmpty ? activeBookings.length : null,
      ),
      SegmentedPillBarItem(
        label: context.l10n.tabPending,
        badgeCount: pendingBookings.isNotEmpty ? pendingBookings.length : null,
      ),
      SegmentedPillBarItem(label: context.l10n.tabHistory),
    ];

    return Scaffold(
      backgroundColor: BookingsHubColors.canvas,
      appBar: AppBar(
        backgroundColor: BookingsHubColors.surface,
        elevation: 0,
        title: Text(
          context.l10n.myJourneys,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: BookingsHubColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.directions_car_rounded,
              color: BookingsHubColors.pinePrimary,
            ),
            tooltip: 'Offered Rides (Driver)',
            onPressed: () => context.push('/driver/rides'),
          ),
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: BookingsHubColors.textMuted,
            ),
            tooltip: 'Trip History',
            onPressed: () => context.push('/ride-history'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SegmentedPillBar(
                  items: dynamicTabs,
                  selectedIndex: _selectedTabIndex,
                  onSelect: _onTabSelected,
                ),
              ),
              Container(color: BookingsHubColors.border, height: 0.8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: bookingsAsync.isLoading
            ? _buildShimmerLoading()
            : PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                children: [
                  // Page 0: Active Journeys (Digital Boarding Pass & Live Telematics)
                  RefreshIndicator(
                    color: BookingsHubColors.pinePrimary,
                    onRefresh: () async {
                      await ref
                          .read(bookingsNotifierProvider.notifier)
                          .fetchMyBookings();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          if (activeBookings.isNotEmpty) ...[
                            ...activeBookings.map(
                              (b) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLiveTelematicsBadge(booking: b),
                                  const SizedBox(height: 14),
                                  DigitalBoardingPass(
                                    booking: b,
                                    onTrackMap: () => context.push(
                                      '/live-tracking',
                                      extra: b,
                                    ),
                                    onViewDetails: () {
                                      if (b.ride != null) {
                                        ref
                                            .read(selectedRideProvider.notifier)
                                            .state = b.ride;
                                      }
                                      final targetId = b.rideId.isNotEmpty
                                          ? b.rideId
                                          : (b.ride?.id ?? '');
                                      if (targetId.isNotEmpty) {
                                        context.push(
                                          '/rides/$targetId',
                                          extra: b.ride,
                                        );
                                      } else if (b.ride != null) {
                                        context.push(
                                          '/ride-details',
                                          extra: b.ride,
                                        );
                                      }
                                    },
                                    onCall: () {
                                      final name = b.ride?.driverName.isNotEmpty == true
                                          ? b.ride!.driverName
                                          : 'Verified Driver';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Calling driver $name...'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    onChat: () => context.push('/messages/${b.id}'),
                                    onShare: () {
                                      final drop = b.drop.address.isNotEmpty
                                          ? b.drop.address
                                          : (b.ride?.destination.address ?? 'destination');
                                      Clipboard.setData(ClipboardData(
                                        text: 'Track my Sahyan journey to $drop live: https://sahyan.app/track/${b.id}',
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Live journey tracking link copied'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    onSos: () => SosActionBottomSheet.show(context, booking: b),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ] else ...[
                            _buildEmptyActivePassesCard(),
                          ],
                          const SizedBox(height: 14),
                          _buildEcoImpactCard(),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),

                  // Page 1: Pending Requests
                  RefreshIndicator(
                    color: BookingsHubColors.pinePrimary,
                    onRefresh: () async {
                      await ref
                          .read(bookingsNotifierProvider.notifier)
                          .fetchMyBookings();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          if (pendingBookings.isNotEmpty) ...[
                            ...pendingBookings.map(
                              (b) => _buildLivePendingCard(b),
                            ),
                          ] else ...[
                            _buildEmptyPendingRequestsCard(),
                          ],
                          const SizedBox(height: 14),
                          _buildEcoImpactCard(),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),

                  // Page 2: History
                  RefreshIndicator(
                    color: BookingsHubColors.pinePrimary,
                    onRefresh: () async {
                      await ref
                          .read(bookingsNotifierProvider.notifier)
                          .fetchMyBookings();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          if (historyBookings.isNotEmpty) ...[
                            ...historyBookings.map(
                              (b) => _buildLiveHistoryCard(b),
                            ),
                          ] else ...[
                            _buildEmptyHistoryCard(),
                          ],
                          const SizedBox(height: 14),
                          _buildEcoImpactCard(),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Telematics Badge
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildLiveTelematicsBadge({BookingModel? booking}) {
    final hasLiveRide = booking != null;
    final pickupDesc = hasLiveRide
        ? (booking.pickup.address.isNotEmpty
              ? booking.pickup.address
              : (booking.ride?.origin.address ?? 'your pickup point'))
        : null;
    final shortPickup = pickupDesc != null && pickupDesc.length > 32
        ? '${pickupDesc.substring(0, 30)}...'
        : (pickupDesc ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasLiveRide ? BookingsHubColors.softMint : BookingsHubColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLiveRide
              ? BookingsHubColors.mintAccent.withValues(alpha: 0.3)
              : BookingsHubColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: BookingsHubColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLiveRide
                  ? Icons.navigation_rounded
                  : Icons.directions_car_outlined,
              color: BookingsHubColors.pinePrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasLiveRide
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver heading to · $shortPickup',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BookingsHubColors.pinePrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Boarding PIN: ${booking.securityPin} · Track live for ETA',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: BookingsHubColors.textMuted,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'No active ride telematics',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BookingsHubColors.textMuted,
                    ),
                  ),
          ),
          if (hasLiveRide)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: BookingsHubColors.mintAccent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Pending Request Card
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildLivePendingCard(BookingModel booking) {
    final driverName = booking.ride?.driverName.isNotEmpty == true
        ? booking.ride!.driverName
        : 'Verified Driver';
    final originCity = booking.pickup.city.isNotEmpty
        ? booking.pickup.city
        : (booking.pickup.address.split(',').first.trim().isNotEmpty
              ? booking.pickup.address.split(',').first.trim()
              : (booking.ride?.origin.city ?? 'Ahmedabad'));
    final destCity = booking.drop.city.isNotEmpty
        ? booking.drop.city
        : (booking.drop.address.split(',').first.trim().isNotEmpty
              ? booking.drop.address.split(',').first.trim()
              : (booking.ride?.destination.city ?? 'Surat'));
    final departureTime = booking.ride?.departureTime.isNotEmpty == true
        ? booking.ride!.departureTime
        : 'Tomorrow, 07:00 AM';
    final fare = booking.totalContribution.toInt();
    final seats = booking.requestedSeats;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookingsHubColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BookingsHubColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Driver/Ride Info + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$driverName · $originCity ➔ $destCity',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BookingsHubColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Departure: $departureTime',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: BookingsHubColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BookingsHubColors.amberFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: BookingsHubColors.amberWarning.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 11,
                      color: BookingsHubColors.amberWarning,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Under Review',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: BookingsHubColors.amberWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fare & Seat Summary + Auto-Expiry
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BookingsHubColors.inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BookingsHubColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$seats Seat${seats > 1 ? 's' : ''} Requested · ₹$fare total contribution',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: BookingsHubColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: BookingsHubColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.l10n.autoExpiresIn(14),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: BookingsHubColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Cancel Request + View Ride Details
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _handleCancelBooking(booking.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BookingsHubColors.coralUrgent,
                      side: const BorderSide(
                        color: BookingsHubColors.coralUrgent,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      context.l10n.cancelRequest,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (booking.ride != null) {
                        ref.read(selectedRideProvider.notifier).state =
                            booking.ride;
                      }
                      final targetId = booking.rideId.isNotEmpty
                          ? booking.rideId
                          : (booking.ride?.id ?? '');
                      if (targetId.isNotEmpty) {
                        context.push(
                          '/rides/$targetId',
                          extra: booking.ride,
                        );
                      } else if (booking.ride != null) {
                        context.push(
                          '/ride-details',
                          extra: booking.ride,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ride details are not available'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookingsHubColors.softMint,
                      foregroundColor: BookingsHubColors.pinePrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      context.l10n.viewRideDetails,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. History Journey Card
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildLiveHistoryCard(BookingModel booking) {
    final originCity = booking.pickup.city.isNotEmpty
        ? booking.pickup.city
        : (booking.pickup.address.split(',').first.trim().isNotEmpty
              ? booking.pickup.address.split(',').first.trim()
              : (booking.ride?.origin.city ?? 'Rajkot'));
    final destCity = booking.drop.city.isNotEmpty
        ? booking.drop.city
        : (booking.drop.address.split(',').first.trim().isNotEmpty
              ? booking.drop.address.split(',').first.trim()
              : (booking.ride?.destination.city ?? 'Ahmedabad'));
    final fare = booking.totalContribution.toInt();
    final seats = booking.requestedSeats;
    final driverName = booking.ride?.driverName.isNotEmpty == true
        ? booking.ride!.driverName
        : 'Rohit Patel';
    final vehicleModel = booking.ride?.vehicle.make.isNotEmpty == true
        ? '${booking.ride!.vehicle.make} ${booking.ride!.vehicle.model}'
        : 'Honda City ZX';
    final isCompleted = booking.status == BookingStatus.completed;
    final statusColor = isCompleted
        ? BookingsHubColors.mintAccent
        : BookingsHubColors.coralUrgent;
    final statusText = booking.status.name.toUpperCase();
    final formattedDate =
        '${booking.createdAt.day} ${_monthName(booking.createdAt.month)} ${booking.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: BookingsHubColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BookingsHubColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (booking.ride != null) {
              ref.read(selectedRideProvider.notifier).state = booking.ride;
            }
            final targetId = booking.rideId.isNotEmpty
                ? booking.rideId
                : (booking.ride?.id ?? '');
            if (targetId.isNotEmpty) {
              context.push('/rides/$targetId', extra: booking.ride);
            } else if (booking.ride != null) {
              context.push('/ride-details', extra: booking.ride);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Header Row: Date & Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BookingsHubColors.softPill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BookingsHubColors.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Route: Rajkot ➔ Ahmedabad
          Text(
            '$originCity ➔ $destCity',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BookingsHubColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Fare & Seats: ₹350 total · 1 Seat
          Text(
            '₹$fare total · $seats Seat${seats > 1 ? 's' : ''}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BookingsHubColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Driver info with vehicle model
          Text(
            'Driver: $driverName · $vehicleModel',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BookingsHubColors.textSubtle,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Action Button: Rate Trip & Driver (for completed bookings)
          if (isCompleted) ...[
            const SizedBox(height: 14),
            const Divider(color: BookingsHubColors.border, height: 1, thickness: 0.8),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => RateTripSheet.show(
                  context,
                  booking: booking,
                  driverName: driverName,
                ),
                icon: const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: BookingsHubColors.goldStar,
                ),
                label: const Text(
                  'Rate Trip & Driver',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BookingsHubColors.pinePrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BookingsHubColors.pinePrimary,
                  side: const BorderSide(
                    color: BookingsHubColors.pinePrimary,
                    width: 0.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  ),
),
);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Interactive Eco & Carbon Impact Bento
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildEcoImpactCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCarbonBreakdownModal(context);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BookingsHubColors.softMint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: BookingsHubColors.mintAccent.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BookingsHubColors.mintAccent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    color: BookingsHubColors.mintAccent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You saved 14.8 kg CO₂ this month',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: BookingsHubColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Top 12% among Gujarat EV Corridor sharers',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: BookingsHubColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: BookingsHubColors.pinePrimary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCarbonBreakdownModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BookingsHubColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Carbon Savings Breakdown',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: BookingsHubColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BookingsHubColors.softMint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Gujarat EV & Green Corridor Leader',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BookingsHubColors.pinePrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildEcoMetricCell('14.8 kg', 'Total CO₂ Offset', 'Equivalent to 2 trees planted'),
                    const SizedBox(width: 10),
                    _buildEcoMetricCell('6.2 L', 'Fuel Conserved', 'Saved via shared corridor'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildEcoMetricCell('320 km', 'Corridor Distance', 'Shared passenger travel'),
                    const SizedBox(width: 10),
                    _buildEcoMetricCell('3.4x', 'Fleet Efficiency', 'Vs single-occupancy vehicle'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BookingsHubColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BookingsHubColors.border, width: 0.8),
                  ),
                  child: const Text(
                    'Calculated based on ARAI passenger vehicle average emission benchmarks (120g CO₂/km) for multi-passenger corridor sharing.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      color: BookingsHubColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookingsHubColors.pinePrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEcoMetricCell(String value, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BookingsHubColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BookingsHubColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: BookingsHubColors.pinePrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: BookingsHubColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                color: BookingsHubColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. Empty States
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyActivePassesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: BookingsHubColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BookingsHubColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: BookingsHubColors.softMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              size: 30,
              color: BookingsHubColors.pinePrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noActiveBoardingPasses,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: BookingsHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your confirmed trips, departure PIN, and live driver tracking will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: BookingsHubColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/rides'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BookingsHubColors.pinePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Find Matching Rides →',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPendingRequestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: BookingsHubColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BookingsHubColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: BookingsHubColors.amberFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 30,
              color: BookingsHubColors.amberWarning,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noPendingRequests,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: BookingsHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You do not have any pending booking requests awaiting driver approval at this moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: BookingsHubColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: BookingsHubColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BookingsHubColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: BookingsHubColors.softPill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 32,
              color: BookingsHubColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noTripHistory,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: BookingsHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completed and previous journeys across Gujarat highway corridors will appear here once finished.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: BookingsHubColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. Skeleton Shimmer Loader
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(children: List.generate(3, (i) => _ShimmerCard(index: i))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Digital Boarding Pass Component (Option A / Wallet Grade)
// ─────────────────────────────────────────────────────────────────────────────

class DigitalBoardingPass extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTrackMap;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onShare;
  final VoidCallback? onSos;
  final VoidCallback? onViewDetails;

  const DigitalBoardingPass({
    super.key,
    required this.booking,
    this.onTrackMap,
    this.onCall,
    this.onChat,
    this.onShare,
    this.onSos,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final driverName = booking.ride?.driverName.isNotEmpty == true
        ? booking.ride!.driverName
        : 'Rohit Patel';
    final initials = driverName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    final driverRating = booking.ride != null && booking.ride!.driverRating > 0
        ? booking.ride!.driverRating.toStringAsFixed(2)
        : '4.92';
    final vehicleModel =
        booking.ride != null && booking.ride!.vehicle.make.isNotEmpty
            ? '${booking.ride!.vehicle.make} ${booking.ride!.vehicle.model}'
            : 'Honda City ZX';
    final vehiclePlate =
        booking.ride?.vehicle.registrationNumber.isNotEmpty == true
            ? booking.ride!.vehicle.registrationNumber
            : 'GJ 01 AB 1234';
    final pinCode = booking.securityPin;

    final departureTime = booking.ride?.departureTime.isNotEmpty == true
        ? booking.ride!.departureTime
        : '06:30 PM';
    final arrivalTime = booking.ride?.estimatedArrival.isNotEmpty == true
        ? booking.ride!.estimatedArrival
        : '09:45 PM';

    final pickupName = booking.pickup.address.isNotEmpty
        ? booking.pickup.address
        : (booking.ride?.origin.address.isNotEmpty == true
              ? booking.ride!.origin.address
              : 'Prahlad Nagar, SG Highway, Ahmedabad');
    final dropName = booking.drop.address.isNotEmpty
        ? booking.drop.address
        : (booking.ride?.destination.address.isNotEmpty == true
              ? booking.ride!.destination.address
              : 'Kalawad Road, Rajkot');

    final distanceDurationText = booking.ride?.route != null
        ? '${booking.ride!.route!.formattedDistance} · Non-stop · Est. ${booking.ride!.route!.formattedDuration}'
        : '215 km · Non-stop · Est. 3h 15m';

    return Container(
      decoration: BoxDecoration(
        color: BookingsHubColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BookingsHubColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Header Row: Driver Avatar + Name + Rating + Vehicle Chip + Status Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 460;

                    Widget buildAvatar() => Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: BookingsHubColors.softPill,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials.isNotEmpty ? initials : 'RP',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: BookingsHubColors.pinePrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );

                    Widget buildDriverRatingBadge() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: BookingsHubColors.softMint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: BookingsHubColors.goldStar,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                driverRating,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: BookingsHubColors.pinePrimary,
                                ),
                              ),
                            ],
                          ),
                        );

                    Widget buildVehicleChip() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BookingsHubColors.softPill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$vehicleModel · $vehiclePlate',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: BookingsHubColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );

                    Widget buildStatusBadge() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BookingsHubColors.softMint,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: BookingsHubColors.mintAccent
                                  .withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: BookingsHubColors.mintAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'CONFIRMED & PAID',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: BookingsHubColors.pinePrimary,
                                ),
                              ),
                            ],
                          ),
                        );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: buildVehicleChip()),
                              const SizedBox(width: 8),
                              buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              buildAvatar(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      driverName,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: BookingsHubColors.textPrimary,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: BookingsHubColors.mintAccent,
                                    ),
                                    buildDriverRatingBadge(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildAvatar(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: BookingsHubColors.textPrimary,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: BookingsHubColors.mintAccent,
                                  ),
                                  buildDriverRatingBadge(),
                                ],
                              ),
                              const SizedBox(height: 3),
                              buildVehicleChip(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        buildStatusBadge(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Route & Time Matrix
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onViewDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: BookingsHubColors.inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BookingsHubColors.border, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          // Left Column: Pickup Time & Location
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  departureTime,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: BookingsHubColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  pickupName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: BookingsHubColors.textMuted,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Center Column: Distance & Non-stop corridor indicator
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: BookingsHubColors.pinePrimary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: BookingsHubColors.mintAccent,
                                        thickness: 1.2,
                                        height: 1,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: BookingsHubColors.mintAccent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    distanceDurationText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: BookingsHubColors.mintAccent,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Right Column: Drop Time & Location
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  arrivalTime,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: BookingsHubColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  dropName,
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: BookingsHubColors.textMuted,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Perforated Ticket Divider with Notches
          const TicketNotchDivider(),

          // 4. Contactless Security PIN & Action Dock
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Highlighted PIN Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: BookingsHubColors.inputBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BookingsHubColors.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONTACTLESS BOARDING PIN',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: BookingsHubColors.textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Show to driver at boarding',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: BookingsHubColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: BookingsHubColors.border, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          pinCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: BookingsHubColors.pinePrimary,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Primary CTA: [ Track Live on Map ]
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onTrackMap,
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Track Live on Map',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookingsHubColors.pinePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Secondary Quick Tray (4 circular buttons: Call, Chat, Share Trip, SOS)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickActionItem(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      color: BookingsHubColors.pinePrimary,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onCall?.call();
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      color: BookingsHubColors.pinePrimary,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onChat?.call();
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.share_outlined,
                      label: 'Share Trip',
                      color: BookingsHubColors.pinePrimary,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onShare?.call();
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.shield_outlined,
                      label: 'SOS',
                      color: BookingsHubColors.coralUrgent,
                      isUrgent: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onSos?.call();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    bool isUrgent = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? BookingsHubColors.coralUrgent.withValues(alpha: 0.1)
                        : BookingsHubColors.softPill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUrgent
                          ? BookingsHubColors.coralUrgent.withValues(alpha: 0.3)
                          : BookingsHubColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 20),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Perforated Ticket Divider with Edge Notches
// ─────────────────────────────────────────────────────────────────────────────

class TicketNotchDivider extends StatelessWidget {
  final Color notchColor;
  final Color borderColor;
  final Color dashColor;
  final double height;

  const TicketNotchDivider({
    super.key,
    this.notchColor = BookingsHubColors.canvas,
    this.borderColor = BookingsHubColors.border,
    this.dashColor = BookingsHubColors.border,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Dashed Separator Line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(color: dashColor),
            ),
          ),
          // Left Semi-Circle Ticket Notch
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: notchColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 0.8),
              ),
            ),
          ),
          // Right Semi-Circle Ticket Notch
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: notchColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Skeleton Loader
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  final int index;
  const _ShimmerCard({required this.index});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.4 + _anim.value * 0.35;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BookingsHubColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BookingsHubColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(40, 40, radius: 20, opacity: opacity),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(120, 12, opacity: opacity),
                      const SizedBox(height: 6),
                      _shimmerBox(80, 10, opacity: opacity),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 48, radius: 12, opacity: opacity),
              const SizedBox(height: 10),
              _shimmerBox(double.infinity, 40, radius: 12, opacity: opacity),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(
    double width,
    double height, {
    double radius = 8,
    required double opacity,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: BookingsHubColors.border,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Perforation Line Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({this.color = BookingsHubColors.border});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height <= 0 ? 1.0 : size.height
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;
    while (startX < size.width) {
      final endX = (startX + dashWidth > size.width)
          ? size.width
          : startX + dashWidth;
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
