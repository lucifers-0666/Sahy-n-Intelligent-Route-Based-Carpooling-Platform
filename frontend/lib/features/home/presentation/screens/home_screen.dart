import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/location_model.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../rides/presentation/rides_provider.dart';
import '../widgets/hero_search_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _originController = TextEditingController(
    text: 'SG Highway, Ahmedabad',
  );
  final TextEditingController _destinationController = TextEditingController(
    text: 'Rajkot, Kalawad Road',
  );

  LocationModel _originLocation = LocationModel.fromCoordinates(
    name: 'SG Highway, Ahmedabad',
    latitude: 23.0225,
    longitude: 72.5714,
  );
  LocationModel _destinationLocation = LocationModel.fromCoordinates(
    name: 'Rajkot, Kalawad Road',
    latitude: 22.3039,
    longitude: 70.8022,
  );

  int _selectedSeats = 2;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 30);

  // Pulsating dot animation controller
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const List<Map<String, dynamic>> _quickCorridors = [
    {
      'from': 'Bhuj',
      'to': 'Ahmedabad',
      'price': 388,
      'fromLat': 23.2420,
      'fromLng': 69.6669,
      'toLat': 23.0225,
      'toLng': 72.5714,
    },
    {
      'from': 'Rajkot',
      'to': 'Surat',
      'price': 520,
      'fromLat': 22.3039,
      'fromLng': 70.8022,
      'toLat': 21.1702,
      'toLng': 72.8311,
    },
    {
      'from': 'Vadodara',
      'to': 'Ahmedabad',
      'price': 210,
      'fromLat': 22.3072,
      'fromLng': 73.1812,
      'toLat': 23.0225,
      'toLng': 72.5714,
    },
    {
      'from': 'Morbi',
      'to': 'Rajkot',
      'price': 120,
      'fromLat': 22.8120,
      'fromLng': 70.8370,
      'toLat': 22.3039,
      'toLng': 70.8022,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    HapticFeedback.mediumImpact();
    setState(() {
      final tempText = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = tempText;

      final tempLoc = _originLocation;
      _originLocation = _destinationLocation;
      _destinationLocation = tempLoc;
    });
  }

  void _selectQuickCorridor(Map<String, dynamic> corridor) {
    HapticFeedback.selectionClick();
    setState(() {
      _originController.text = corridor['from'] as String;
      _destinationController.text = corridor['to'] as String;
      _originLocation = LocationModel.fromCoordinates(
        name: corridor['from'] as String,
        latitude: corridor['fromLat'] as double,
        longitude: corridor['fromLng'] as double,
      );
      _destinationLocation = LocationModel.fromCoordinates(
        name: corridor['to'] as String,
        latitude: corridor['toLat'] as double,
        longitude: corridor['toLng'] as double,
      );
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SahyanColors.primaryDark,
              onPrimary: Colors.white,
              surface: SahyanColors.surface,
              onSurface: SahyanColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: SahyanColors.primaryDark,
                onPrimary: Colors.white,
                surface: SahyanColors.surface,
                onSurface: SahyanColors.textMain,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _handleSearch() {
    HapticFeedback.mediumImpact();
    final originText = _originController.text.trim();
    final destText = _destinationController.text.trim();

    if (originText.isEmpty || destText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify both origin and destination corridors.'),
          backgroundColor: SahyanColors.urgentCoral,
        ),
      );
      return;
    }

    final depDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    ref.read(rideSearchQueryProvider.notifier).state = RideSearchQuery(
      origin: originText,
      destination: destText,
      originLocation: _originLocation,
      destinationLocation: _destinationLocation,
      date: depDate,
      time: _selectedTime,
      seats: _selectedSeats,
    );

    context.push('/search-results');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final unreadNotifs = ref.watch(notificationsProvider).unreadCount;
    final displayName = user?.name.split(' ').first ?? 'Arjun';

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ──────────────────────────────────────────────────────────────
            // 1. Top App Header Bar
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Brand tag + Greeting + Location pill
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand tag: ● SAHYĀN 2026
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: SahyanColors.primaryMint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'SAHYĀN 2026',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: SahyanColors.textMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Main greeting
                          Text(
                            'Hey $displayName 👋',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: SahyanColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Active Location Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SahyanColors.primaryLight,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: SahyanColors.primaryMint
                                    .withValues(alpha: 0.3),
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
                                    color: SahyanColors.primaryMint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  '📍',
                                  style: TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 2),
                                const Flexible(
                                  child: Text(
                                    'Ahmedabad Hub',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: SahyanColors.primaryDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Notification Bell + Avatar
                    Row(
                      children: [
                        // Notification Bell
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: SahyanColors.surface,
                              shape: const CircleBorder(
                                side: BorderSide(
                                  color: SahyanColors.border,
                                  width: 0.8,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => context.push('/notifications'),
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      size: 20,
                                      color: SahyanColors.textMain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (unreadNotifs > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SahyanColors.primaryMint,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$unreadNotifs',
                                    style: const TextStyle(
                                      color: SahyanColors.primaryDark,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),

                        // User Avatar with verified badge
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
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
                                  displayName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: SahyanColors.primaryDark,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: SahyanColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: SahyanColors.primaryMint,
                                  ),
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
            ),

            // ──────────────────────────────────────────────────────────────
            // 2. Hero Search Bento Card
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              sliver: SliverToBoxAdapter(
                child: HeroSearchCard(
                  originController: _originController,
                  destinationController: _destinationController,
                  onSwap: _swapLocations,
                  onSelectCorridor: _selectQuickCorridor,
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  onPickDateTime: _pickDateTime,
                  selectedSeats: _selectedSeats,
                  onSeatsChanged: (val) => setState(() => _selectedSeats = val),
                  onSearch: _handleSearch,
                  popularCorridors: _quickCorridors,
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // 3. Section Header: Live Highway Corridors
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Live Highway Corridors',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    // ● Live Telematics pulsating badge
                    _PulsatingTelematics(animation: _pulseAnimation),
                  ],
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // 4. Corridor Bento Cards + Metric Mini Bentos
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Corridor Card 1: Ahmedabad → Rajkot Express
                  _CorridorBentoCard(
                    routeName: 'Ahmedabad ➔ Rajkot Express',
                    speedLabel: '⚡ 94 km/h avg',
                    driverInfo: '12 verified drivers ready · Next in 8 mins',
                    badges: const ['via NH47', 'EV Fastlane'],
                    badgeVariants: const [
                      PillTagVariant.neutral,
                      PillTagVariant.mint,
                    ],
                    badgeIcons: const [null, Icons.bolt_rounded],
                    price: '₹320 / seat',
                    onTap: () {
                      _originController.text = 'Ahmedabad SG Highway';
                      _destinationController.text = 'Rajkot Trikon Baug';
                      _handleSearch();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Corridor Card 2: Surat → Vadodara
                  _CorridorBentoCard(
                    routeName: 'Surat ➔ Vadodara Expressway',
                    speedLabel: '⚡ 88 km/h avg',
                    driverInfo: '8 verified drivers ready · Next in 14 mins',
                    badges: const ['via NH48', 'Zero Toll'],
                    badgeVariants: const [
                      PillTagVariant.neutral,
                      PillTagVariant.mint,
                    ],
                    badgeIcons: const [null, Icons.check_circle_outline_rounded],
                    price: '₹210 / seat',
                    onTap: () {
                      _originController.text = 'Surat';
                      _destinationController.text = 'Vadodara';
                      _handleSearch();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Two-Column Mini Bentos
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 280;

                      final co2Card = BentoContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  size: 22,
                                  color: SahyanColors.primaryMint,
                                ),
                                PillTag(
                                  label: '+24%',
                                  variant: PillTagVariant.mint,
                                  fontSize: 10,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '14.2 kg',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: SahyanColors.textMain,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'CO₂ Offset This Month',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SahyanColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );

                      final surgeCard = BentoContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.trending_down_rounded,
                                  size: 22,
                                  color: SahyanColors.goldStar,
                                ),
                                PillTag(
                                  label: 'Off-Peak',
                                  variant: PillTagVariant.gold,
                                  fontSize: 10,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Save 18%',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: SahyanColors.textMain,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Smart Surge Drop Active',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SahyanColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            co2Card,
                            const SizedBox(height: 12),
                            surgeCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: co2Card),
                          const SizedBox(width: 12),
                          Expanded(child: surgeCard),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Telematics status card
                  BentoContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SahyanColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.traffic_rounded,
                            color: SahyanColors.primaryDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zero Congestion Detected',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: SahyanColors.textMain,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'NH47 Limbdi Toll cleared · Smooth transit flow',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: SahyanColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: SahyanColors.textDisabled,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Corridor Bento Card with top/mid/bottom row structure per spec.
class _CorridorBentoCard extends StatelessWidget {
  final String routeName;
  final String speedLabel;
  final String driverInfo;
  final List<String> badges;
  final List<PillTagVariant> badgeVariants;
  final List<IconData?> badgeIcons;
  final String price;
  final VoidCallback onTap;

  const _CorridorBentoCard({
    required this.routeName,
    required this.speedLabel,
    required this.driverInfo,
    required this.badges,
    required this.badgeVariants,
    required this.badgeIcons,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Route name + Speed pill
          Row(
            children: [
              Expanded(
                child: Text(
                  routeName,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.textMain,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SahyanColors.primaryMint.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: SahyanColors.primaryMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      speedLabel,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
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

          const SizedBox(height: 8),

          // Mid Row: Driver info
          Text(
            driverInfo,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: SahyanColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Row: Route badges + Price
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: List.generate(badges.length, (i) {
                    return PillTag(
                      label: badges[i],
                      variant: badgeVariants[i],
                      icon: badgeIcons[i],
                      fontSize: 11,
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: SahyanColors.primaryDark,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pulsating "● Live Telematics" badge with scale animation.
class _PulsatingTelematics extends StatelessWidget {
  final Animation<double> animation;

  const _PulsatingTelematics({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SahyanColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SahyanColors.primaryMint.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsating dot
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Transform.scale(
                scale: animation.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SahyanColors.primaryMint,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          const Text(
            'Live Telematics',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SahyanColors.primaryDark,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
