import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';

/// Premium Smartphone-Native Hero Route Search Bento Card for Sahyān.
/// Features high-contrast editorial typography, tactile continuous route capsule,
/// smooth animated swap action, quick corridor discovery chips, and parameter controls.
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
  final VoidCallback? onTapPickup;
  final VoidCallback? onTapDestination;

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
      {'from': 'Baroda', 'to': 'Ahmedabad', 'price': 180},
      {'from': 'Morbi', 'to': 'Rajkot', 'price': 120},
    ],
    this.onTapPickup,
    this.onTapDestination,
  });

  @override
  State<HeroSearchCard> createState() => _HeroSearchCardState();
}

class _HeroSearchCardState extends State<HeroSearchCard> {
  double _swapTurns = 0.0;
  bool _isSwapPressed = false;
  bool _isSearchPressed = false;

  void _handleSwap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _swapTurns += 0.5;
    });
    widget.onSwap();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
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
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── A. Header Row: Title + Route Corridor Badge ──────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Where are you heading?',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
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
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SahyanColors.primaryMint.withValues(alpha: 0.4),
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
                        color: SahyanColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'P2P Corridor',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.primaryDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── B. Integrated Continuous Route Capsule ────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: SahyanColors.border,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: SahyanColors.textMain.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Transit Visual Track (Dot, Dashed Line, Pin)
                      SizedBox(
                        width: 44,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 18),
                            // Origin Dot (Deep Forest, 9dp)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: SahyanColors.primaryDark,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: SahyanColors.primaryMint,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Vertical Dashed Transit Corridor Line
                            Expanded(
                              child: CustomPaint(
                                painter: const _DashedVerticalTrackPainter(
                                  color: SahyanColors.primaryMint,
                                  strokeWidth: 2.0,
                                  dashHeight: 3.5,
                                  dashGap: 2.5,
                                ),
                                size: const Size(2, double.infinity),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Destination Pin (Mint Accent)
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: SahyanColors.primaryDark,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // Right Input Fields (Pickup and Dropoff)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Pickup Origin Field
                              InkWell(
                                onTap: widget.onTapPickup,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 57),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'PICKUP LOCATION',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: SahyanColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TextField(
                                        controller: widget.originController,
                                        onTap: widget.onTapPickup,
                                        readOnly: widget.onTapPickup != null,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: SahyanColors.textMain,
                                          letterSpacing: -0.2,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: 'Enter pickup hub or address…',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: SahyanColors.textDisabled,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Hairline Divider
                              const Divider(
                                height: 0.8,
                                thickness: 0.8,
                                color: SahyanColors.border,
                              ),

                              // 2. Dropoff Destination Field
                              InkWell(
                                onTap: widget.onTapDestination,
                                borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(20),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 57),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'DESTINATION HUB',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: SahyanColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TextField(
                                        controller: widget.destinationController,
                                        onTap: widget.onTapDestination,
                                        readOnly: widget.onTapDestination != null,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: SahyanColors.textMain,
                                          letterSpacing: -0.2,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: 'Where to? (Destination)…',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: SahyanColors.textDisabled,
                                            fontSize: 14,
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
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Swap Button (36x36dp, Tactile Animated Rotation)
                Positioned(
                  right: 12,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isSwapPressed = true),
                    onTapUp: (_) => setState(() => _isSwapPressed = false),
                    onTapCancel: () => setState(() => _isSwapPressed = false),
                    child: AnimatedScale(
                      scale: _isSwapPressed ? 0.90 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(
                          side: BorderSide(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        elevation: 2.0,
                        shadowColor: SahyanColors.textMain.withValues(alpha: 0.08),
                        child: InkWell(
                          onTap: _handleSwap,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: AnimatedRotation(
                                turns: _swapTurns,
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                child: const Icon(
                                  Icons.swap_vert_rounded,
                                  size: 19,
                                  color: SahyanColors.primaryDark,
                                ),
                              ),
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

          // ─── C. Frequent Highway Corridors ─────────────────────────────────
          Row(
            children: [
              const Flexible(
                child: Text(
                  'FREQUENT CORRIDORS',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: SahyanColors.primaryMint,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.popularCorridors.map((c) {
                final label = '${c['from']} → ${c['to']}';
                final price = '₹${c['price']}';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: const Color(0xFFF6FAF8),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelectCorridor(c);
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: SahyanColors.primaryMint.withValues(alpha: 0.12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: SahyanColors.textMain,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: SahyanColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                price,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: SahyanColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ─── D. Dual-Cell Parameters Bar: Date/Time & Seat Stepper ─────────
          _ParamsBar(
            formattedDate: formattedDate,
            formattedTime: formattedTime,
            selectedSeats: widget.selectedSeats,
            onPickDateTime: widget.onPickDateTime,
            onSeatsChanged: widget.onSeatsChanged,
          ),

          const SizedBox(height: 16),

          // ─── E. Primary Search CTA Button ──────────────────────────────────
          GestureDetector(
            onTapDown: (_) => setState(() => _isSearchPressed = true),
            onTapUp: (_) => setState(() => _isSearchPressed = false),
            onTapCancel: () => setState(() => _isSearchPressed = false),
            child: AnimatedScale(
              scale: _isSearchPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: SizedBox(
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
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: SahyanColors.primaryMint,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Find Matching Rides',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Unified Dual-Cell Parameters Bar ────────────────────────────────────────
/// Segmented layout: [ Calendar Date + Time ] | [ Seat Count Stepper ]
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
    Future.delayed(
      const Duration(milliseconds: 120),
      () => setState(() => _minusScaled = false),
    );
    widget.onSeatsChanged(widget.selectedSeats - 1);
  }

  void _tapPlus() {
    if (widget.selectedSeats >= 6) return;
    HapticFeedback.selectionClick();
    setState(() => _plusScaled = true);
    Future.delayed(
      const Duration(milliseconds: 120),
      () => setState(() => _plusScaled = false),
    );
    widget.onSeatsChanged(widget.selectedSeats + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          // Left Cell — Departure Date & Time Picker
          Expanded(
            child: InkWell(
              onTap: widget.onPickDateTime,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.textMain,
                          letterSpacing: -0.2,
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

          // Vertical Hairline Divider
          Container(
            width: 1,
            height: 26,
            color: SahyanColors.border,
          ),

          // Right Cell — Seat Count Stepper
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 105, maxWidth: 135),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minus Button
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
                                ? Colors.white
                                : const Color(0xFFEFF3F0),
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

                    // Seat Count Label
                    Text(
                      '${widget.selectedSeats} Seat${widget.selectedSeats == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: SahyanColors.textMain,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Plus Button
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
                                : const Color(0xFFEFF3F0),
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
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the dashed vertical transit line connecting Origin to Destination.
class _DashedVerticalTrackPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashHeight;
  final double dashGap;

  const _DashedVerticalTrackPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashHeight = 3.5,
    this.dashGap = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;
    double y = 0.0;
    while (y < size.height) {
      final endY = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, endY), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVerticalTrackPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashGap != dashGap;
  }
}
