import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/rides/domain/services/route_geometry_service.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/shared/widgets/full_screen_route_map_sheet.dart';
import 'package:sahyan/shared/widgets/sahyan_route_map.dart';
import 'package:sahyan/shared/widgets/sahyan_3d_vehicle_marker.dart';

class OfferRideStep1 extends ConsumerWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onSelectOrigin;
  final VoidCallback onSelectDestination;
  final VoidCallback onAddStopover;
  final Function(Map<String, dynamic> originHub, Map<String, dynamic> destHub)? onSelectCorridor;

  const OfferRideStep1({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.onSelectOrigin,
    required this.onSelectDestination,
    required this.onAddStopover,
    this.onSelectCorridor,
  });

  static const List<Map<String, dynamic>> popularHubs = [
    {'name': 'Bhuj', 'lat': 23.2420, 'lng': 69.6669},
    {'name': 'Anjar', 'lat': 23.1132, 'lng': 70.0278},
    {'name': 'Gandhidham', 'lat': 23.0753, 'lng': 70.1337},
    {'name': 'Ahmedabad', 'lat': 23.0225, 'lng': 72.5714},
    {'name': 'Rajkot', 'lat': 22.3039, 'lng': 70.8022},
    {'name': 'Vadodara', 'lat': 22.3072, 'lng': 73.1812},
    {'name': 'Surat', 'lat': 21.1702, 'lng': 72.8311},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(offerRideProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Vehicle Garage Selector Header
        _buildSectionHeader(
          '1. Choose Your Vehicle',
          'Select the vehicle for this journey',
        ),
        const SizedBox(height: 10),

        // Vehicle Selector Card
        if (!authState.isAuthenticated)
          _buildSignInRequiredCard(context)
        else if (authState.user != null && !authState.user!.isDriverEligible)
          _buildDriverEligibilityGate(context, authState.user!)
        else
          vehiclesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
              ),
            ),
            error: (err, _) => _buildVehicleErrorCard(ref),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return _buildEmptyVehiclesCard(context);
              }
              if (draft.selectedVehicle == null && vehicles.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(offerRideProvider.notifier).setVehicle(vehicles.first);
                });
              }
              final selected = draft.selectedVehicle ?? vehicles.first;
              return _buildVehicleElevatedBento(context, ref, selected, vehicles);
            },
          ),
        const SizedBox(height: 22),

        // 2. Journey Route Header
        _buildSectionHeader(
          '2. Journey Route',
          'Specify where your trip begins and ends',
        ),
        const SizedBox(height: 10),

        // Unified Transit Route Rail (Apple Maps / Uber Style)
        _buildTransitRouteRailCard(context, ref, draft),
        const SizedBox(height: 12),

        // Frequent Corridor Quick Chips (Horizontal Scroll Only)
        _buildFrequentCorridorsScroll(ref),
        const SizedBox(height: 16),

        // Integrated Route Mini-Map Card
        if (draft.origin != null && draft.destination != null) ...[
          _buildRouteTelemetryPill(draft),
          const SizedBox(height: 10),
          _buildIntegratedMiniMapCard(context, draft),
        ],
      ],
    );
  }

  // --- 1. Vehicle Elevated Bento Card ---
  Widget _buildVehicleElevatedBento(
    BuildContext context,
    WidgetRef ref,
    VehicleModel selected,
    List<VehicleModel> vehicles,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: vehicles.length > 1
              ? () => _showVehiclePickerModal(context, ref, vehicles, selected)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Left 3D Vector Vehicle Icon
                Container(
                  width: 52,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                  ),
                  child: Center(
                    child: Sahyan3DVehicleMarker(
                      vehicleTypeCode: selected.vehicleType,
                      heading: 90,
                      size: 36,
                      isStopped: false,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Vehicle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selected.make} ${selected.model}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14241C),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2EF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            selected.registrationNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Capacity Badge & Switch Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selected.seatCapacity} seats',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                    ),
                    if (vehicles.length > 1) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF1B4D3E),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVehiclePickerModal(
    BuildContext context,
    WidgetRef ref,
    List<VehicleModel> vehicles,
    VehicleModel current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8E4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Vehicle for Journey',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF14241C),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8E4)),
                    itemBuilder: (context, idx) {
                      final v = vehicles[idx];
                      final isSelected = v.id == current.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: VehicleIcon.illustration(type: v.type, width: 36, height: 22),
                        title: Text(
                          '${v.make} ${v.model}',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF14241C),
                          ),
                        ),
                        subtitle: Text(
                          '${v.registrationNumber} · ${v.seatCapacity} Seats',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5C6E64)),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B4D3E))
                            : null,
                        onTap: () {
                          ref.read(offerRideProvider.notifier).setVehicle(v);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 2. Unified Transit Route Rail Card ---
  Widget _buildTransitRouteRailCard(
    BuildContext context,
    WidgetRef ref,
    OfferRideState draft,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Vertical Transit Rail
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 14),
            child: Column(
              children: [
                // Origin Dot (Solid Pine #1B4D3E)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Connecting Dashed Mint Line
                Container(
                  width: 2.2,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EC486).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                if (draft.stopovers.isNotEmpty) ...[
                  // Stopover Dot (Amber #E5A93C)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A93C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                  Container(
                    width: 2.2,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC486).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
                // Destination Location Pin (Mint #2EC486)
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF2EC486),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Inputs & Waypoints
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin Input
                InkWell(
                  onTap: onSelectOrigin,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: originController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF14241C),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              labelText: 'Origin Location (From)',
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5C6E64),
                                fontWeight: FontWeight.w500,
                              ),
                              hintText: 'Search pickup point or current GPS',
                              hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF5C6E64)),
                            ),
                            onChanged: (val) {
                              if (val.trim().isNotEmpty) {
                                ref.read(offerRideProvider.notifier).setOrigin(
                                      LocationModel.fromCoordinates(
                                        name: val.trim(),
                                        latitude: 23.2420,
                                        longitude: 69.6669,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF1B4D3E)),
                          tooltip: 'Search Places Autocomplete',
                          onPressed: onSelectOrigin,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Center Divider: Hairline 0.8px with inline "Add Stopover / Toll" text button
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE2E8E4), height: 1)),
                    Flexible(
                      child: InkWell(
                        onTap: onAddStopover,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  size: 13,
                                  color: Color(0xFF1B4D3E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  draft.stopovers.isEmpty
                                      ? 'Add Stopover / Toll'
                                      : 'Add Stopover (${draft.stopovers.length}/3)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE2E8E4), height: 1)),
                  ],
                ),

                // Stopovers List if present
                if (draft.stopovers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(draft.stopovers.length, (idx) {
                      final stop = draft.stopovers[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5A93C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Stop ${idx + 1}: ${stop.name}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF14241C),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => ref.read(offerRideProvider.notifier).removeStopover(idx),
                              child: const Icon(Icons.close, size: 14, color: Color(0xFF5C6E64)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 8),

                // Destination Input
                InkWell(
                  onTap: onSelectDestination,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: destinationController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF14241C),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              labelText: 'Destination Location (To)',
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5C6E64),
                                fontWeight: FontWeight.w500,
                              ),
                              hintText: 'Search dropoff city or hub',
                              hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF5C6E64)),
                            ),
                            onChanged: (val) {
                              if (val.trim().isNotEmpty) {
                                ref.read(offerRideProvider.notifier).setDestination(
                                      LocationModel.fromCoordinates(
                                        name: val.trim(),
                                        latitude: 23.0225,
                                        longitude: 72.5714,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF1B4D3E)),
                          tooltip: 'Search Places Autocomplete',
                          onPressed: onSelectDestination,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Frequent Corridor Quick Chips (Horizontal Scroll Only) ---
  Widget _buildFrequentCorridorsScroll(WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Current GPS Pill
          ActionChip(
            avatar: const Icon(
              Icons.my_location_rounded,
              size: 14,
              color: Color(0xFF1B4D3E),
            ),
            label: const Text(
              'Use GPS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
            backgroundColor: const Color(0xFFE8F5EF),
            side: const BorderSide(color: Color(0xFFE2E8E4), width: 0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onPressed: onSelectOrigin,
          ),
          const SizedBox(width: 8),

          // Major Highway Corridor Quick Capsules
          _buildCorridorCapsule(
            ref,
            from: 'Bhuj',
            to: 'Ahmedabad',
            display: 'Bhuj \u2794 Ahmd',
          ),
          const SizedBox(width: 8),
          _buildCorridorCapsule(
            ref,
            from: 'Rajkot',
            to: 'Surat',
            display: 'Rajkot \u2794 Surat',
          ),
          const SizedBox(width: 8),
          _buildCorridorCapsule(
            ref,
            from: 'Vadodara',
            to: 'Ahmedabad',
            display: 'Vadodara \u2794 Ahmd',
          ),
          const SizedBox(width: 8),
          _buildCorridorCapsule(
            ref,
            from: 'Ahmedabad',
            to: 'Rajkot',
            display: 'Ahmd \u2794 Rajkot',
          ),
          const SizedBox(width: 8),

          // Individual Hub Chips for instant single-hub selection & test compatibility
          ...popularHubs.map((hub) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(
                  hub['name'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14241C),
                  ),
                ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8E4), width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                onPressed: () {
                  if (originController.text.isEmpty) {
                    originController.text = hub['name'] as String;
                    ref.read(offerRideProvider.notifier).setOrigin(
                          LocationModel.fromCoordinates(
                            name: hub['name'] as String,
                            latitude: hub['lat'] as double,
                            longitude: hub['lng'] as double,
                          ),
                        );
                  } else {
                    destinationController.text = hub['name'] as String;
                    ref.read(offerRideProvider.notifier).setDestination(
                          LocationModel.fromCoordinates(
                            name: hub['name'] as String,
                            latitude: hub['lat'] as double,
                            longitude: hub['lng'] as double,
                          ),
                        );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCorridorCapsule(
    WidgetRef ref, {
    required String from,
    required String to,
    required String display,
  }) {
    return ActionChip(
      label: Text(
        display,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B4D3E),
        ),
      ),
      backgroundColor: const Color(0xFFF6F8F6),
      side: const BorderSide(color: Color(0xFFE2E8E4), width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () {
        final originHub = popularHubs.firstWhere(
          (h) => h['name'] == from,
          orElse: () => popularHubs[3],
        );
        final destHub = popularHubs.firstWhere(
          (h) => h['name'] == to,
          orElse: () => popularHubs[4],
        );

        originController.text = originHub['name'] as String;
        destinationController.text = destHub['name'] as String;

        ref.read(offerRideProvider.notifier).setOrigin(
              LocationModel.fromCoordinates(
                name: originHub['name'] as String,
                latitude: originHub['lat'] as double,
                longitude: originHub['lng'] as double,
              ),
            );
        ref.read(offerRideProvider.notifier).setDestination(
              LocationModel.fromCoordinates(
                name: destHub['name'] as String,
                latitude: destHub['lat'] as double,
                longitude: destHub['lng'] as double,
              ),
            );
      },
    );
  }

  // --- 4. Integrated Route Mini-Map Card ---
  Widget _buildIntegratedMiniMapCard(BuildContext context, OfferRideState draft) {
    final corridor = RouteGeometryService.getHighwayCorridor(
      draft.origin!,
      draft.destination!,
    );
    final distanceKm = draft.route != null
        ? (draft.route!.distanceMeters / 1000).toStringAsFixed(0)
        : '216';
    final durationSec = draft.route?.durationSeconds ?? 12300;
    final hours = durationSec ~/ 3600;
    final minutes = (durationSec % 3600) ~/ 60;
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    final pts = draft.route != null && draft.route!.encodedPolyline.isNotEmpty
        ? RouteService.decodePolyline(draft.route!.encodedPolyline)
            .map((pt) => LatLng(pt.latitude, pt.longitude))
            .toList()
        : const <LatLng>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              // Real High-Density Route Map
              SahyanRouteMap(
                origin: draft.origin!,
                destination: draft.destination!,
                polylinePoints: pts,
                stopovers: draft.stopovers,
                vehicleTypeCode: draft.selectedVehicle?.vehicleType,
                interactive: false,
                showControls: false,
                bounds: pts.isNotEmpty
                    ? RouteGeometryService.calculateBounds(pts)
                    : null,
              ),

              // Floating Badge Top-Left: via NH47 · 216 km · 3h 25m
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2EC486), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 13,
                        color: Color(0xFF2EC486),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$corridor · $distanceKm km · $durationText',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Button Top-Right: [ ⤢ Expand Map ]
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      FullScreenRouteMapSheet.show(
                        context: context,
                        origin: draft.origin!,
                        destination: draft.destination!,
                        polylinePoints: pts,
                        stopovers: draft.stopovers,
                        corridorHighway: corridor,
                        vehicleTypeCode: draft.selectedVehicle?.vehicleType,
                        distanceKm: draft.route?.distanceMeters != null
                            ? (draft.route!.distanceMeters / 1000.0)
                            : null,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_full_rounded,
                            size: 12,
                            color: Color(0xFF1B4D3E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Expand Map',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                            ),
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
      ),
    );
  }

  Widget _buildRouteTelemetryPill(OfferRideState draft) {
    if (draft.isCalculatingRoute) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8E4)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1B4D3E),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Computing highway route corridor & telemetry...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // --- Helpers & Guards ---
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF14241C),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5C6E64),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInRequiredCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFF1B4D3E)),
          const SizedBox(height: 8),
          const Text(
            'Sign In Required',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF14241C)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in or register to select your registered vehicle and publish rides.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF5C6E64)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
            label: const Text('Sign In to Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehiclesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_car_outlined, size: 36, color: Color(0xFF5C6E64)),
          const SizedBox(height: 8),
          const Text(
            'No vehicles registered yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF14241C)),
          ),
          const SizedBox(height: 4),
          const Text(
            'You need an active vehicle to offer a carpool ride.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF5C6E64)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => context.push('/vehicles/add'),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleErrorCard(WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Unable to load vehicles. Please verify your network connection.',
            style: TextStyle(fontSize: 12, color: Color(0xFFE11D48)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => ref.read(vehiclesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF1B4D3E)),
            label: const Text('Retry', style: TextStyle(color: Color(0xFF1B4D3E))),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverEligibilityGate(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFC2410C), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Application Under Review',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                    ),
                    Text(
                      'Licence verification in progress',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFC2410C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your driving licence documentation is currently being reviewed. Ride publishing unlocks automatically upon approval.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF7C2D12), height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.push('/driver-onboarding'),
              child: const Text('Check Application Status'),
            ),
          ),
        ],
      ),
    );
  }
}
