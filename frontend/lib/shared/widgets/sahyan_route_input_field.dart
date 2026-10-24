import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RouteInputType { origin, destination, stopover }

/// Standard Option A Route Input Field for Sahyān.
/// Features a filled container (#F8FAF8), integrated uppercase top micro-label,
/// fixed 32dp left node container, borderless text input, and fixed 36dp right contextual action.
class SahyanRouteInputField extends StatefulWidget {
  final String label;
  final String? labelPrefix;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final RouteInputType type;
  final VoidCallback? onGpsTap;
  final bool isGpsLoading;
  final VoidCallback? onActionTap;
  final VoidCallback? onClear;
  final Widget? trailingAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  const SahyanRouteInputField({
    super.key,
    required this.label,
    this.labelPrefix,
    required this.hintText,
    required this.controller,
    this.focusNode,
    this.type = RouteInputType.origin,
    this.onGpsTap,
    this.isGpsLoading = false,
    this.onActionTap,
    this.onClear,
    this.trailingAction,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  @override
  State<SahyanRouteInputField> createState() => _SahyanRouteInputFieldState();
}

class _SahyanRouteInputFieldState extends State<SahyanRouteInputField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(SahyanRouteInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _effectiveFocusNode.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? const Color(0xFF2EC486) : const Color(0xFFE2E8E4),
          width: isFocused ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Left Node Container (Fixed 32dp width)
          SizedBox(
            width: 32,
            child: Center(
              child: _buildLeftNode(),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Center Content Column (Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Integrated Top Micro-Label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.labelPrefix != null) ...[
                        Text(
                          widget.labelPrefix!,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isFocused
                                ? const Color(0xFF1B4D3E)
                                : const Color(0xFF5C6E64),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isFocused
                              ? const Color(0xFF1B4D3E)
                              : const Color(0xFF5C6E64),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Borderless Text Input Field (15px SemiBold #14241C, zero vertical padding)
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _effectiveFocusNode,
                    readOnly: widget.readOnly,
                    autofocus: widget.autofocus,
                    onTap: widget.onTap,
                    onChanged: widget.onChanged,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: const Color(0xFF0B5D4B),
                    cursorWidth: 2.0,
                    cursorHeight: 18.0,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF14241C),
                      height: 1.25,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A9A90),
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Right Contextual Action
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.trailingAction != null)
                  widget.trailingAction!
                else
                  _buildDefaultTrailingAction(hasText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftNode() {
    switch (widget.type) {
      case RouteInputType.origin:
        // Solid Pine circle dot #1B4D3E (8dp) inside soft mint container #E8F5EF (26x26dp)
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5EF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1B4D3E),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case RouteInputType.destination:
        // Vibrant Mint pin #2EC486 (16dp) inside soft mint container #E8F5EF (26x26dp)
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5EF),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.location_on_rounded,
              size: 16,
              color: Color(0xFF2EC486),
            ),
          ),
        );
      case RouteInputType.stopover:
        // Solid amber milestone dot inside soft amber container #FEF3C7
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.fiber_manual_record_rounded,
              size: 10,
              color: Color(0xFFE5A93C),
            ),
          ),
        );
    }
  }

  Widget _buildDefaultTrailingAction(bool hasText) {
    if (widget.type == RouteInputType.origin) {
      if (widget.isGpsLoading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
          ),
        );
      }
      return Tooltip(
        message: 'Use current GPS location',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onGpsTap?.call();
            },
            borderRadius: BorderRadius.circular(18),
            splashColor: const Color(0xFFE8F5EF),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.my_location_rounded,
                size: 20,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ),
        ),
      );
    } else {
      // Destination: Clear button (X) when text is present, or landmark icon when empty
      if (hasText) {
        return Tooltip(
          message: 'Clear location',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.controller.clear();
                widget.onClear?.call();
                widget.onChanged?.call('');
                setState(() {});
              },
              borderRadius: BorderRadius.circular(18),
              splashColor: const Color(0xFFE8F5EF),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: Color(0xFF8A9A90),
                ),
              ),
            ),
          ),
        );
      } else {
        return Tooltip(
          message: 'Select destination',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onActionTap?.call();
              },
              borderRadius: BorderRadius.circular(18),
              splashColor: const Color(0xFFE8F5EF),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.explore_outlined,
                  size: 20,
                  color: Color(0xFF2EC486),
                ),
              ),
            ),
          ),
        );
      }
    }
  }
}

/// Continuous 2dp dashed vertical connector rail painter in #2EC486.
class SahyanDashedRailPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashHeight;
  final double dashGap;

  const SahyanDashedRailPainter({
    this.color = const Color(0xFF2EC486),
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
  bool shouldRepaint(covariant SahyanDashedRailPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashGap != dashGap;
  }
}

/// Unified Transit Connector Divider integrating the vertical rail line
/// and either a Centered Quick-Swap Button or a Centered Stopover Action Pill.
class SahyanTransitRailDivider extends StatelessWidget {
  final double height;
  final Widget? centerWidget;
  final Color railColor;

  const SahyanTransitRailDivider({
    super.key,
    this.height = 32.0,
    this.centerWidget,
    this.railColor = const Color(0xFF2EC486),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical Continuous Dotted Connector (center at 14 + 16 = 30dp)
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            width: 32,
            child: Center(
              child: CustomPaint(
                size: Size(2.0, height),
                painter: SahyanDashedRailPainter(
                  color: railColor,
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ),

          // Horizontal Hairline Divider with Centered Action Widget
          LayoutBuilder(
            builder: (context, constraints) {
              final maxCenterWidth =
                  (constraints.maxWidth - 48 - 14 - 16).clamp(0.0, double.infinity);
              return Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Divider(
                      color: Color(0xFFE2E8E4),
                      thickness: 0.8,
                      height: 1,
                    ),
                  ),
                  if (centerWidget != null) ...[
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCenterWidth),
                      child: centerWidget!,
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Expanded(
                    child: Divider(
                      color: Color(0xFFE2E8E4),
                      thickness: 0.8,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Circular quick-swap button (32x32dp, #FFFFFF surface, 0.8px border #E2E8E4, soft shadow)
/// centered on the divider line between Pickup and Destination.
class SahyanQuickSwapButton extends StatefulWidget {
  final VoidCallback onSwap;

  const SahyanQuickSwapButton({
    super.key,
    required this.onSwap,
  });

  @override
  State<SahyanQuickSwapButton> createState() => _SahyanQuickSwapButtonState();
}

class _SahyanQuickSwapButtonState extends State<SahyanQuickSwapButton> {
  double _turns = 0.0;
  bool _isPressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _turns += 0.5; // 180 degrees
    });
    widget.onSwap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: _turns,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: const Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean capsule badge pill for '+ Add Stopover / Toll' centered on the transit divider line.
class SahyanStopoverActionPill extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const SahyanStopoverActionPill({
    super.key,
    required this.onTap,
    this.label = 'Add Stopover / Toll',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 14,
                color: Color(0xFF1B4D3E),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
