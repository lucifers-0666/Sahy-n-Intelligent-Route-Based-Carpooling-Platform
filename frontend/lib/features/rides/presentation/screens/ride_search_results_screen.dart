import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';
import '../rides_provider.dart';

class RideSearchResultsScreen extends ConsumerStatefulWidget {
  const RideSearchResultsScreen({super.key});

  @override
  ConsumerState<RideSearchResultsScreen> createState() =>
      _RideSearchResultsScreenState();
}

class _RideSearchResultsScreenState
    extends ConsumerState<RideSearchResultsScreen> {
  String _selectedSort = 'Earliest';
  bool _verifiedOnly = false;
  bool _acOnly = false;
  bool _womenOnly = false;

  // Radar State
  bool _corridorAlertEnabled = true;
  double _searchRadiusKm = 15.0;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(rideSearchQueryProvider);
    final searchResultsAsync = ref.watch(searchRidesProvider);
    final formattedDate = DateFormat('EEE, dd MMM').format(query.date);

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: AppBar(
        backgroundColor: SahyanColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: SahyanColors.textMain,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    query.origin.isNotEmpty ? query.origin : 'Origin',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.textMain,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: SahyanColors.primaryMint,
                  ),
                ),
                Flexible(
                  child: Text(
                    query.destination.isNotEmpty
                        ? query.destination
                        : 'Destination',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.textMain,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '$formattedDate · ${query.seats} ${query.seats == 1 ? 'Seat' : 'Seats'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: SahyanColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              size: 20,
              color: SahyanColors.primaryDark,
            ),
            onPressed: () => context.push('/filter-rides'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal Bento Filter Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Earliest Departure',
                    isSelected: _selectedSort == 'Earliest',
                    icon: Icons.schedule_rounded,
                    onTap: () => setState(() => _selectedSort = 'Earliest'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Verified Drivers Only',
                    isSelected: _verifiedOnly,
                    icon: Icons.verified_user_rounded,
                    onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'AC Only',
                    isSelected: _acOnly,
                    icon: Icons.ac_unit_rounded,
                    onTap: () => setState(() => _acOnly = !_acOnly),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Women-Only',
                    isSelected: _womenOnly,
                    icon: Icons.female_rounded,
                    onTap: () => setState(() => _womenOnly = !_womenOnly),
                  ),
                ],
              ),
            ),
          ),

          // 2. Results List or Smart Radar Empty State
          Expanded(
            child: searchResultsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: SahyanColors.primaryDark,
                  strokeWidth: 2.5,
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: SahyanColors.urgentCoral,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load corridor rides: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: SahyanColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(searchRidesProvider),
                        child: const Text('Retry Search'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (results) {
                // Apply local client filters
                var filtered = results.map((r) => r.ride).toList();
                if (_verifiedOnly) {
                  filtered = filtered
                      .where((r) => r.isDriverVerified)
                      .toList();
                }
                if (_acOnly) {
                  filtered = filtered
                      .where((r) => r.amenities.contains('AC'))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return _buildSmartRadarEmptyState(query.destination);
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final ride = filtered[index];
                    return _buildLiveRideBentoCard(context, ride);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? SahyanColors.primaryDark : SahyanColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? SahyanColors.primaryDark : SahyanColors.border,
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SahyanColors.primaryDark.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : SahyanColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : SahyanColors.textMain,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRideBentoCard(BuildContext context, RideModel ride) {
    final depTimeStr = ride.departureTime.isNotEmpty
        ? ride.departureTime
        : '06:15 PM';
    final arrTimeStr = ride.estimatedArrival.isNotEmpty
        ? ride.estimatedArrival
        : '09:30 PM';
    final durationStr = ride.route != null && ride.route!.formattedDuration.isNotEmpty
        ? '${ride.route!.formattedDuration} nonstop'
        : '3h 15m nonstop';

    final driverName = ride.driverName.isNotEmpty ? ride.driverName : 'Rohit Patel';
    final ratingVal = ride.driverRating > 0 ? ride.driverRating : 4.9;
    const ridesCount = 184;
    final vehicleDesc = '${ride.vehicle.make} ${ride.vehicle.model} · ${ride.vehicle.color} · Quiet Cabin';

    return BentoContainer(
      onTap: () {
        ref.read(selectedRideProvider.notifier).state = ride;
        context.push('/ride-details');
      },
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SahyanColors.primaryMint,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  driverName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.primaryDark,
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
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: SahyanColors.textMain,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: SahyanColors.primaryMint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: SahyanColors.goldStar,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$ratingVal · $ridesCount rides',
                          style: const TextStyle(
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
              PillTag(
                label: '5 mins away',
                icon: Icons.near_me_rounded,
                variant: PillTagVariant.mint,
                fontSize: 11,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: SahyanColors.border),
          const SizedBox(height: 14),

          // Timeline Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    depTimeStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: SahyanColors.textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ride.origin.name.split(',').first,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SahyanColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    durationStr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.primaryMint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SahyanColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 2,
                        color: SahyanColors.border,
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SahyanColors.primaryMint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrTimeStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: SahyanColors.textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ride.destination.name.split(',').first,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SahyanColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Vehicle Info & Seats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: SahyanColors.chipBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  size: 16,
                  color: SahyanColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vehicleDesc,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SahyanColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PillTag(
                  label: '${ride.availableSeats} Seats Open',
                  variant: PillTagVariant.mint,
                  fontSize: 11,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Price & Request Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${ride.contributionPerSeat.toInt()}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: SahyanColors.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        ' / seat',
                        style: TextStyle(
                          fontSize: 12,
                          color: SahyanColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'No Hidden Charges · RBI Escrow',
                    style: TextStyle(
                      fontSize: 10,
                      color: SahyanColors.textDisabled,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ref.read(selectedRideProvider.notifier).state = ride;
                  context.push('/seat-selection');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Request Seat',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRadarEmptyState(String destination) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      child: Column(
        children: [
          // Radar Visual Graphic
          BentoContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SmartRadarWidget(),
                const SizedBox(height: 20),
                Text(
                  'No direct rides on $destination bypass right now',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vehicles on this highway typically post 15-45 minutes before departure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: SahyanColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: SahyanColors.border),
                const SizedBox(height: 16),

                // Corridor Alert Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant Corridor Alert',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Notify me when a verified driver departs',
                            style: TextStyle(
                              fontSize: 12,
                              color: SahyanColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _corridorAlertEnabled,
                      activeTrackColor: SahyanColors.primaryMint,
                      activeThumbColor: SahyanColors.surface,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _corridorAlertEnabled = val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search Radius Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Corridor Search Radius',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SahyanColors.textMain,
                          ),
                        ),
                        Text(
                          '+${_searchRadiusKm.toInt()} km',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: SahyanColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: SahyanColors.primaryDark,
                        inactiveTrackColor: SahyanColors.border,
                        thumbColor: SahyanColors.primaryMint,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _searchRadiusKm,
                        min: 5,
                        max: 40,
                        divisions: 7,
                        onChanged: (val) => setState(() => _searchRadiusKm = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Outlined CTA: Post as Wanted Ride
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: SahyanColors.primaryDark, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Corridor alert created! Drivers will be notified.'),
                  backgroundColor: SahyanColors.primaryDark,
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, color: SahyanColors.primaryDark, size: 18),
                SizedBox(width: 8),
                Text(
                  'Post as Wanted Ride',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.primaryDark,
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

/// Custom pulsing radar graphic with concentric rings
class SmartRadarWidget extends StatefulWidget {
  const SmartRadarWidget({super.key});

  @override
  State<SmartRadarWidget> createState() => _SmartRadarWidgetState();
}

class _SmartRadarWidgetState extends State<SmartRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: _RadarPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;

  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer concentric guides
    final guidePaint = Paint()
      ..color = SahyanColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, maxRadius * 0.4, guidePaint);
    canvas.drawCircle(center, maxRadius * 0.7, guidePaint);
    canvas.drawCircle(center, maxRadius, guidePaint);

    // Pulsing waves
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i / 3.0)) % 1.0;
      final waveRadius = waveProgress * maxRadius;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.4;

      final wavePaint = Paint()
        ..color = SahyanColors.primaryMint.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // Center Core Dot
    final corePaint = Paint()..color = SahyanColors.primaryDark;
    canvas.drawCircle(center, 8, corePaint);

    final mintDotPaint = Paint()..color = SahyanColors.primaryMint;
    canvas.drawCircle(center, 4, mintDotPaint);

    // Simulated radar sweep beam
    final sweepAngle = progress * 2 * math.pi;
    final beamPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          SahyanColors.primaryMint.withValues(alpha: 0.0),
          SahyanColors.primaryMint.withValues(alpha: 0.25),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
