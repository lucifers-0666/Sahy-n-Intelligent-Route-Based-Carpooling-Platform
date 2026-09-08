import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../core/widgets/sahyan_section_header.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../rides/presentation/rides_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_hub_chips.dart';
import '../widgets/route_corridor_card.dart';
import 'package:sahyan/shared/models/location_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _originController = TextEditingController(
    text: 'Ahmedabad',
  );
  final TextEditingController _destinationController = TextEditingController(
    text: 'Rajkot',
  );

  LocationModel? _originLocation = LocationModel.fromCoordinates(
    name: 'Ahmedabad',
    latitude: 23.0225,
    longitude: 72.5714,
  );
  LocationModel? _destinationLocation = LocationModel.fromCoordinates(
    name: 'Rajkot',
    latitude: 22.3039,
    longitude: 70.8022,
  );

  int _selectedSeats = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  static const List<Map<String, dynamic>> _popularHubs = [
    {'name': 'Bhuj', 'lat': 23.2420, 'lng': 69.6669},
    {'name': 'Anjar', 'lat': 23.1132, 'lng': 70.0278},
    {'name': 'Gandhidham', 'lat': 23.0753, 'lng': 70.1337},
    {'name': 'Ahmedabad', 'lat': 23.0225, 'lng': 72.5714},
    {'name': 'Rajkot', 'lat': 22.3039, 'lng': 70.8022},
    {'name': 'Vadodara', 'lat': 22.3072, 'lng': 73.1812},
    {'name': 'Surat', 'lat': 21.1702, 'lng': 72.8311},
  ];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final tempText = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = tempText;

      final tempLoc = _originLocation;
      _originLocation = _destinationLocation;
      _destinationLocation = tempLoc;
    });
  }

  void _handleSearch() {
    final originText = _originController.text.trim();
    final destText = _destinationController.text.trim();

    if (originText.isEmpty || destText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both origin and destination locations.'),
          backgroundColor: AppColors.mutedRust,
        ),
      );
      return;
    }

    ref.read(rideSearchQueryProvider.notifier).state = RideSearchQuery(
      originLocation: _originLocation,
      destinationLocation: _destinationLocation,
      origin: originText,
      destination: destText,
      date: _selectedDate,
      time: _selectedTime,
      seats: _selectedSeats,
    );

    context.go('/search-results');
  }

  void _selectPopularRoute(String originName, String destName) {
    final originHub = _popularHubs.firstWhere(
      (h) => h['name'] == originName,
      orElse: () => {'name': originName, 'lat': 23.0225, 'lng': 72.5714},
    );
    final destHub = _popularHubs.firstWhere(
      (h) => h['name'] == destName,
      orElse: () => {'name': destName, 'lat': 22.3039, 'lng': 70.8022},
    );

    setState(() {
      _originController.text = originName;
      _destinationController.text = destName;
      _originLocation = LocationModel.fromCoordinates(
        name: originHub['name'] as String,
        latitude: (originHub['lat'] as num).toDouble(),
        longitude: (originHub['lng'] as num).toDouble(),
      );
      _destinationLocation = LocationModel.fromCoordinates(
        name: destHub['name'] as String,
        latitude: (destHub['lat'] as num).toDouble(),
        longitude: (destHub['lng'] as num).toDouble(),
      );
    });

    _handleSearch();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = ref.watch(userModeProvider).isGuest;
    final displayName = isGuest
        ? 'Guest Traveler'
        : (authState.user?.name.split(' ').first ?? 'Member');

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppSpacing.containerMargin,
                right: AppSpacing.containerMargin,
                top: AppSpacing.md,
                bottom:
                    110.0, // Space to avoid floating bottom navigation collision
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Header with User Avatar & Notification Action
                  HomeHeader(
                    displayName: displayName,
                    onNotificationTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Primary Discovery Card: Find a Shared Ride
                  _buildSearchCard(context),
                  const SizedBox(height: AppSpacing.xl),

                  // Popular Routes Section Header
                  SahyanSectionHeader(
                    title: 'Popular Routes in Gujarat',
                    subtitle: 'Frequently travelled verified corridors',
                    actionLabel: 'Explore All',
                    onActionTap: _handleSearch,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Featured Route Corridor Cards
                  RouteCorridorCard(
                    origin: 'Ahmedabad',
                    destination: 'Rajkot',
                    price: 'from ₹350',
                    subtitle: 'NH 47 Express Highway · High frequency',
                    onTap: () => _selectPopularRoute('Ahmedabad', 'Rajkot'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RouteCorridorCard(
                    origin: 'Vadodara',
                    destination: 'Surat',
                    price: 'from ₹280',
                    subtitle: 'Golden Quadrilateral corridor · Direct rides',
                    onTap: () => _selectPopularRoute('Vadodara', 'Surat'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RouteCorridorCard(
                    origin: 'Bhuj',
                    destination: 'Gandhidham',
                    price: 'from ₹150',
                    subtitle:
                        'Kutch Intercity transit · Regular morning departures',
                    onTap: () => _selectPopularRoute('Bhuj', 'Gandhidham'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return SahyanCard(
      padding: AppSpacing.paddingCardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Find a Shared Ride',
                  style: AppTypography.sectionHeader.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softForest,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  'Route Match',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryForest,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),

          // Route Fields with Visual Indicator & Swap Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    SahyanTextField(
                      hint: 'Enter departure city',
                      controller: _originController,
                      prefixIcon: const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primaryForest,
                        size: 20,
                      ),
                      onChanged: (val) {
                        _originLocation = LocationModel.fromCoordinates(
                          name: val,
                          latitude: 23.0225,
                          longitude: 72.5714,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SahyanTextField(
                      hint: 'Enter destination city',
                      controller: _destinationController,
                      prefixIcon: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.mutedBrass,
                        size: 20,
                      ),
                      onChanged: (val) {
                        _destinationLocation = LocationModel.fromCoordinates(
                          name: val,
                          latitude: 22.3039,
                          longitude: 70.8022,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Swap Button
              Material(
                color: AppColors.surfaceContainerLow,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _swapLocations,
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      color: AppColors.primaryForest,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Hub Suggestions (Horizontally Scrollable without clipping)
          QuickHubChips(
            hubs: _popularHubs,
            selectedHub: _originController.text,
            onHubSelected: (hub) {
              setState(() {
                _originController.text = hub['name'] as String;
                _originLocation = LocationModel.fromCoordinates(
                  name: hub['name'] as String,
                  latitude: (hub['lat'] as num).toDouble(),
                  longitude: (hub['lng'] as num).toDouble(),
                );
              });
            },
          ),
          const SizedBox(height: AppSpacing.base),

          // Date, Time, and Seats Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildParameterCapsule(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value:
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            onTap: () => _pickDate(context),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildParameterCapsule(
                            icon: Icons.schedule_rounded,
                            label: 'Time',
                            value: _selectedTime.format(context),
                            onTap: () => _pickTime(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildParameterCapsule(
                      icon: Icons.airline_seat_recline_normal_rounded,
                      label: 'Seats',
                      value:
                          '$_selectedSeats Seat${_selectedSeats > 1 ? 's' : ''}',
                      onTap: _cycleSeats,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildParameterCapsule(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value:
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: () => _pickDate(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildParameterCapsule(
                      icon: Icons.schedule_rounded,
                      label: 'Time',
                      value: _selectedTime.format(context),
                      onTap: () => _pickTime(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildParameterCapsule(
                      icon: Icons.airline_seat_recline_normal_rounded,
                      label: 'Seats',
                      value:
                          '$_selectedSeats Seat${_selectedSeats > 1 ? 's' : ''}',
                      onTap: _cycleSeats,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Primary Search Button
          SahyanButton(
            text: 'Search Rides',
            icon: Icons.search_rounded,
            variant: SahyanButtonVariant.primary,
            size: SahyanButtonSize.regular,
            onPressed: _handleSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCapsule({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryForest),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                    Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.textPrimary,
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
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _cycleSeats() {
    setState(() {
      _selectedSeats = (_selectedSeats % 4) + 1;
    });
  }
}
