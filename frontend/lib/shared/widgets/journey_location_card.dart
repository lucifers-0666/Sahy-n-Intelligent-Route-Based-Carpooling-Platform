import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sahyan/shared/models/location_model.dart';

/// Unified Connected Journey Location Card for Sahyān.
/// Serves as the single shared location input architecture across:
/// 1. Home Screen Passenger Search (HeroSearchCard)
/// 2. Offer a Ride Driver Wizard (OfferRideStep1)
///
/// Features:
/// - Clean white surface container with 22dp radius and single 0.8px border (no nested double borders)
/// - Continuous vertical transit rail connecting pickup origin node to drop-off destination pin
/// - Integrated uppercase micro-labels and borderless inputs
/// - Separate actions for clearing text (X), map picker selection, and GPS geolocation
/// - Accessible 180-degree animated quick-swap action
/// - Dynamic highway stopover integration along the transit rail
class JourneyLocationCard extends StatefulWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final FocusNode? pickupFocusNode;
  final FocusNode? destinationFocusNode;
  final VoidCallback onSwap;
  final VoidCallback? onUseCurrentLocation;
  final VoidCallback? onSelectPickupOnMap;
  final VoidCallback? onSelectDestinationOnMap;
  final ValueChanged<String>? onPickupChanged;
  final ValueChanged<String>? onDestinationChanged;
  final VoidCallback? onPickupClear;
  final VoidCallback? onDestinationClear;
  final VoidCallback? onTapPickup;
  final VoidCallback? onTapDestination;
  final bool isPickupReadOnly;
  final bool isDestinationReadOnly;
  final bool isGpsLoading;
  final String pickupLabel;
  final String destinationLabel;
  final String? pickupPrefix;
  final String? destinationPrefix;
  final String pickupHint;
  final String destinationHint;
  final IconData? destinationTrailingIcon;
  final List<LocationModel> stopovers;
  final ValueChanged<int>? onRemoveStopover;
  final Widget? stopoverActionWidget;
  final bool showBottomCurrentLocation;
  final Color emeraldColor;
  final Color mintColor;
  final Color borderColor;
  final Color surfaceColor;

  const JourneyLocationCard({
    super.key,
    required this.pickupController,
    required this.destinationController,
    this.pickupFocusNode,
    this.destinationFocusNode,
    required this.onSwap,
    this.onUseCurrentLocation,
    this.onSelectPickupOnMap,
    this.onSelectDestinationOnMap,
    this.onPickupChanged,
    this.onDestinationChanged,
    this.onPickupClear,
    this.onDestinationClear,
    this.onTapPickup,
    this.onTapDestination,
    this.isPickupReadOnly = false,
    this.isDestinationReadOnly = false,
    this.isGpsLoading = false,
    this.pickupLabel = 'PICKUP LOCATION',
    this.destinationLabel = 'DESTINATION',
    this.pickupPrefix,
    this.destinationPrefix,
    this.pickupHint = 'Search city, area or landmark',
    this.destinationHint = 'Where do you want to go?',
    this.destinationTrailingIcon,
    this.stopovers = const [],
    this.onRemoveStopover,
    this.stopoverActionWidget,
    this.showBottomCurrentLocation = false,
    this.emeraldColor = const Color(0xFF0B5D4B),
    this.mintColor = const Color(0xFF2EC486),
    this.borderColor = const Color(0xFFDCE7E1),
    this.surfaceColor = Colors.white,
  });

  @override
  State<JourneyLocationCard> createState() => _JourneyLocationCardState();
}

class _JourneyLocationCardState extends State<JourneyLocationCard> {
  double _swapRotationTurns = 0.0;
  bool _isSwapPressed = false;

  FocusNode? _internalPickupFocusNode;
  FocusNode? _internalDestFocusNode;

  FocusNode get _effectivePickupFocusNode =>
      widget.pickupFocusNode ?? (_internalPickupFocusNode ??= FocusNode());
  FocusNode get _effectiveDestFocusNode =>
      widget.destinationFocusNode ?? (_internalDestFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectivePickupFocusNode.addListener(_handleFocusUpdate);
    _effectiveDestFocusNode.addListener(_handleFocusUpdate);
    widget.pickupController.addListener(_handleTextUpdate);
    widget.destinationController.addListener(_handleTextUpdate);
  }

  @override
  void didUpdateWidget(JourneyLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupController != widget.pickupController) {
      oldWidget.pickupController.removeListener(_handleTextUpdate);
      widget.pickupController.addListener(_handleTextUpdate);
    }
    if (oldWidget.destinationController != widget.destinationController) {
      oldWidget.destinationController.removeListener(_handleTextUpdate);
      widget.destinationController.addListener(_handleTextUpdate);
    }
    if (oldWidget.pickupFocusNode != widget.pickupFocusNode) {
      (oldWidget.pickupFocusNode ?? _internalPickupFocusNode)
          ?.removeListener(_handleFocusUpdate);
      _effectivePickupFocusNode.addListener(_handleFocusUpdate);
    }
    if (oldWidget.destinationFocusNode != widget.destinationFocusNode) {
      (oldWidget.destinationFocusNode ?? _internalDestFocusNode)
          ?.removeListener(_handleFocusUpdate);
      _effectiveDestFocusNode.addListener(_handleFocusUpdate);
    }
  }

  @override
  void dispose() {
    _effectivePickupFocusNode.removeListener(_handleFocusUpdate);
    _effectiveDestFocusNode.removeListener(_handleFocusUpdate);
    _internalPickupFocusNode?.dispose();
    _internalDestFocusNode?.dispose();
    widget.pickupController.removeListener(_handleTextUpdate);
    widget.destinationController.removeListener(_handleTextUpdate);
    super.dispose();
  }

  void _handleFocusUpdate() {
    if (mounted) setState(() {});
  }

  void _handleTextUpdate() {
    if (mounted) setState(() {});
  }

  void _handleSwapTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _swapRotationTurns += 0.5; // 180 degrees
    });
    widget.onSwap();
  }

  @override
  Widget build(BuildContext context) {
    final hasPickupText = widget.pickupController.text.trim().isNotEmpty;
    final hasDestText = widget.destinationController.text.trim().isNotEmpty;
    final isPickupFocused = _effectivePickupFocusNode.hasFocus;
    final isDestFocused = _effectiveDestFocusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Pickup Origin Field Row
          _buildLocationRow(
            label: widget.pickupLabel,
            labelPrefix: widget.pickupPrefix,
            hint: widget.pickupHint,
            controller: widget.pickupController,
            focusNode: _effectivePickupFocusNode,
            isFocused: isPickupFocused,
            readOnly: widget.isPickupReadOnly,
            onTap: widget.onTapPickup,
            onChanged: widget.onPickupChanged,
            onClear: () {
              widget.pickupController.clear();
              widget.onPickupClear?.call();
              widget.onPickupChanged?.call('');
              setState(() {});
            },
            nodeWidget: _buildOriginNode(isPickupFocused),
            actions: [
              if (hasPickupText)
                _buildActionIconButton(
                  tooltip: 'Clear pickup location',
                  icon: Icons.cancel_rounded,
                  iconSize: 18,
                  color: const Color(0xFF8A9A90),
                  onTap: () {
                    widget.pickupController.clear();
                    widget.onPickupClear?.call();
                    widget.onPickupChanged?.call('');
                    setState(() {});
                  },
                ),
              if (widget.onSelectPickupOnMap != null)
                _buildActionIconButton(
                  tooltip: 'Select pickup on map',
                  icon: Icons.map_outlined,
                  iconSize: 20,
                  color: widget.emeraldColor,
                  onTap: widget.onSelectPickupOnMap!,
                ),
              if (widget.onUseCurrentLocation != null)
                _buildGpsActionButton(),
            ],
          ),

          // 2. Continuous Transit Rail Divider & Stopovers / Swap Button
          _buildTransitRailDivider(),

          // 3. Stopovers Section (if any in route)
          if (widget.stopovers.isNotEmpty) ...[
            for (int i = 0; i < widget.stopovers.length; i++) ...[
              _buildStopoverRow(widget.stopovers[i], i),
              _buildTransitRailConnector(height: 16),
            ],
          ],

          // 4. Destination Drop-off Field Row
          _buildLocationRow(
            label: widget.destinationLabel,
            labelPrefix: widget.destinationPrefix,
            hint: widget.destinationHint,
            controller: widget.destinationController,
            focusNode: _effectiveDestFocusNode,
            isFocused: isDestFocused,
            readOnly: widget.isDestinationReadOnly,
            onTap: widget.onTapDestination,
            onChanged: widget.onDestinationChanged,
            onClear: () {
              widget.destinationController.clear();
              widget.onDestinationClear?.call();
              widget.onDestinationChanged?.call('');
              setState(() {});
            },
            nodeWidget: _buildDestinationNode(isDestFocused),
            actions: [
              if (hasDestText)
                _buildActionIconButton(
                  tooltip: 'Clear destination',
                  icon: Icons.cancel_rounded,
                  iconSize: 18,
                  color: const Color(0xFF8A9A90),
                  onTap: () {
                    widget.destinationController.clear();
                    widget.onDestinationClear?.call();
                    widget.onDestinationChanged?.call('');
                    setState(() {});
                  },
                ),
              if (widget.onSelectDestinationOnMap != null)
                _buildActionIconButton(
                  tooltip: 'Select destination on map',
                  icon: widget.destinationTrailingIcon ?? Icons.map_outlined,
                  iconSize: 20,
                  color: widget.emeraldColor,
                  onTap: widget.onSelectDestinationOnMap!,
                ),
            ],
          ),

          // 5. Optional Bottom Action: "Use my current location"
          if (widget.showBottomCurrentLocation &&
              widget.onUseCurrentLocation != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onUseCurrentLocation,
                icon: Icon(
                  Icons.my_location_rounded,
                  size: 17,
                  color: widget.emeraldColor,
                ),
                label: Text(
                  'Use my current location',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: widget.emeraldColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Location Input Row (Single un-nested text field)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildLocationRow({
    required String label,
    String? labelPrefix,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool readOnly,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    required VoidCallback onClear,
    required Widget nodeWidget,
    required List<Widget> actions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Node (Origin Dot / Destination Pin)
        SizedBox(
          width: 32,
          child: Center(child: nodeWidget),
        ),
        const SizedBox(width: 10),

        // Center Content: Label + Borderless TextField (NO NESTED DOUBLE BORDER)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Micro-Label
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (labelPrefix != null) ...[
                      Text(
                        labelPrefix,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isFocused
                              ? widget.emeraldColor
                              : const Color(0xFF6B7F78),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isFocused
                            ? widget.emeraldColor
                            : const Color(0xFF6B7F78),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              // Clean Borderless TextField
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
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: widget.emeraldColor,
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    hintText: hint,
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
        const SizedBox(width: 6),

        // Right Contextual Action Icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Rail Dividers & Center Swap Button
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTransitRailDivider() {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical Continuous Dashed Rail Line
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 32,
            child: Center(
              child: CustomPaint(
                size: const Size(2.0, 32.0),
                painter: _TransitDashedLinePainter(
                  color: widget.emeraldColor,
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ),

          // Horizontal Hairline with Accessible Quick Swap Button
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: Divider(
                  color: widget.borderColor,
                  thickness: 0.8,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              _buildSwapButton(),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: widget.borderColor,
                  thickness: 0.8,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransitRailConnector({double height = 16.0}) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 32,
            child: Center(
              child: CustomPaint(
                size: Size(2.0, height),
                painter: _TransitDashedLinePainter(
                  color: widget.emeraldColor,
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isSwapPressed = true),
      onTapUp: (_) => setState(() => _isSwapPressed = false),
      onTapCancel: () => setState(() => _isSwapPressed = false),
      onTap: _handleSwapTap,
      child: AnimatedScale(
        scale: _isSwapPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: widget.borderColor, width: 0.8),
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
              turns: _swapRotationTurns,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.swap_vert_rounded,
                size: 17,
                color: widget.emeraldColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Stopover Row
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStopoverRow(LocationModel stop, int index) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
              ),
              child: Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF92400E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STOPOVER ${index + 1} (VIA)',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stop.name,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14241C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        if (widget.onRemoveStopover != null)
          _buildActionIconButton(
            tooltip: 'Remove stopover',
            icon: Icons.close_rounded,
            iconSize: 18,
            color: const Color(0xFF5C6E64),
            onTap: () => widget.onRemoveStopover!(index),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Nodes & Action Buttons
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildOriginNode(bool isFocused) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EF),
        shape: BoxShape.circle,
        border: Border.all(
          color: isFocused ? widget.mintColor : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.emeraldColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationNode(bool isFocused) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EF),
        shape: BoxShape.circle,
        border: Border.all(
          color: isFocused ? widget.mintColor : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.location_on_rounded,
          size: 16,
          color: widget.mintColor,
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required String tooltip,
    required IconData icon,
    required double iconSize,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFE8F5EF),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildGpsActionButton() {
    return Tooltip(
      message: 'Use current GPS location',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isGpsLoading ? null : widget.onUseCurrentLocation,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFE8F5EF),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: widget.isGpsLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.emeraldColor,
                      ),
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    size: 19,
                    color: widget.emeraldColor,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Continuous vertical dashed rail painter for the connected transit path.
class _TransitDashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  static const double dashHeight = 3.5;
  static const double dashGap = 2.5;

  const _TransitDashedLinePainter({
    required this.color,
    this.strokeWidth = 2.0,
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
  bool shouldRepaint(covariant _TransitDashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
