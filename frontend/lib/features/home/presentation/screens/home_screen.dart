import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../rides/presentation/rides_provider.dart';

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
  ];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
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

    context.push('/search-results');
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.softForest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primaryForest,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sahyān',
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.deepForest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.deepForest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Namaste, $displayName',
                              style: AppTypography.screenTitle.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Where are you travelling today?',
                              style: AppTypography.secondary.copyWith(
                                color: AppColors.softForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Search Card Form
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find a Shared Ride',
                          style: AppTypography.sectionHeader,
                        ),
                        const SizedBox(height: 16),

                        // Pickup
                        AppTextField(
                          label: 'Pickup City / Landmark',
                          hint: 'Enter origin city',
                          controller: _originController,
                          prefixIcon: const Icon(
                            Icons.my_location,
                            color: AppColors.primaryForest,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _popularHubs.map((hub) {
                              final isSelected =
                                  _originController.text == hub['name'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(
                                    hub['name'] as String,
                                    style: AppTypography.caption,
                                  ),
                                  backgroundColor: isSelected
                                      ? AppColors.softForest
                                      : AppColors.white,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryForest
                                        : AppColors.border,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      _originController.text =
                                          hub['name'] as String;
                                      _originLocation =
                                          LocationModel.fromCoordinates(
                                            name: hub['name'] as String,
                                            latitude: (hub['lat'] as num)
                                                .toDouble(),
                                            longitude: (hub['lng'] as num)
                                                .toDouble(),
                                          );
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Destination
                        AppTextField(
                          label: 'Drop Location',
                          hint: 'Enter destination city',
                          controller: _destinationController,
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: AppColors.mutedSage,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _popularHubs.map((hub) {
                              final isSelected =
                                  _destinationController.text == hub['name'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(
                                    hub['name'] as String,
                                    style: AppTypography.caption,
                                  ),
                                  backgroundColor: isSelected
                                      ? AppColors.softForest
                                      : AppColors.white,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryForest
                                        : AppColors.border,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      _destinationController.text =
                                          hub['name'] as String;
                                      _destinationLocation =
                                          LocationModel.fromCoordinates(
                                            name: hub['name'] as String,
                                            latitude: (hub['lat'] as num)
                                                .toDouble(),
                                            longitude: (hub['lng'] as num)
                                                .toDouble(),
                                          );
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date, Time & Seats selector
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 420) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDatePicker(context),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildTimePicker(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildSeatsPicker(context),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: _buildDatePicker(context)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildTimePicker(context)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildSeatsPicker(context)),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        PrimaryButton(
                          text: 'Search Rides',
                          icon: Icons.search_rounded,
                          onPressed: _handleSearch,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Popular Routes in Gujarat',
                  style: AppTypography.sectionHeader,
                ),
                const SizedBox(height: 12),

                // Quick Route Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      _buildQuickRouteChip('Ahmedabad → Rajkot', '₹350'),
                      const SizedBox(width: 10),
                      _buildQuickRouteChip('Vadodara → Surat', '₹280'),
                      const SizedBox(width: 10),
                      _buildQuickRouteChip('Gandhinagar → Bhavnagar', '₹400'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Date', style: AppTypography.caption),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Time', style: AppTypography.caption),
                  Text(
                    _selectedTime.format(context),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
    );
  }

  Widget _buildSeatsPicker(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedSeats = (_selectedSeats % 4) + 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.airline_seat_recline_normal_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Seats', style: AppTypography.caption),
                  Text(
                    '$_selectedSeats Seat${_selectedSeats > 1 ? 's' : ''}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
    );
  }

  Widget _buildQuickRouteChip(String route, String price) {
    return ActionChip(
      backgroundColor: AppColors.white,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            route,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryForest,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onPressed: () {
        final parts = route.split(' → ');
        final originName = parts.first;
        final destName = parts.last;
        _originController.text = originName;
        _destinationController.text = destName;
        final originHub = _popularHubs.firstWhere(
          (h) => h['name'] == originName,
          orElse: () => {'name': originName, 'lat': 23.0225, 'lng': 72.5714},
        );
        final destHub = _popularHubs.firstWhere(
          (h) => h['name'] == destName,
          orElse: () => {'name': destName, 'lat': 22.3039, 'lng': 70.8022},
        );
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
        _handleSearch();
      },
    );
  }
}
