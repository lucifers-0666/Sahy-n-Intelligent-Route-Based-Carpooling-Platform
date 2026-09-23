import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';

/// Ultra-clean Luxury Bento Hero Search Card.
/// Single unified elevated white card — no nested double-border artifacts.
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
      {'from': 'Bhuj', 'to': 'Ahmedabad', 'price': 388},
      {'from': 'Rajkot', 'to': 'Surat', 'price': 520},
      {'from': 'Baroda', 'to': 'Ahmedabad', 'price': 180},
      {'from': 'Morbi', 'to': 'Rajkot', 'price': 120},
    ],
  });

  @override
  State<HeroSearchCard> createState() => _HeroSearchCardState();
}

class _HeroSearchCardState extends State<HeroSearchCard> {
  double _swapTurns = 0.0;

  void _handleSwap() {
    HapticFeedback.mediumImpact();
    setState(() => _swapTurns += 0.5);
    widget.onSwap();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = widget.selectedTime.format(context);
    final formattedDate = _formatDate(widget.selectedDate);

    return BentoContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── A. Header Row ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Where are you heading?',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: SahyanColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // ⚡ Express Corridors badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SahyanColors.primaryMint.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 12,
                      color: SahyanColors.primaryDark,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Express Corridors',
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
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── B. Unified Route Rail Container ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SahyanColors.border,
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Column(
                  children: [
                    // Origin Row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 52, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Solid pine dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: SahyanColors.primaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: widget.originController,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: SahyanColors.textMain,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                hintText: 'Pickup origin…',
                                hintStyle: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: SahyanColors.textDisabled,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hairline divider
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 32,
                      endIndent: 52,
                      color: SahyanColors.border,
                    ),

                    // Destination Row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 52, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Mint location pin
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: SahyanColors.primaryMint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: widget.destinationController,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: SahyanColors.textMain,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                hintText: 'Where to?',
                                hintStyle: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: SahyanColors.textDisabled,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Swap button — vertically centered, right-anchored
                Positioned(
                  right: 10,
                  child: Material(
                    color: SahyanColors.surface,
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: SahyanColors.border,
                        width: 0.8,
                      ),
                    ),
                    shadowColor: const Color(0x1414241C),
                    elevation: 2,
                    child: InkWell(
                      onTap: _handleSwap,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: AnimatedRotation(
                            turns: _swapTurns,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              size: 17,
                              color: SahyanColors.primaryDark,
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

          const SizedBox(height: 16),

          // ─── C. Popular Corridors Strip ───────────────────────────────────
          const Text(
            'FREQUENT ROUTES',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: SahyanColors.textMuted,
              letterSpacing: 1.2,
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
                    color: SahyanColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelectCorridor(c);
                      },
                      borderRadius: BorderRadius.circular(999),
                      splashColor:
                          SahyanColors.primaryMint.withValues(alpha: 0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
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
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SahyanColors.textMain,
                            letterSpacing: -0.1,
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

          // ─── D. Unified Dual-Cell Parameters Bar ─────────────────────────
          _ParamsBar(
            formattedDate: formattedDate,
            formattedTime: formattedTime,
            selectedSeats: widget.selectedSeats,
            onPickDateTime: widget.onPickDateTime,
            onSeatsChanged: widget.onSeatsChanged,
          ),

          const SizedBox(height: 16),

          // ─── E. Primary Search CTA ────────────────────────────────────────
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Find Matching Rides',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '→',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Unified Dual-Cell Parameters Bar ────────────────────────────────────────
/// One seamless container: [📅 Date + Time] | [− Seats +]
/// No double borders, equal height, perfectly balanced.
class _ParamsBar extends StatefulWidget {
  final String formattedDate;
  final String formattedTime;
  final int selectedSeats;
  final VoidCallback onPickDateTime;
  final ValueChanged<int> onSeatsChanged;

  const _ParamsBar({
    required this.formattedDate,
    required this.formattedTime,
    required this.selectedSeats,
    required this.onPickDateTime,
    required this.onSeatsChanged,
  });

  @override
  State<_ParamsBar> createState() => _ParamsBarState();
}

class _ParamsBarState extends State<_ParamsBar> {
  bool _minusScaled = false;
  bool _plusScaled = false;

  void _tapMinus() {
    if (widget.selectedSeats <= 1) return;
    HapticFeedback.selectionClick();
    setState(() => _minusScaled = true);
    Future.delayed(const Duration(milliseconds: 120),
        () => setState(() => _minusScaled = false));
    widget.onSeatsChanged(widget.selectedSeats - 1);
  }

  void _tapPlus() {
    if (widget.selectedSeats >= 6) return;
    HapticFeedback.selectionClick();
    setState(() => _plusScaled = true);
    Future.delayed(const Duration(milliseconds: 120),
        () => setState(() => _plusScaled = false));
    widget.onSeatsChanged(widget.selectedSeats + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          // Left Cell — Departure date/time
          Expanded(
            child: InkWell(
              onTap: widget.onPickDateTime,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: SahyanColors.primaryDark,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        '${widget.formattedDate}, ${widget.formattedTime}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SahyanColors.textMain,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 28,
            color: SahyanColors.border,
          ),

          // Right Cell — Seat stepper
          SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minus button
                  AnimatedScale(
                    scale: _minusScaled ? 0.82 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTap: _tapMinus,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.selectedSeats > 1
                              ? SahyanColors.surface
                              : const Color(0xFFF0F4F1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 14,
                          color: widget.selectedSeats > 1
                              ? SahyanColors.textMain
                              : SahyanColors.textDisabled,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Seat count label
                  Text(
                    '${widget.selectedSeats} Seat${widget.selectedSeats == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.textMain,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Plus button
                  AnimatedScale(
                    scale: _plusScaled ? 0.82 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTap: _tapPlus,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.selectedSeats < 6
                              ? SahyanColors.primaryDark
                              : const Color(0xFFF0F4F1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.selectedSeats < 6
                                ? SahyanColors.primaryDark
                                : SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: widget.selectedSeats < 6
                              ? Colors.white
                              : SahyanColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
