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
    {'label': 'Luggage Space', 'icon': Icons.luggage_rounded},
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

        // Amenities Card
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

              return FilterChip(
                avatar: isSelected
                    ? const Icon(Icons.check, size: 14, color: Color(0xFF1B4D3E))
                    : Icon(icon, size: 14, color: const Color(0xFF5C6E64)),
                label: Text(label),
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: const Color(0xFFF8FAF8),
                selectedColor: const Color(0xFFE8F5EF),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2EC486) : const Color(0xFFE2E8E4),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1B4D3E) : const Color(0xFF14241C),
                ),
                onSelected: (_) => ref.read(offerRideProvider.notifier).toggleAmenity(label),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Optional Journey Notes
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: TextFormField(
            controller: notesController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF14241C),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              labelText: 'Journey Notes (Optional)',
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C6E64),
              ),
              hintText: 'Add pickup landmark or travel instructions (e.g. Leaving from Iscon circle sharp at 11 PM)...',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF5C6E64),
                height: 1.35,
              ),
            ),
            onChanged: (val) => ref.read(offerRideProvider.notifier).setNotes(val),
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

  Widget _buildBoardingPassSummaryCard(BuildContext context, OfferRideState draft) {
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.alt_route_rounded,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$originName to $destinationName',
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
                  label: 'Distance',
                  value: distanceText,
                ),
                _buildSummaryGridCell(
                  label: 'Est. Duration',
                  value: durationText,
                ),
                _buildSummaryGridCell(
                  label: 'Seats',
                  value: '${draft.availableSeats}',
                ),
                _buildSummaryGridCell(
                  label: 'Price',
                  value: '\u20B9${draft.contributionPerSeat.toStringAsFixed(0)}',
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
                  VehicleIcon.illustration(type: VehicleType.sedan, width: 32, height: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vehicle != null
                        ? '${vehicle.make} ${vehicle.model} (${vehicle.registrationNumber})'
                        : 'Selected Vehicle',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14241C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                  ),
                  child: Text(
                    '${DateFormat('dd MMM').format(draft.departureDate)} ${draft.departureTime.format(context)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4D3E),
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

  Widget _buildPerforatedTicketDivider() {
    return Row(
      children: [
        // Left notch
        Container(
          width: 8,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8F6),
            borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
          ),
        ),
        // Dashed center line
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1,
                    color: const Color(0xFFE2E8E4),
                  );
                }),
              );
            },
          ),
        ),
        // Right notch
        Container(
          width: 8,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8F6),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGridCell({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5C6E64),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF14241C),
            letterSpacing: -0.2,
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
}
