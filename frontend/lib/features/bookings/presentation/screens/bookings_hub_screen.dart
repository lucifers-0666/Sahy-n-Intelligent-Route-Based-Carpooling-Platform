import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/trip/presentation/widgets/sos_action_bottom_sheet.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';

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
        label: 'Active',
        badgeCount: activeBookings.isNotEmpty ? activeBookings.length : 1,
      ),
      SegmentedPillBarItem(
        label: 'Pending',
        badgeCount: pendingBookings.isNotEmpty ? pendingBookings.length : 1,
      ),
      const SegmentedPillBarItem(label: 'History'),
    ];

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: AppBar(
        backgroundColor: SahyanColors.surface,
        elevation: 0,
        title: const Text(
          'My Journeys',
          style: TextStyle(
            color: SahyanColors.textMain,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: SahyanColors.textMuted),
            tooltip: 'Trip History',
            onPressed: () => context.push('/ride-history'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedPillBar(
                  items: dynamicTabs,
                  selectedIndex: _selectedTabIndex,
                  onSelect: _onTabSelected,
                ),
              ),
              Container(color: SahyanColors.border, height: 0.8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          children: [
            // Page 0: Active Journeys
            RefreshIndicator(
              color: SahyanColors.primaryDark,
              onRefresh: () async {
                await ref.read(bookingsNotifierProvider.notifier).fetchMyBookings();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    _buildLiveTelematicsBadge(),
                    const SizedBox(height: 14),
                    _buildDigitalBoardingPass(
                      booking: activeBookings.isNotEmpty ? activeBookings.first : null,
                    ),
                    const SizedBox(height: 14),
                    _buildActionDock(
                      driverName: activeBookings.isNotEmpty
                          ? (activeBookings.first.ride?.driverName ?? 'Rohit Patel')
                          : 'Rohit Patel',
                      booking: activeBookings.isNotEmpty ? activeBookings.first : null,
                    ),
                    const SizedBox(height: 14),
                    _buildEcoImpactCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Page 1: Pending Requests
            RefreshIndicator(
              color: SahyanColors.primaryDark,
              onRefresh: () async {
                await ref.read(bookingsNotifierProvider.notifier).fetchMyBookings();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    if (pendingBookings.isNotEmpty) ...[
                      ...pendingBookings.map((b) => _buildLivePendingCard(b)),
                    ] else ...[
                      _buildUpcomingRequestsBento(),
                    ],
                    const SizedBox(height: 14),
                    _buildEcoImpactCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Page 2: History
            RefreshIndicator(
              color: SahyanColors.primaryDark,
              onRefresh: () async {
                await ref.read(bookingsNotifierProvider.notifier).fetchMyBookings();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    if (historyBookings.isNotEmpty) ...[
                      ...historyBookings.map((b) => _buildLiveHistoryCard(b)),
                    ] else ...[
                      _buildHistorySection(),
                    ],
                    const SizedBox(height: 14),
                    _buildEcoImpactCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTelematicsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SahyanColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SahyanColors.primaryMint.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: SahyanColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: SahyanColors.primaryDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver en route to pickup · 4.2 km away',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.primaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ETA: 8 mins at Iscon Cross Roads, SG Highway',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: SahyanColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: SahyanColors.primaryMint,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalBoardingPass({BookingModel? booking}) {
    final driverName = booking?.ride?.driverName ?? 'Rohit Patel';
    final initials = driverName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join();
    final driverRating = booking?.ride != null
        ? booking!.ride!.driverRating.toStringAsFixed(2)
        : '4.92';
    final vehicleModel = booking?.ride != null
        ? '${booking!.ride!.vehicle.make} ${booking.ride!.vehicle.model}'
        : 'Honda City';
    final vehiclePlate =
        booking?.ride?.vehicle.registrationNumber ?? 'GJ 01 AB 1234';
    final pinCode = booking?.securityPin ?? '4821';
    final pickupName = booking != null && booking.pickup.address.isNotEmpty
        ? booking.pickup.address
        : 'AMD · Iscon Cross';
    final dropName = booking != null && booking.drop.address.isNotEmpty
        ? booking.drop.address
        : 'RAJ · Kalawad Rd';

    return BentoContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Upper Section: Driver & Vehicle Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: SahyanColors.primaryLight,
                      child: Text(
                        initials.isNotEmpty ? initials : 'RP',
                        style: const TextStyle(
                          color: SahyanColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: SahyanColors.textMain,
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: SahyanColors.primaryMint,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SahyanColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: SahyanColors.goldStar,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      driverRating,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '$vehicleModel ·',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SahyanColors.textMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: SahyanColors.canvas,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: SahyanColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  vehiclePlate,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: SahyanColors.textMain,
                                  ),
                                ),
                              ),
                            ],
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
                        color: SahyanColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CONFIRMED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: SahyanColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Journey Timeline
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SahyanColors.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SahyanColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: SahyanColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 1.5,
                                height: 28,
                                color: SahyanColors.border,
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: SahyanColors.primaryMint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '06:30 PM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        pickupName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: SahyanColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '09:45 PM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        dropName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: SahyanColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Perforated Dashed Divider with Ticket Notch Cutouts
          _buildTicketNotchDivider(),

          // Lower Section: Contactless Security PIN & Live Map CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contactless Boarding PIN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SahyanColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Show to driver at boarding',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: SahyanColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SahyanColors.primaryDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pinCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: SahyanColors.primaryMint,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/live-tracking', extra: booking),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Track Live on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SahyanColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketNotchDivider() {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(),
            ),
          ),
          // Left Semi-Circle Ticket Notch
          Positioned(
            left: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: SahyanColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: SahyanColors.border, width: 0.8),
              ),
            ),
          ),
          // Right Semi-Circle Ticket Notch
          Positioned(
            right: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: SahyanColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: SahyanColors.border, width: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock({String driverName = 'Rohit Patel', BookingModel? booking}) {
    final bookingId = booking?.id ?? 'conv-1';
    return BentoContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone_outlined,
              label: 'Call',
              color: SahyanColors.primaryDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling driver $driverName...'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              color: SahyanColors.primaryDark,
              onTap: () => context.push('/messages/$bookingId'),
            ),
          ),
          Expanded(
            child: _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              color: SahyanColors.primaryDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live journey tracking link copied'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _buildActionButton(
              icon: Icons.shield_outlined,
              label: 'SOS',
              color: SahyanColors.urgentCoral,
              isUrgent: true,
              onTap: () => SosActionBottomSheet.show(context, booking: booking),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isUrgent = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUrgent
                    ? SahyanColors.urgentCoral.withValues(alpha: 0.1)
                    : SahyanColors.chipBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUrgent
                      ? SahyanColors.urgentCoral.withValues(alpha: 0.3)
                      : SahyanColors.border,
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePendingCard(BookingModel booking) {
    final driverName = booking.ride?.driverName ?? 'Driver';
    final initials = driverName.trim().isNotEmpty
        ? driverName.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
        : 'DR';
    final origin = booking.pickup.address.isNotEmpty
        ? booking.pickup.address
        : (booking.ride?.origin.address ?? 'Origin');
    final destination = booking.drop.address.isNotEmpty
        ? booking.drop.address
        : (booking.ride?.destination.address ?? 'Destination');
    final fare = booking.totalContribution.toInt();
    final seats = booking.requestedSeats;
    final statusText = booking.status.name.toUpperCase();

    return BentoContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Approval Pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SahyanColors.goldStar.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.goldStar,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: SahyanColors.primaryLight,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: SahyanColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                          ),
                          Text(
                            '$origin → $destination',
                            style: const TextStyle(
                              fontSize: 11,
                              color: SahyanColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(
                  color: SahyanColors.border,
                  height: 1,
                  thickness: 0.8,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$seats Seat${seats > 1 ? 's' : ''} Requested · ₹$fare total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SahyanColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Request?'),
                            content: const Text('Are you sure you want to cancel this booking request?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Cancel Request', style: TextStyle(color: SahyanColors.urgentCoral)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await ref.read(bookingsNotifierProvider.notifier).cancelBooking(booking.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking request cancelled')),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SahyanColors.urgentCoral,
                        side: const BorderSide(
                          color: SahyanColors.urgentCoral,
                          width: 0.8,
                        ),
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildLiveHistoryCard(BookingModel booking) {
    final origin = booking.pickup.address.isNotEmpty
        ? booking.pickup.address
        : (booking.ride?.origin.address ?? 'Origin');
    final destination = booking.drop.address.isNotEmpty
        ? booking.drop.address
        : (booking.ride?.destination.address ?? 'Destination');
    final fare = booking.totalContribution.toInt();
    final driverName = booking.ride?.driverName ?? 'Verified Driver';
    final isCompleted = booking.status == BookingStatus.completed;
    final statusColor = isCompleted
        ? SahyanColors.primaryMint
        : SahyanColors.urgentCoral;
    final statusText = booking.status.name.toUpperCase();
    final seats = booking.requestedSeats;

    return BentoContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$origin → $destination',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹$fare total · $seats Seat${seats > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Driver: $driverName',
                        style: const TextStyle(
                          fontSize: 11,
                          color: SahyanColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRequestsBento() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Approval Pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SahyanColors.goldStar.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Under Review',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.goldStar,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: SahyanColors.primaryLight,
                      child: Text(
                        'PS',
                        style: TextStyle(
                          color: SahyanColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Priya Sharma',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                          ),
                          Text(
                            'Ahmedabad → Surat · Tomorrow 07:00 AM',
                            style: TextStyle(
                              fontSize: 11,
                              color: SahyanColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(
                  color: SahyanColors.border,
                  height: 1,
                  thickness: 0.8,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '2 Seats Requested · ₹520 total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SahyanColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request details viewed'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SahyanColors.primaryDark,
                        side: const BorderSide(
                          color: SahyanColors.border,
                          width: 0.8,
                        ),
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildEcoImpactCard() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SahyanColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: SahyanColors.primaryMint,
              size: 24,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMain,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Top 12% among Gujarat EV Corridor sharers',
                  style: TextStyle(
                    fontSize: 11,
                    color: SahyanColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completed Journeys',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SahyanColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Rajkot → Ahmedabad',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.textMain,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '₹350',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Yesterday · 219 km · Driver: Jay Patel',
                  style: TextStyle(
                    fontSize: 11,
                    color: SahyanColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SahyanColors.border
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
