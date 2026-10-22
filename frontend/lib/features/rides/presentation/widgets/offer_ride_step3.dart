import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/shared/widgets/sahyan_3d_vehicle_marker.dart';

class OfferRideStep3 extends ConsumerWidget {
  final TextEditingController notesController;

  const OfferRideStep3({
    super.key,
    required this.notesController,
  });

  static const List<Map<String, dynamic>> allAmenities = [
    {'label': 'AC', 'icon': Icons.ac_unit_rounded},
    {'label': 'Music', 'icon': Icons.music_note_rounded},
    {'label': 'Luggage Space', 'icon': Icons.work_outline_rounded},
    {'label': 'No Smoking', 'icon': Icons.smoke_free_rounded},
    {'label': 'Pets Allowed', 'icon': Icons.pets_rounded},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(offerRideProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Luxury Amenity Filter Chips Header
        _buildSectionHeader(
          'Amenities & Preferences',
          'Highlight features available in your vehicle',
        ),
        const SizedBox(height: 10),

        // Amenities Card with Professional Tactile Capsules
        Container(
          width: double.infinity,
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
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allAmenities.map((amenity) {
              final label = amenity['label'] as String;
              final icon = amenity['icon'] as IconData;
              final isSelected = draft.amenities.contains(label);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      ref.read(offerRideProvider.notifier).toggleAmenity(label),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F5EF)
                          : const Color(0xFFF9FAF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2EC486)
                            : const Color(0xFFE2E8E4),
                        width: isSelected ? 1.4 : 0.8,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2EC486)
                                    .withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : icon,
                          size: 15,
                          color: isSelected
                              ? const Color(0xFF1B4D3E)
                              : const Color(0xFF5C6E64),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1B4D3E)
                                : const Color(0xFF14241C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Optional Journey Notes (Elevated Card)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: Color(0xFF1B4D3E),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Journey Notes (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14241C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    fillColor: Color(0xFFF6F8F6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F6),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                  ),
                  child: TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF14241C),
                      height: 1.35,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                      hintText:
                          'Add pickup landmark or travel instructions (e.g. Leaving from Iscon circle sharp at 11 PM)...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF8A9A90),
                        height: 1.35,
                      ),
                    ),
                    onChanged: (val) =>
                        ref.read(offerRideProvider.notifier).setNotes(val),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 3. Final Journey Summary Card (Boarding Pass Style)
        _buildSectionHeader(
          'Journey Summary',
          'Review the ride details before publishing',
        ),
        const SizedBox(height: 10),

        _buildBoardingPassSummaryCard(context, draft),
      ],
    );
  }

  Widget _buildBoardingPassSummaryCard(
      BuildContext context, OfferRideState draft) {
    final originName = draft.origin?.name ?? 'Ahmedabad';
    final destinationName = draft.destination?.name ?? 'Rajkot';
    final distanceText = draft.route?.distanceMeters != null
        ? '${(draft.route!.distanceMeters / 1000.0).toStringAsFixed(1)} km'
        : (draft.route?.formattedDistance ?? '216.0 km');
    final durationText = draft.route?.formattedDuration ?? '3h 25m';
    final vehicle = draft.selectedVehicle;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Route corridor & Boarding pass banner
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.navigation_rounded,
                      color: Color(0xFF1B4D3E),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$originName \u2794 $destinationName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14241C),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Verified Highway Corridor · Boarding Pass',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5C6E64),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Perforated Ticket Divider with Semicircular Notches
          _buildPerforatedTicketDivider(),

          // 4-Column Details Grid: Distance | Duration | Seats | Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryGridCell(
                  label: 'DISTANCE',
                  value: distanceText,
                ),
                _buildSummaryGridCell(
                  label: 'DURATION',
                  value: durationText,
                ),
                _buildSummaryGridCell(
                  label: 'SEATS',
                  value: '${draft.availableSeats}',
                ),
                _buildSummaryGridCell(
                  label: 'PRICE / SEAT',
                  value:
                      '\u20B9${draft.contributionPerSeat.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),

          // Perforated Ticket Divider
          _buildPerforatedTicketDivider(),

          // Vehicle Badge Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F8F6),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(21)),
            ),
            child: Row(
              children: [
                if (vehicle != null)
                  Sahyan3DVehicleMarker(
                    vehicleTypeCode: vehicle.vehicleType,
                    size: 28,
                    heading: 90,
                    isStopped: false,
                  )
                else
                  VehicleIcon.illustration(
                      type: VehicleType.sedan, width: 32, height: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicle != null
                            ? '${vehicle.make} ${vehicle.model}'
                            : 'Selected Vehicle',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14241C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vehicle != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2EF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vehicle.registrationNumber,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EF),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF2EC486), width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Color(0xFF1B4D3E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('dd MMM').format(draft.departureDate)} ${draft.departureTime.format(context)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
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

  Widget _buildSummaryGridCell({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5C6E64),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF14241C),
          ),
        ),
      ],
    );
  }

  Widget _buildPerforatedTicketDivider() {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed Line Divider
          Positioned(
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(
                32,
                (i) => Expanded(
                  child: Container(
                    height: 1.2,
                    color: i.isEven
                        ? const Color(0xFFE2E8E4)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          // Left Notch Cutout
          Positioned(
            left: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8F6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right Notch Cutout
          Positioned(
            right: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8F6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14241C),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5C6E64),
          ),
        ),
      ],
    );
  }
}
