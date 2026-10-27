import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import 'sahyan_brand_mark.dart';
import 'sahyan_logo.dart';

/// Animated master brand reveal for the Sahyān splash screen.
/// Implements the concept: "Different paths. One shared journey."
///
/// Choreographed 3.0s sequence:
/// 1. Fade in emerald background, origin nodes appear (0 - 300 ms).
/// 2. Draw curved roads from separate origins toward the central hub (150 - 1650 ms = 1500 ms).
/// 3. Animate car along top path and motorcycle along bottom path with tangent rotation (150 - 1650 ms = 1500 ms).
/// 4. Roads converge at central hub, emitting a soft champagne-gold & mint pulse wave (1450 - 1800 ms = 350 ms).
/// 5. Shared vehicle travels forward along the shared horizontal highway.
/// 6. Reveal the Sahyān wordmark with leaf motif using subtle scale and fade (1750 - 2250 ms = 500 ms).
/// 7. Fade in the tagline: "Different paths. One shared journey." (2200 - 2600 ms = 400 ms).
/// 8. Hold final composition (2600 - 3000 ms = 400 ms) before triggering onComplete.
class SahyanAnimatedRouteLogo extends StatefulWidget {
  final double size;
  final bool isDark;
  final bool showWordmark;
  final bool showTagline;
  final String? tagline;
  final Color? wordmarkColor;
  final Color? taglineColor;
  final VoidCallback? onComplete;

  const SahyanAnimatedRouteLogo({
    super.key,
    this.size = 140,
    this.isDark = true,
    this.showWordmark = true,
    this.showTagline = true,
    this.tagline,
    this.wordmarkColor,
    this.taglineColor,
    this.onComplete,
  });

  @override
  State<SahyanAnimatedRouteLogo> createState() =>
      _SahyanAnimatedRouteLogoState();
}

class _SahyanAnimatedRouteLogoState extends State<SahyanAnimatedRouteLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _masterController;
  late final Animation<double> _originAnimation;
  late final Animation<double> _drawAnimation;
  late final Animation<double> _vehicleAnimation;
  late final Animation<double> _hubPulseAnimation;
  late final Animation<double> _wordmarkAnimation;
  late final Animation<double> _taglineAnimation;

  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();

    // 3.0-second coordinated brand reveal animation
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Origin nodes appear (0 to 300 ms)
    _originAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.00, 0.10, curve: Curves.easeOutCubic),
    );

    // 2. Road drawing (150 to 1650 ms = 1500 ms)
    _drawAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.05, 0.55, curve: Curves.easeInOutCubic),
    );

    // 3. Vehicles moving along tangent paths (150 to 1650 ms = 1500 ms)
    _vehicleAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.05, 0.55, curve: Curves.easeInOutCubic),
    );

    // 4. Central Hub pulse ring when vehicles meet (1450 to 1800 ms = 350 ms)
    _hubPulseAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.483, 0.600, curve: Curves.easeOutQuad),
    );

    // 5. Sahyān wordmark scale and fade in (1750 to 2250 ms = 500 ms)
    _wordmarkAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.583, 0.750, curve: Curves.easeOutCubic),
    );

    // 6. Tagline fade in (2200 to 2600 ms = 400 ms)
    _taglineAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.733, 0.867, curve: Curves.easeOut),
    );

    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasCompleted) {
        _hasCompleted = true;
        widget.onComplete?.call();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _masterController.value = 1.0;
        if (!_hasCompleted) {
          _hasCompleted = true;
          widget.onComplete?.call();
        }
      } else {
        _masterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordmarkColor =
        widget.wordmarkColor ??
        (widget.isDark ? Colors.white : AppColors.brand);
    final taglineColor =
        widget.taglineColor ??
        (widget.isDark
            ? AppColors.softMint.withValues(alpha: 0.95)
            : AppColors.mutedLight);
    final effectiveTagline =
        widget.tagline ?? 'Different paths. One shared journey.';

    final letters = ['S', 'a', 'h', 'y', 'ā', 'n'];

    // Proportional dimensions based on size
    final markWidth = widget.size * 1.5;
    final markHeight = widget.size * 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Converging Route Brand Mark ──────────────────────────────────────
        Hero(
          tag: 'sahyan_brand_mark',
          child: AnimatedBuilder(
            animation: _masterController,
            builder: (context, _) {
              return SizedBox(
                width: markWidth,
                height: markHeight,
                child: CustomPaint(
                  painter: SahyanBrandMarkPainter(
                    originProgress: _originAnimation.value,
                    drawProgress: _drawAnimation.value,
                    vehicleProgress: _vehicleAnimation.value,
                    hubPulseProgress: _hubPulseAnimation.value,
                    showVehicles: true,
                    isDark: widget.isDark,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Wordmark Reveal ──────────────────────────────────────────────────
        if (widget.showWordmark) ...[
          SizedBox(height: widget.size * 0.14),
          AnimatedBuilder(
            animation: _wordmarkAnimation,
            builder: (context, _) {
              final val = _wordmarkAnimation.value;
              return Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 10 * (1.0 - val)),
                  child: Transform.scale(
                    scale: 0.94 + (0.06 * val),
                    alignment: Alignment.center,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Letter by letter row for test compatibility and kerning
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final letter in letters)
                              Text(
                                letter,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: widget.size * 0.34,
                                  fontWeight: FontWeight.w800,
                                  color: wordmarkColor,
                                  letterSpacing: -0.6,
                                  height: 1.05,
                                ),
                              ),
                          ],
                        ),

                        // Eco Leaf Accent above the 'y' and 'a'
                        Positioned(
                          top: -widget.size * 0.08,
                          right: widget.size * 0.40,
                          child: Opacity(
                            opacity: (val > 0.4 ? (val - 0.4) / 0.6 : 0.0)
                                .clamp(0.0, 1.0),
                            child: Transform.rotate(
                              angle: -0.15,
                              child: CustomPaint(
                                size: Size(
                                  widget.size * 0.12,
                                  widget.size * 0.12,
                                ),
                                painter: _SahyanLeafPainter(
                                  color: widget.isDark
                                      ? AppColors.softMint
                                      : AppColors.brandBright,
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
            },
          ),
        ],

        // ── Official Tagline Reveal ──────────────────────────────────────────
        if (widget.showTagline) ...[
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _taglineAnimation,
            builder: (context, _) {
              final val = _taglineAnimation.value;
              return Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 6 * (1.0 - val)),
                  child: Text(
                    effectiveTagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: taglineColor,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Custom painter rendering the crisp eco leaf accent above 'y' in the Sahyān wordmark.
class _SahyanLeafPainter extends CustomPainter {
  final Color color;

  const _SahyanLeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leafPath = Path()
      ..moveTo(0, h * 0.70)
      ..cubicTo(w * 0.30, h * 0.10, w * 0.90, 0, w, 0)
      ..cubicTo(w * 0.95, h * 0.60, w * 0.50, h, 0, h * 0.70)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SahyanLeafPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Static route convergence mark for headers, cards, and loaders.
class SahyanRouteConvergenceMark extends StatelessWidget {
  final double size;
  final bool isDark;

  const SahyanRouteConvergenceMark({
    super.key,
    this.size = 32,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return SahyanLogo.mark(
      size: size,
      color: isDark ? AppColors.softMint : AppColors.brand,
    );
  }
}
