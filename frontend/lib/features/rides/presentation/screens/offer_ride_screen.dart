import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/widgets/route_map_preview.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class OfferRideScreen extends ConsumerStatefulWidget {
  const OfferRideScreen({super.key});

  @override
  ConsumerState<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends ConsumerState<OfferRideScreen> {
  int _currentStep = 0;

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _contributionController = TextEditingController(text: '350');
  final _notesController = TextEditingController();

  static const List<Map<String, dynamic>> _popularHubs = [
    {'name': 'Bhuj', 'lat': 23.2420, 'lng': 69.6669},
    {'name': 'Anjar', 'lat': 23.1132, 'lng': 70.0278},
    {'name': 'Gandhidham', 'lat': 23.0753, 'lng': 70.1337},
    {'name': 'Ahmedabad', 'lat': 23.0225, 'lng': 72.5714},
    {'name': 'Rajkot', 'lat': 22.3039, 'lng': 70.8022},
    {'name': 'Vadodara', 'lat': 22.3072, 'lng': 73.1812},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaults();
    });
  }

  void _initializeDefaults() {
    final draft = ref.read(offerRideProvider);
    if (draft.origin != null) {
      _originController.text = draft.origin!.name;
    }
    if (draft.destination != null) {
      _destinationController.text = draft.destination!.name;
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _contributionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectHubAsOrigin(Map<String, dynamic> hub) {
    _originController.text = hub['name'] as String;
    ref
        .read(offerRideProvider.notifier)
        .setOrigin(
          LocationModel.fromCoordinates(
            name: hub['name'] as String,
            latitude: hub['lat'] as double,
            longitude: hub['lng'] as double,
          ),
        );
  }

  void _selectHubAsDestination(Map<String, dynamic> hub) {
    _destinationController.text = hub['name'] as String;
    ref
        .read(offerRideProvider.notifier)
        .setDestination(
          LocationModel.fromCoordinates(
            name: hub['name'] as String,
            latitude: hub['lat'] as double,
            longitude: hub['lng'] as double,
          ),
        );
  }

  Future<void> _pickDepartureDate() async {
    final draft = ref.read(offerRideProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.departureDate.isAfter(now) ? draft.departureDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryForest,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(offerRideProvider.notifier).setDepartureDate(picked);
    }
  }

  Future<void> _pickDepartureTime() async {
    final draft = ref.read(offerRideProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: draft.departureTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryForest,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(offerRideProvider.notifier).setDepartureTime(picked);
    }
  }

  Future<void> _onPublishPressed() async {
    final draft = ref.read(offerRideProvider);
    if (draft.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    try {
      final ride = await ref.read(offerRideProvider.notifier).publishRide();
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2E6B4B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Journey Published',
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.deepForest,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your carpool journey from ${ride.origin.name} to ${ride.destination.name} has been published successfully.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Departure: ${DateFormat('dd MMM yyyy').format(ride.dateTime)} at ${ride.departureTime}',
                style: AppTypography.secondary,
              ),
              Text(
                'Seats: ${ride.availableSeats} | ₹${ride.contributionPerSeat.toStringAsFixed(0)} per seat',
                style: AppTypography.secondary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(offerRideProvider.notifier).reset();
                context.go('/my-bookings');
              },
              child: const Text(
                'View My Rides',
                style: TextStyle(color: AppColors.primaryForest),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(offerRideProvider.notifier).reset();
                context.go('/home');
              },
              child: const Text(
                'Done',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.mutedRust,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(offerRideProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text(
          'Offer a Ride',
          style: AppTypography.screenTitle.copyWith(
            fontSize: 20,
            color: AppColors.deepForest,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (draft.selectedVehicle != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softForest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    draft.selectedVehicle!.registrationNumber,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryForest,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 16),
              if (_currentStep == 0)
                _buildStep1VehicleAndRoute(draft, vehiclesAsync, authState)
              else if (_currentStep == 1)
                _buildStep2ScheduleAndCapacity(draft)
              else
                _buildStep3PreferencesAndReview(draft),
              const SizedBox(height: 24),
              _buildNavigationButtons(draft),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['Vehicle & Route', 'Schedule & Seats', 'Review & Publish'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCurrent = _currentStep == index;
          final isCompleted = _currentStep > index;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? const Color(0xFF2E6B4B)
                        : isCurrent
                        ? AppColors.primaryForest
                        : AppColors.border,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTypography.caption.copyWith(
                              color: isCurrent
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[index],
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.deepForest
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < steps.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.mutedSage,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- Step 1: Vehicle & Route ---
  Widget _buildStep1VehicleAndRoute(
    OfferRideState draft,
    AsyncValue<List<VehicleModel>> vehiclesAsync,
    AuthState authState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          '1. Choose Your Vehicle',
          'Select the vehicle for this journey',
        ),
        const SizedBox(height: 8),
        vehiclesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primaryForest),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mutedRust),
            ),
            child: Text(
              'Failed to load vehicles: $err',
              style: AppTypography.caption,
            ),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_car_outlined,
                      size: 36,
                      color: AppColors.mutedSage,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No vehicles registered yet',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.deepForest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You need an active vehicle to offer a carpool ride.',
                      style: AppTypography.secondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryForest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => context.push('/vehicles/add'),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Add Vehicle',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (draft.selectedVehicle == null && vehicles.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(offerRideProvider.notifier).setVehicle(vehicles.first);
              });
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleModel>(
                  value: draft.selectedVehicle ?? vehicles.first,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryForest,
                  ),
                  items: vehicles.map((v) {
                    return DropdownMenuItem<VehicleModel>(
                      value: v,
                      child: Row(
                        children: [
                          Icon(
                            v.vehicleType.toLowerCase() == 'motorcycle'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${v.make} ${v.model} (${v.registrationNumber})',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softForest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${v.seatCapacity} seats',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(offerRideProvider.notifier).setVehicle(v);
                    }
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // 2. Route Locations
        _buildSectionHeader(
          '2. Journey Route',
          'Specify where your trip begins and ends',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _originController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Origin Location (From)',
                  prefixIcon: const Icon(
                    Icons.trip_origin,
                    color: Color(0xFF2E6B4B),
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) {
                  if (val.trim().isNotEmpty) {
                    ref
                        .read(offerRideProvider.notifier)
                        .setOrigin(
                          LocationModel.fromCoordinates(
                            name: val.trim(),
                            latitude: 23.2420,
                            longitude: 69.6669,
                          ),
                        );
                  }
                },
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularHubs.take(4).map((hub) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(
                          hub['name'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: AppColors.warmBackground,
                        padding: EdgeInsets.zero,
                        onPressed: () => _selectHubAsOrigin(hub),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinationController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Destination Location (To)',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppColors.deepForest,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) {
                  if (val.trim().isNotEmpty) {
                    ref
                        .read(offerRideProvider.notifier)
                        .setDestination(
                          LocationModel.fromCoordinates(
                            name: val.trim(),
                            latitude: 23.0225,
                            longitude: 72.5714,
                          ),
                        );
                  }
                },
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularHubs.reversed.take(4).map((hub) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(
                          hub['name'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: AppColors.warmBackground,
                        padding: EdgeInsets.zero,
                        onPressed: () => _selectHubAsDestination(hub),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (draft.origin != null && draft.destination != null) ...[
          RouteMapPreview(
            origin: draft.origin!,
            destination: draft.destination!,
            route: draft.route,
            isCalculating: draft.isCalculatingRoute,
          ),
        ],
      ],
    );
  }

  // --- Step 2: Schedule & Capacity ---
  Widget _buildStep2ScheduleAndCapacity(OfferRideState draft) {
    final maxSeats = draft.selectedVehicle?.seatCapacity ?? 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Departure Schedule',
          'Select when you are starting the journey',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDepartureDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.primaryForest,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: AppTypography.caption),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(draft.departureDate),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _pickDepartureTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.primaryForest,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time', style: AppTypography.caption),
                          Text(
                            draft.departureTime.format(context),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Seats & Fuel Contribution',
          'Specify spare seats offered and passenger contribution',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Seats',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Vehicle limit: $maxSeats seats',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.primaryForest,
                        ),
                        onPressed: draft.availableSeats > 1
                            ? () => ref
                                  .read(offerRideProvider.notifier)
                                  .setAvailableSeats(draft.availableSeats - 1)
                            : null,
                      ),
                      Text(
                        '${draft.availableSeats}',
                        style: AppTypography.cardTitle,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primaryForest,
                        ),
                        onPressed: draft.availableSeats < maxSeats
                            ? () => ref
                                  .read(offerRideProvider.notifier)
                                  .setAvailableSeats(draft.availableSeats + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contribution Per Seat',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Shared fuel & toll contribution',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _contributionController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 0) {
                          ref
                              .read(offerRideProvider.notifier)
                              .setContribution(parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Pickup Preference',
          'Choose how you will coordinate passenger pickups',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildPickupPolicyTile(
                policy: PickupPolicy.nearby,
                current: draft.pickupPolicy,
                title: 'Nearby Pickup (Recommended)',
                subtitle:
                    'Willing to deviate up to 5 km along route for pickups.',
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildPickupPolicyTile(
                policy: PickupPolicy.exact,
                current: draft.pickupPolicy,
                title: 'Exact Origin Only',
                subtitle:
                    'Passengers must board at your exact starting location.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPolicyTile({
    required PickupPolicy policy,
    required PickupPolicy current,
    required String title,
    required String subtitle,
  }) {
    final isSelected = policy == current;

    return InkWell(
      onTap: () => ref.read(offerRideProvider.notifier).setPickupPolicy(policy),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryForest : AppColors.mutedSage,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Preferences & Review ---
  Widget _buildStep3PreferencesAndReview(OfferRideState draft) {
    const allAmenities = [
      'AC',
      'Music',
      'Luggage Space',
      'No Smoking',
      'Pets Allowed',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Amenities & Preferences',
          'Highlight features available in your vehicle',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allAmenities.map((amenity) {
              final isSelected = draft.amenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                selectedColor: AppColors.softForest,
                checkmarkColor: AppColors.primaryForest,
                labelStyle: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryForest
                      : AppColors.textPrimary,
                ),
                onSelected: (_) =>
                    ref.read(offerRideProvider.notifier).toggleAmenity(amenity),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _notesController,
          maxLines: 2,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Journey Notes (Optional)',
            hintText:
                'e.g. Departing punctually; 1 medium bag per rider allowed.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: AppColors.white,
          ),
          onChanged: (val) =>
              ref.read(offerRideProvider.notifier).setNotes(val),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Journey Summary',
          'Review the ride details before publishing',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryForest, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.route,
                    color: AppColors.primaryForest,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${draft.origin?.name ?? "Origin"} to ${draft.destination?.name ?? "Destination"}',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.deepForest,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    'Distance',
                    draft.route?.formattedDistance ?? '--',
                  ),
                  _buildSummaryItem(
                    'Est. Duration',
                    draft.route?.formattedDuration ?? '--',
                  ),
                  _buildSummaryItem('Seats', '${draft.availableSeats}'),
                  _buildSummaryItem(
                    'Price',
                    '₹${draft.contributionPerSeat.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warmBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 16,
                      color: AppColors.primaryForest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${draft.selectedVehicle?.make ?? ""} ${draft.selectedVehicle?.model ?? ""} (${draft.selectedVehicle?.registrationNumber ?? ""})',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${DateFormat('dd MMM').format(draft.departureDate)} ${draft.departureTime.format(context)}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepForest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.deepForest,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.cardTitle.copyWith(color: AppColors.deepForest),
        ),
        Text(subtitle, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildNavigationButtons(OfferRideState draft) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: () => setState(() => _currentStep--),
              child: Text(
                'Back',
                style: AppTypography.button.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: draft.isSubmitting
                ? null
                : () {
                    if (_currentStep < 2) {
                      if (_currentStep == 0) {
                        if (draft.selectedVehicle == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a vehicle first.'),
                            ),
                          );
                          return;
                        }
                        if (draft.origin == null || draft.destination == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter both origin and destination.',
                              ),
                            ),
                          );
                          return;
                        }
                      }
                      setState(() => _currentStep++);
                    } else {
                      _onPublishPressed();
                    }
                  },
            child: draft.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    _currentStep == 2 ? 'Publish Ride' : 'Continue',
                    style: AppTypography.button,
                  ),
          ),
        ),
      ],
    );
  }
}
