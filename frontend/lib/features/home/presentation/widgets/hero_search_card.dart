import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';

class HeroSearchCard extends StatefulWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onSwap;
  final ValueChanged<Map<String, dynamic>> onSelectCorridor;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onPickDateTime;
  final int selectedSeats;
  final ValueChanged<int> onSeatsChanged;
  final VoidCallback onSearch;
  final List<Map<String, dynamic>> popularCorridors;

  const HeroSearchCard({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.onSwap,
    required this.onSelectCorridor,
    required this.selectedDate,
    required this.selectedTime,
    required this.onPickDateTime,
    required this.selectedSeats,
    required this.onSeatsChanged,
    required this.onSearch,
    this.popularCorridors = const [
      {'from': 'Bhuj', 'to': 'Ahmd', 'price': 388},
      {'from': 'Rajkot', 'to': 'Surat', 'price': 520},
      {'from': 'Baroda', 'to': 'Ahmd', 'price': 180},
      {'from': 'Morbi', 'to': 'Rajkot', 'price': 120},
    ],
  });

  @override
  State<HeroSearchCard> createState() => _HeroSearchCardState();
}

class _HeroSearchCardState extends State<HeroSearchCard> {
  double _swapTurns = 0.0;

  void _handleSwap() {
    HapticFeedback.lightImpact();
    setState(() {
      _swapTurns += 0.5; // 180 degree rotation
    });
    widget.onSwap();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = widget.selectedTime.format(context);

    return BentoContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Express Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Find a Shared Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: SahyanColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Express',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Unified Route Input Container with Route Rail and Centered Inline Swap Button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8E4),
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Vertical Route Rail with consistent 16px left margin
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Green Origin Dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B4D3E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // 2px Connecting Line
                          Container(
                            width: 2,
                            height: 32,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          // Mint Destination Pin
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(0xFF2EC486),
                          ),
                        ],
                      ),
                    ),

                    // Route Inputs Column
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: widget.originController,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SahyanColors.textMain,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                hintText: 'Pickup Origin (e.g. SG Highway)',
                                hintStyle: TextStyle(
                                  color: SahyanColors.textDisabled,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 0.8,
                              color: Color(0xFFE2E8E4),
                            ),
                            TextFormField(
                              controller: widget.destinationController,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SahyanColors.textMain,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                hintText: 'Destination (e.g. Kalawad Road)',
                                hintStyle: TextStyle(
                                  color: SahyanColors.textDisabled,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Inline Circular Swap Button (36x36dp, #FFFFFF, subtle shadow) vertically centered
                Positioned(
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: Color(0xFFE2E8E4),
                        width: 0.8,
                      ),
                    ),
                    shadowColor: const Color(0x1414241C),
                    elevation: 2,
                    child: InkWell(
                      onTap: _handleSwap,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: AnimatedRotation(
                            turns: _swapTurns,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              size: 18,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Popular Routes Quick Chips
          const Text(
            'Popular Routes in Gujarat',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SahyanColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.popularCorridors.map((c) {
                final label = '${c['from']} → ${c['to']} · ₹${c['price']}';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: SahyanColors.chipBackground,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelectCorridor(c);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SahyanColors.textMain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Departure Date/Time & Seat Stepper Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;
              final departureWidget = Material(
                color: SahyanColors.chipBackground,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: widget.onPickDateTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SahyanColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: SahyanColors.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today, $formattedTime',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final stepperWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: SahyanColors.chipBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SahyanColors.border,
                    width: 0.8,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        color: widget.selectedSeats > 1
                            ? SahyanColors.textMain
                            : SahyanColors.textDisabled,
                        onPressed: widget.selectedSeats > 1
                            ? () {
                                HapticFeedback.selectionClick();
                                widget.onSeatsChanged(widget.selectedSeats - 1);
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '${widget.selectedSeats} Seats',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SahyanColors.textMain,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        color: widget.selectedSeats < 6
                            ? SahyanColors.textMain
                            : SahyanColors.textDisabled,
                        onPressed: widget.selectedSeats < 6
                            ? () {
                                HapticFeedback.selectionClick();
                                widget.onSeatsChanged(widget.selectedSeats + 1);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    departureWidget,
                    const SizedBox(height: 10),
                    stepperWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: departureWidget),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: stepperWidget),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Primary CTA: Find Matches
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: SahyanColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Find Matches',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
