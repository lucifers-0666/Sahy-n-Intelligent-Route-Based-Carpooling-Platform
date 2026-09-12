import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';

class BookingsHubScreen extends ConsumerStatefulWidget {
  const BookingsHubScreen({super.key});

  @override
  ConsumerState<BookingsHubScreen> createState() => _BookingsHubScreenState();
}

class _BookingsHubScreenState extends ConsumerState<BookingsHubScreen> {
  int _selectedTabIndex = 0;
  final List<SegmentedPillBarItem> _tabs = const [
    SegmentedPillBarItem(label: 'Active', badgeCount: 1),
    SegmentedPillBarItem(label: 'Pending', badgeCount: 1),
    SegmentedPillBarItem(label: 'History'),
  ];

  @override
  Widget build(BuildContext context) {
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
                  items: _tabs,
                  selectedIndex: _selectedTabIndex,
                  onSelect: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
              ),
              Container(color: SahyanColors.border, height: 0.8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            if (_selectedTabIndex == 0) ...[
              // Live Telematics Status Badge
              _buildLiveTelematicsBadge(),
              const SizedBox(height: 14),

              // Digital Boarding Pass Ticket
              _buildDigitalBoardingPass(),
              const SizedBox(height: 14),

              // Action Dock (Call, Chat, Share, SOS)
              _buildActionDock(),
              const SizedBox(height: 14),

              // Eco Impact Mini-Card
              _buildEcoImpactCard(),
            ] else if (_selectedTabIndex == 1) ...[
              // Upcoming Requests Bento
              _buildUpcomingRequestsBento(),
              const SizedBox(height: 14),
              _buildEcoImpactCard(),
            ] else ...[
              // History View
              _buildHistorySection(),
            ],
            const SizedBox(height: 24),
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

  Widget _buildDigitalBoardingPass() {
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
                      child: const Text(
                        'RP',
                        style: TextStyle(
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
                          Row(
                            children: [
                              const Text(
                                'Rohit Patel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: SahyanColors.textMain,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SahyanColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: SahyanColors.goldStar,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      '4.92',
                                      style: TextStyle(
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
                          const Text(
                            'Honda City · GJ 01 AB 1234',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SahyanColors.textMuted,
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '06:30 PM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'AMD · Iscon Cross',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: SahyanColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '09:45 PM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'RAJ · Kalawad Rd',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: SahyanColors.textMuted,
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

          // Perforated Dashed Divider
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(),
          ),

          // Lower Section: Contactless Security PIN & Live Map CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contactless Boarding PIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SahyanColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Show to driver at boarding',
                          style: TextStyle(
                            fontSize: 10,
                            color: SahyanColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SahyanColors.primaryDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '4821',
                        style: TextStyle(
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
                  onPressed: () => context.push('/live-tracking'),
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

  Widget _buildActionDock() {
    return BentoContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.phone_outlined,
            label: 'Call',
            color: SahyanColors.primaryDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling driver Rohit Patel...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            color: SahyanColors.primaryDark,
            onTap: () => context.push('/messages'),
          ),
          _buildActionButton(
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
          _buildActionButton(
            icon: Icons.shield_outlined,
            label: 'SOS',
            color: SahyanColors.urgentCoral,
            isUrgent: true,
            onTap: () => context.push('/trip-safety'),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
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
            ),
          ],
        ),
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
              const Text(
                'Approval Pending',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SahyanColors.textMain,
                ),
              ),
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
                            'Ahmedabad ➔ Surat · Tomorrow 07:00 AM',
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
                    const Text(
                      '2 Seats Requested · ₹520 total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMain,
                      ),
                    ),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rajkot ➔ Ahmedabad',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
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
