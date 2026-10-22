import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class OfferRideStep2 extends ConsumerStatefulWidget {
  final TextEditingController contributionController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const OfferRideStep2({
    super.key,
    required this.contributionController,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  ConsumerState<OfferRideStep2> createState() => _OfferRideStep2State();
}

class _OfferRideStep2State extends ConsumerState<OfferRideStep2> {
  bool _middleSeatComfort = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(offerRideProvider);
    final maxSeats = draft.selectedVehicle?.seatCapacity ?? 4;
    final totalRecovery = (draft.availableSeats * draft.contributionPerSeat).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Departure Schedule Section Header
        _buildSectionHeader(
          'Departure Schedule',
          'Select when you are starting the journey',
        ),
        const SizedBox(height: 10),

        // Schedule Bento Container (Balanced Dual-Cell Row)
        Container(
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
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left Cell (Date Picker)
                Expanded(
                  child: InkWell(
                    onTap: widget.onPickDate,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C6E64),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  DateFormat('dd MMM yyyy').format(draft.departureDate),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF14241C),
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
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 48,
                  color: const Color(0xFFE2E8E4),
                ),

                // Right Cell (Time Picker)
                Expanded(
                  child: InkWell(
                    onTap: widget.onPickTime,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C6E64),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  draft.departureTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF14241C),
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
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        // 2. Seats & Fair Contribution Section Header
        _buildSectionHeader(
          'Seats & Fuel Contribution',
          'Specify spare seats offered and passenger contribution',
        ),
        const SizedBox(height: 10),

        // Elevated Bento Container: Seats Stepper + Middle Seat Toggle + Fare Math
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Seats Stepper Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Seats',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14241C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vehicle limit: $maxSeats seats',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5C6E64),
                        ),
                      ),
                    ],
                  ),
                  // Stepper with thumb-friendly 44x44dp tap targets
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Color(0xFF1B4D3E),
                              size: 22,
                            ),
                            tooltip: 'Decrease Seats',
                            onPressed: draft.availableSeats > 1
                                ? () => ref
                                    .read(offerRideProvider.notifier)
                                    .setAvailableSeats(draft.availableSeats - 1)
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${draft.availableSeats}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14241C),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'Seats',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5C6E64),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF1B4D3E),
                              size: 22,
                            ),
                            tooltip: 'Increase Seats',
                            onPressed: draft.availableSeats < maxSeats
                                ? () => ref
                                    .read(offerRideProvider.notifier)
                                    .setAvailableSeats(draft.availableSeats + 1)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE2E8E4), height: 1),
              const SizedBox(height: 14),

              // Middle-Seat Comfort Policy Toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Middle-Seat Comfort',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF14241C),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Leave middle seat empty for executive luxury comfort',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF5C6E64),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _middleSeatComfort,
                    activeThumbColor: const Color(0xFF2EC486),
                    activeTrackColor: const Color(0xFFE8F5EF),
                    onChanged: (val) {
                      setState(() {
                        _middleSeatComfort = val;
                      });
                      if (val) {
                        final cur = draft.availableSeats;
                        if (cur > 1 && cur >= maxSeats) {
                          ref.read(offerRideProvider.notifier).setAvailableSeats(cur - 1);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE2E8E4), height: 1),
              const SizedBox(height: 14),

              // Contribution Per Seat Field
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Contribution Per Seat',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF14241C),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Shared fuel & toll contribution',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF5C6E64),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      controller: widget.contributionController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                      decoration: InputDecoration(
                        prefixText: '\u20B9 ',
                        prefixStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4D3E),
                        ),
                        suffixText: ' / seat',
                        suffixStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5C6E64),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8E4), width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8E4), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2EC486), width: 1.2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 0) {
                          ref.read(offerRideProvider.notifier).setContribution(parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Dynamic Math Pill: Max Fuel Recovery: ₹700 (2 seats × ₹350)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2EC486).withValues(alpha: 0.6), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.energy_savings_leaf_outlined,
                      size: 15,
                      color: Color(0xFF1B4D3E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Max Fuel Recovery: \u20B9$totalRecovery (${draft.availableSeats} seats \u00D7 \u20B9${draft.contributionPerSeat.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 3. Pickup Preference Section Header
        _buildSectionHeader(
          'Pickup Preference',
          'Choose how you will coordinate passenger pickups',
        ),
        const SizedBox(height: 10),

        // Pickup Coordination Preference (Custom Radio Cards)
        Container(
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
          child: Column(
            children: [
              _buildPickupPolicyCard(
                policy: PickupPolicy.nearby,
                current: draft.pickupPolicy,
                title: 'Nearby Pickup (Recommended)',
                subtitle: 'Willing to deviate up to 5 km along route for pickups.',
                isFirst: true,
              ),
              const Divider(color: Color(0xFFE2E8E4), height: 1),
              _buildPickupPolicyCard(
                policy: PickupPolicy.exact,
                current: draft.pickupPolicy,
                title: 'Exact Origin Only',
                subtitle: 'Passengers must board at your exact starting location.',
                isFirst: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPolicyCard({
    required PickupPolicy policy,
    required PickupPolicy current,
    required String title,
    required String subtitle,
    required bool isFirst,
  }) {
    final isSelected = policy == current;

    return InkWell(
      onTap: () => ref.read(offerRideProvider.notifier).setPickupPolicy(policy),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isFirst ? Radius.zero : const Radius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1B4D3E) : const Color(0xFF5C6E64),
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF14241C),
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
              ),
            ),
          ],
        ),
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
