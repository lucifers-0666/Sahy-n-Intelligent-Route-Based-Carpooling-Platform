import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/app_region.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/location/data/providers/geolocator_provider.dart';
import '../../../../core/location/domain/gps_provider.dart';
import '../../../../shared/models/location_model.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../bookings/presentation/bookings_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../rides/presentation/rides_provider.dart';
import '../../../rides/presentation/widgets/location_search_bottom_sheet.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../widgets/hero_search_card.dart';

/// Single-Screen Hybrid UI/UX Redesigned Home Screen for Sahyān.
/// Blends modern smartphone-native mobility ergonomics (JoyRide-inspired clarity)
/// with Sahyān's proprietary converging corridor matching, explainable Route Match Score,
/// contextual journey awareness, and non-commercial P2P cost sharing.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _originController = TextEditingController(
    text: AppRegion.fallbackCity,
  );
  final TextEditingController _destinationController = TextEditingController(
    text: '',
  );

  LocationModel _originLocation = LocationModel.fromCoordinates(
    name: AppRegion.fallbackCity,
    latitude: AppRegion.fallbackLatitude,
    longitude: AppRegion.fallbackLongitude,
  );
  LocationModel _destinationLocation = LocationModel.fromCoordinates(
    name: '',
    latitude: AppRegion.fallbackLatitude,
    longitude: AppRegion.fallbackLongitude,
  );

  int _selectedSeats = 2;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 30);

  // Pulsating dot animation controller
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const List<Map<String, dynamic>> _quickCorridors = [
    {
      'from': 'Ahmedabad',
      'to': 'Vadodara',
      'price': 150,
      'fromLat': 23.0225,
      'fromLng': 72.5714,
      'toLat': 22.3072,
      'toLng': 73.1812,
      'viaHighway': 'NE1',
      'matchScore': 95,
    },
    {
      'from': 'Surat',
      'to': 'Mumbai',
      'price': 380,
      'fromLat': 21.1702,
      'fromLng': 72.8311,
      'toLat': 19.0760,
      'toLng': 72.8777,
      'viaHighway': 'NH48',
      'matchScore': 92,
    },
    {
      'from': 'Gandhinagar',
      'to': 'Ahmedabad',
      'price': 80,
      'fromLat': 23.2156,
      'fromLng': 72.6369,
      'toLat': 23.0225,
      'toLng': 72.5714,
      'viaHighway': 'SG Highway',
      'matchScore': 96,
    },
    {
      'from': 'Rajkot',
      'to': 'Ahmedabad',
      'price': 250,
      'fromLat': 22.3039,
      'fromLng': 70.8022,
      'toLat': 23.0225,
      'toLng': 72.5714,
      'viaHighway': 'NH47',
      'matchScore': 90,
    },
  ];

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!isTest) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final city = user?.city.trim();
      if (city != null && city.isNotEmpty) {
        if (_originController.text.isEmpty ||
            _originController.text == 'Nagpur' ||
            _originController.text == AppRegion.fallbackCity) {
          setState(() {
            _originController.text = city;
            _originLocation = LocationModel.fromCoordinates(
              name: city,
              latitude: AppRegion.fallbackLatitude,
              longitude: AppRegion.fallbackLongitude,
            );
          });
        }
      }
      _loadGrantedUserLocation();
    });
  }

  Future<void> _loadGrantedUserLocation() async {
    final locationProvider = GeolocatorProvider();
    try {
      final permission = await locationProvider.checkPermission();
      if (permission != LocationPermissionStatus.granted ||
          !await locationProvider.isServiceEnabled()) {
        return;
      }

      final point = await locationProvider.getCurrentPosition().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (point == null || !mounted) return;

      setState(() {
        _originLocation = LocationModel.fromCoordinates(
          name: 'Current location',
          latitude: point.latitude,
          longitude: point.longitude,
        );
        _originController.text = _originLocation.name;
      });
    } finally {
      await locationProvider.dispose();
    }
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
        latitude:
            (corridor['fromLat'] as num?)?.toDouble() ??
            AppRegion.fallbackLatitude,
        longitude:
            (corridor['fromLng'] as num?)?.toDouble() ??
            AppRegion.fallbackLongitude,
      );
      _destinationLocation = LocationModel.fromCoordinates(
        name: corridor['to'] as String,
        latitude:
            (corridor['toLat'] as num?)?.toDouble() ??
            AppRegion.fallbackLatitude,
        longitude:
            (corridor['toLng'] as num?)?.toDouble() ??
            AppRegion.fallbackLongitude,
      );
    });
  }

  Future<void> _selectPickupLocation() async {
    final result = await LocationSearchBottomSheet.show(
      context: context,
      title: 'Select Pickup Hub',
      initialQuery: _originController.text,
      isPickup: true,
    );
    if (result != null && mounted) {
      setState(() {
        _originController.text = result.name;
        _originLocation = result;
      });
    }
  }

  Future<void> _selectDestinationLocation() async {
    final result = await LocationSearchBottomSheet.show(
      context: context,
      title: 'Select Destination Hub',
      initialQuery: _destinationController.text,
      isPickup: false,
    );
    if (result != null && mounted) {
      setState(() {
        _destinationController.text = result.name;
        _destinationLocation = result;
      });
    }
  }

  Future<void> _navigateToDateTimeSelection() async {
    final result = await context.push<Map<String, dynamic>>(
      '/travel-date-time',
      extra: {
        'date': _selectedDate,
        'time': _selectedTime,
      },
    );
    if (result != null && mounted) {
      final pickedDate = result['date'] as DateTime?;
      final pickedTime = result['time'] as TimeOfDay?;
      if (pickedDate != null && pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  Future<void> _navigateToPassengerSelection() async {
    final result = await context.push<int>(
      '/passenger-selection',
      extra: _selectedSeats,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedSeats = result;
      });
    }
  }


  void _handleSearch() {
    HapticFeedback.mediumImpact();
    final originText = _originController.text.trim();
    final destText = _destinationController.text.trim();

    if (originText.isEmpty || destText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please specify both origin and destination corridors.',
          ),
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

    final activeOrigin = _originLocation.name == originText
        ? _originLocation
        : LocationModel.fromCoordinates(
            name: originText,
            latitude: _originLocation.latitude,
            longitude: _originLocation.longitude,
          );
    final activeDest = _destinationLocation.name == destText
        ? _destinationLocation
        : LocationModel.fromCoordinates(
            name: destText,
            latitude: _destinationLocation.latitude,
            longitude: _destinationLocation.longitude,
          );

    ref.read(rideSearchQueryProvider.notifier).state = RideSearchQuery(
      origin: originText,
      destination: destText,
      originLocation: activeOrigin,
      destinationLocation: activeDest,
      date: depDate,
      time: _selectedTime,
      seats: _selectedSeats,
    );

    context.push('/search-results');
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getTimeSubtitle() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 7) {
      return 'Early morning start · Smooth Gujarat highways await';
    }
    if (hour >= 7 && hour < 12) {
      return 'Ready for your morning corridor commute?';
    }
    if (hour >= 12 && hour < 17) {
      return 'Midday travels made seamless, shared, and green';
    }
    if (hour >= 17 && hour < 21) {
      return 'Heading back home? Find verified rides on your route';
    }
    return 'Late commute? Safe travels with verified co-passengers';
  }

  String _getActiveCity(UserModel? user) {
    if (_originLocation.city.isNotEmpty && _originLocation.city != 'Nagpur') {
      return _originLocation.city;
    }
    if (_originLocation.name.isNotEmpty &&
        _originLocation.name != 'Current location' &&
        _originLocation.name != 'Nagpur') {
      if (_originLocation.name.contains(',')) {
        return _originLocation.name.split(',').last.trim();
      }
      return _originLocation.name;
    }
    if (user != null && user.city.trim().isNotEmpty) {
      return user.city.trim();
    }
    return AppRegion.fallbackCity;
  }

  Widget _buildRoleSelectorPill(UserModel? user) {
    final modeState = ref.watch(userModeProvider);
    final isDriver = modeState.isDriverMode;
    final isDriverEligible = user?.isDriverEligible ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Passenger Mode Segment
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(userModeProvider.notifier)
                      .setOperationalMode(OperationalMode.rider);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: !isDriver
                        ? AppColors.primaryForest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 16,
                          color: !isDriver
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Take a Ride',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            fontWeight: !isDriver
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: !isDriver
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Driver Mode Segment
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isDriverEligible) {
                    ref
                        .read(userModeProvider.notifier)
                        .setOperationalMode(OperationalMode.driver);
                    context.push('/offer-ride');
                  } else {
                    context.push('/driver-onboarding');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isDriver
                        ? AppColors.primaryForest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 16,
                          color: isDriver
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDriverEligible ? 'Offer a Ride' : 'Become a Host',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            fontWeight: isDriver
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isDriver
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final unreadNotifs = ref.watch(notificationsProvider).unreadCount;
    final displayName = user?.name.split(' ').first ?? 'Traveler';
    final corridorsAsync = ref.watch(corridorsProvider);
    final quickCorridors = corridorsAsync.value ?? _quickCorridors;

    // Proactive Contextual Trip Awareness
    final bookingsAsync = ref.watch(bookingsNotifierProvider);
    final myRidesAsync = ref.watch(myRidesProvider);

    BookingModel? activeBooking;
    bookingsAsync.whenData((bookings) {
      for (final b in bookings) {
        if (b.status == BookingStatus.accepted ||
            b.status == BookingStatus.pending) {
          activeBooking = b;
          break;
        }
      }
    });

    RideModel? activeDriverRide;
    if (activeBooking == null) {
      myRidesAsync.whenData((rides) {
        for (final r in rides) {
          if (r.status == RideStatus.scheduled ||
              r.status == RideStatus.active) {
            activeDriverRide = r;
            break;
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ──────────────────────────────────────────────────────────────
            // 1. Editorial Smartphone-Native Header Bar
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Brand tag + Time Greeting + Location pill
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand tag: SAHYAN
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.deepEmerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'SAHYAN',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepEmerald,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Dynamic Greeting
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_getTimeGreeting()}, $displayName',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Contextual subtitle with warmth and uniqueness
                          Text(
                            _getTimeSubtitle(),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedText,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Active Regional Transit Hub Pill
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _selectPickupLocation,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.softMint.withValues(
                                        alpha: 0.6,
                                      ),
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
                                          color: AppColors.softMint,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: AppColors.deepEmerald,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getActiveCity(user),
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.deepEmerald,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 13,
                                        color: AppColors.deepEmerald,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Notification Bell + Profile Avatar
                    Row(
                      children: [
                        // Notification Bell
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: AppColors.white,
                              shape: const CircleBorder(
                                side: BorderSide(
                                  color: AppColors.border,
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
                                      color: AppColors.primaryText,
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
                                    color: AppColors.deepEmerald,
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
                                      color: Colors.white,
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

                        // User Avatar with Verified Badge
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.softMint,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepEmerald,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: AppColors.deepEmerald,
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
            // 1b. Role Mode Switcher Pill (Take a Ride / Offer a Ride)
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _buildRoleSelectorPill(user),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // 2. Contextual Active Trip Card (If user has upcoming booking/ride)
            // ──────────────────────────────────────────────────────────────
            if (activeBooking != null || activeDriverRide != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _ActiveJourneyCard(
                    booking: activeBooking,
                    driverRide: activeDriverRide,
                    onTap: () {
                      if (activeBooking != null) {
                        context.push('/bookings');
                      } else {
                        context.push('/offer-ride');
                      }
                    },
                  ),
                ),
              ),

            // ──────────────────────────────────────────────────────────────
            // 3. Hero Route-Search Bento Module
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
                  onPickDateTime: _navigateToDateTimeSelection,
                  onOpenDateTime: _navigateToDateTimeSelection,
                  selectedSeats: _selectedSeats,
                  onSeatsChanged: (val) => setState(() => _selectedSeats = val),
                  onOpenPassengers: _navigateToPassengerSelection,
                  onSearch: _handleSearch,
                  popularCorridors: quickCorridors,
                  onTapPickup: _selectPickupLocation,
                  onTapDestination: _selectDestinationLocation,
                  onOriginLocationSelected: (loc) =>
                      setState(() => _originLocation = loc),
                  onDestinationLocationSelected: (loc) =>
                      setState(() => _destinationLocation = loc),
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // 4. Quick Action Shortcuts (Mobility Ergonomics)
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.add_road_rounded,
                        label: 'Offer Ride',
                        caption: 'Publish route',
                        onTap: () => context.push('/offer-ride'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.confirmation_number_outlined,
                        label: 'My Bookings',
                        caption: 'Active passes',
                        onTap: () => context.push('/bookings'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.shield_outlined,
                        label: 'Safety Center',
                        caption: '24/7 SOS desk',
                        onTap: () => context.push('/safety-center'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // 5. Section Header: Popular Highway Corridors
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Popular Highway Corridors',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PulsatingTelematics(animation: _pulseAnimation),
                  ],
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────────
            // 6. Intelligent Route Corridor Cards & Trust Banner
            // ──────────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Corridor 1: Ahmedabad -> Vadodara
                  _CorridorBentoCard(
                    routeName:
                        '${quickCorridors.isNotEmpty ? quickCorridors[0]['from'] : 'Ahmedabad'} → ${quickCorridors.isNotEmpty ? quickCorridors[0]['to'] : 'Vadodara'} Express',
                    speedLabel: 'Expressway Corridor',
                    driverInfo: 'Regular daily commuter route',
                    matchScoreText: '95% Corridor Match',
                    badges: [
                      'via ${quickCorridors.isNotEmpty ? quickCorridors[0]['viaHighway'] ?? 'NE1' : 'NE1'}',
                      'Direct Transit',
                    ],
                    badgeVariants: const [
                      PillTagVariant.neutral,
                      PillTagVariant.mint,
                    ],
                    badgeIcons: const [null, Icons.alt_route_rounded],
                    price:
                        '₹${quickCorridors.isNotEmpty ? quickCorridors[0]['price'] : 150} / seat',
                    onTap: () {
                      _originController.text = quickCorridors.isNotEmpty
                          ? quickCorridors[0]['from']
                          : 'Ahmedabad';
                      _destinationController.text = quickCorridors.isNotEmpty
                          ? quickCorridors[0]['to']
                          : 'Vadodara';
                      _handleSearch();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Corridor 2: Surat -> Mumbai
                  _CorridorBentoCard(
                    routeName:
                        '${quickCorridors.length > 1 ? quickCorridors[1]['from'] : 'Surat'} → ${quickCorridors.length > 1 ? quickCorridors[1]['to'] : 'Mumbai'} Highway',
                    speedLabel: 'Direct Route',
                    driverInfo: 'Interstate carpool corridor',
                    matchScoreText: '92% Corridor Match',
                    badges: [
                      'via ${quickCorridors.length > 1 ? quickCorridors[1]['viaHighway'] ?? 'NH48' : 'NH48'}',
                      'Verified Hosts',
                    ],
                    badgeVariants: const [
                      PillTagVariant.neutral,
                      PillTagVariant.mint,
                    ],
                    badgeIcons: const [
                      null,
                      Icons.check_circle_outline_rounded,
                    ],
                    price:
                        '₹${quickCorridors.length > 1 ? quickCorridors[1]['price'] : 380} / seat',
                    onTap: () {
                      _originController.text = quickCorridors.length > 1
                          ? quickCorridors[1]['from']
                          : 'Surat';
                      _destinationController.text = quickCorridors.length > 1
                          ? quickCorridors[1]['to']
                          : 'Mumbai';
                      _handleSearch();
                    },
                  ),

                  const SizedBox(height: 14),

                  // 7. Verified Platform Community Trust Card (No fake statistics)
                  BentoContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.white,
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 0.8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.deepEmerald,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Carpool Community',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Government ID verification, vehicle registration validation, and 4-digit boarding security on every planned journey.',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 8. Highway Transit Flow Card
                  BentoContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.white,
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 0.8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.traffic_rounded,
                            color: AppColors.deepEmerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Standard Corridor Flow',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Direct intercity highway routing · Co-travel verified',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 9. Non-Commercial P2P Compliance Disclaimer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.mutedText,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sahyān is a non-commercial peer-to-peer carpooling platform. All amounts indicate passenger fuel and toll cost-sharing only.',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: AppColors.mutedText,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
// Subordinate Modular Components
// ─────────────────────────────────────────────────────────────────────────────

/// Contextual Active Journey Card anchored when a ride or booking exists
class _ActiveJourneyCard extends StatelessWidget {
  final BookingModel? booking;
  final RideModel? driverRide;
  final VoidCallback onTap;

  const _ActiveJourneyCard({
    this.booking,
    this.driverRide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDriver = driverRide != null;
    final title = isDriver ? 'Your Published Ride' : 'Upcoming Booked Ride';
    final origin = isDriver
        ? driverRide!.origin.city.isNotEmpty
              ? driverRide!.origin.city
              : driverRide!.origin.name
        : booking!.pickup.name;
    final dest = isDriver
        ? driverRide!.destination.city.isNotEmpty
              ? driverRide!.destination.city
              : driverRide!.destination.name
        : booking!.drop.name;
    final statusText = isDriver
        ? 'Active Route'
        : (booking!.status == BookingStatus.accepted ? 'Confirmed' : 'Pending');

    return BentoContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppColors.softMint.withValues(alpha: 0.6),
        width: 0.8,
      ),
      color: AppColors.lightSurface,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.deepEmerald,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.softMint,
              size: 22,
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
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEmerald,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$origin → $dest',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.deepEmerald,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Tactile Quick Action Tile with micro-press scale feedback
class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: BentoContainer(
          onTap: widget.onTap,
          color: AppColors.white,
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: AppColors.deepEmerald,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                widget.caption,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Corridor Bento Card with Explainable Route Match Score badge
class _CorridorBentoCard extends StatelessWidget {
  final String routeName;
  final String speedLabel;
  final String driverInfo;
  final String matchScoreText;
  final List<String> badges;
  final List<PillTagVariant> badgeVariants;
  final List<IconData?> badgeIcons;
  final String price;
  final VoidCallback onTap;

  const _CorridorBentoCard({
    required this.routeName,
    required this.speedLabel,
    required this.driverInfo,
    this.matchScoreText = '94% Corridor Match',
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
      color: AppColors.white,
      borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Route name + Speed pill
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                routeName,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.softMint.withValues(alpha: 0.5),
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
                        color: AppColors.deepEmerald,
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
                        color: AppColors.deepEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Mid Row: Driver info & Match Score
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                driverInfo,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  matchScoreText,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEmerald,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Row: Badges + Price
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
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
              Text(
                price,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepEmerald,
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

/// Pulsating Live Telematics badge with scale animation
class _PulsatingTelematics extends StatelessWidget {
  final Animation<double> animation;

  const _PulsatingTelematics({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.softMint.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Transform.scale(
                scale: animation.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.deepEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          const Text(
            'Active Corridors',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEmerald,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

