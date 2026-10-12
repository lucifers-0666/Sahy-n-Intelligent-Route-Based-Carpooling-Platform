import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

/// CustomPainter that renders the Sahyān route-convergence symbol.
///
/// Draws two highway corridor trajectories from the left that smoothly
/// sweep into a single shared junction node, with an inner convergence core
/// and radiant focal point.
class SahyanRouteConvergencePainter extends CustomPainter {
  /// Progress of the drawing paths [0.0, 1.0]
  final double strokeProgress;

  /// Progress of the junction node pulse [0.0, 1.0]
  final double pulseProgress;

  /// Opacity of the settled filled shape [0.0, 1.0]
  final double fillOpacity;

  /// Color palette overrides (auto-adapts if null)
  final Color? brandColor;
  final Color? mintColor;
  final bool isDark;

  SahyanRouteConvergencePainter({
    this.strokeProgress = 1.0,
    this.pulseProgress = 1.0,
    this.fillOpacity = 1.0,
    this.brandColor,
    this.mintColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.scale(scale, scale);

    final brand =
        brandColor ?? (isDark ? AppColors.brandBright : AppColors.brand);
    final mint = mintColor ?? AppColors.mint;

    // Define the Upper Planned Corridor (Driver route)
    final upperPath = Path();
    upperPath.moveTo(20, 30);
    upperPath.cubicTo(36, 30, 50, 42, 64, 55);
    upperPath.lineTo(82, 55);

    // Define the Lower Matched Trajectory (Passenger route)
    final lowerPath = Path();
    lowerPath.moveTo(20, 90);
    lowerPath.cubicTo(36, 90, 50, 78, 64, 65);
    lowerPath.lineTo(82, 65);

    // Dynamic Convergence Junction Shape
    final junctionPath = Path();
    junctionPath.moveTo(56, 60);
    junctionPath.lineTo(78, 44);
    junctionPath.cubicTo(82, 41, 86, 43, 86, 48);
    junctionPath.lineTo(86, 72);
    junctionPath.cubicTo(86, 77, 82, 79, 78, 76);
    junctionPath.close();

    // 1. Draw animated stroke trajectories via PathMetric
    if (strokeProgress > 0) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Upper Corridor stroke
      for (final metric in upperPath.computeMetrics()) {
        final extractLength = metric.length * strokeProgress.clamp(0.0, 1.0);
        final segment = metric.extractPath(0, extractLength);
        strokePaint.shader = LinearGradient(
          colors: [
            isDark
                ? AppColors.mint.withValues(alpha: 0.6)
                : brand.withValues(alpha: 0.8),
            brand,
          ],
        ).createShader(const Rect.fromLTWH(20, 20, 80, 80));
        canvas.drawPath(segment, strokePaint);
      }

      // Lower Corridor stroke
      for (final metric in lowerPath.computeMetrics()) {
        final extractLength = metric.length * strokeProgress.clamp(0.0, 1.0);
        final segment = metric.extractPath(0, extractLength);
        strokePaint.shader = LinearGradient(
          colors: [
            isDark
                ? AppColors.brandBright.withValues(alpha: 0.6)
                : mint.withValues(alpha: 0.8),
            brand,
          ],
        ).createShader(const Rect.fromLTWH(20, 20, 80, 80));
        canvas.drawPath(segment, strokePaint);
      }
    }

    // 2. Draw settled filled shapes once strokes converge
    if (fillOpacity > 0.05) {
      final fullUpper = Path()
        ..moveTo(22, 28)
        ..cubicTo(36, 28, 52, 40, 64, 54)
        ..lineTo(88, 54)
        ..cubicTo(92, 54, 94, 57, 92, 60)
        ..lineTo(76, 74)
        ..cubicTo(73, 76, 69, 74, 69, 70)
        ..lineTo(69, 66)
        ..cubicTo(58, 56, 46, 44, 22, 44)
        ..cubicTo(18, 44, 16, 40, 16, 36)
        ..cubicTo(16, 32, 18, 28, 22, 28)
        ..close();

      final fullLower = Path()
        ..moveTo(22, 92)
        ..cubicTo(36, 92, 52, 80, 64, 66)
        ..lineTo(88, 66)
        ..cubicTo(92, 66, 94, 63, 92, 60)
        ..lineTo(76, 46)
        ..cubicTo(73, 44, 69, 46, 69, 50)
        ..lineTo(69, 54)
        ..cubicTo(58, 64, 46, 76, 22, 76)
        ..cubicTo(18, 76, 16, 80, 16, 84)
        ..cubicTo(16, 88, 18, 92, 22, 92)
        ..close();

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = (isDark ? Colors.white : brand).withValues(
          alpha: fillOpacity.clamp(0.0, 1.0),
        );

      canvas.drawPath(fullUpper, fillPaint);
      canvas.drawPath(fullLower, fillPaint);

      // Dynamic Junction Core Fill
      final corePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mint.withValues(alpha: fillOpacity),
            AppColors.brandBright.withValues(alpha: fillOpacity),
          ],
        ).createShader(const Rect.fromLTWH(56, 44, 30, 32));

      canvas.drawPath(junctionPath, corePaint);
    }

    // 3. Focal Convergence Node with pulse glow
    if (strokeProgress > 0.4) {
      final nodeCenter = const Offset(68, 60);
      final pulse = (pulseProgress.clamp(0.0, 1.0));

      // Glow halo
      final glowRadius = (14.0 * pulse).clamp(4.0, 18.0);
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = mint.withValues(
          alpha: (0.5 * (1.0 - (pulse - 1.0).abs())).clamp(0.0, 0.6),
        );
      canvas.drawCircle(nodeCenter, glowRadius, glowPaint);

      // Solid central junction node
      final nodePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isDark ? AppColors.darkText : Colors.white;
      canvas.drawCircle(nodeCenter, 4.5, nodePaint);

      // Inner mint dot
      final innerDotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = brand;
      canvas.drawCircle(nodeCenter, 2.0, innerDotPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SahyanRouteConvergencePainter oldDelegate) {
    return oldDelegate.strokeProgress != strokeProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.fillOpacity != fillOpacity ||
        oldDelegate.brandColor != brandColor ||
        oldDelegate.mintColor != mintColor ||
        oldDelegate.isDark != isDark;
  }
}

/// Static, lightweight vector representation of the Sahyān route mark.
class SahyanRouteConvergenceMark extends StatelessWidget {
  final double size;
  final Color? brandColor;
  final Color? mintColor;
  final bool? isDark;

  const SahyanRouteConvergenceMark({
    super.key,
    this.size = 48.0,
    this.brandColor,
    this.mintColor,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SahyanRouteConvergencePainter(
          strokeProgress: 1.0,
          pulseProgress: 1.0,
          fillOpacity: 1.0,
          brandColor: brandColor,
          mintColor: mintColor,
          isDark: effectiveIsDark,
        ),
      ),
    );
  }
}

/// High-fidelity animated Sahyān brand mark with route-convergence motion.
class SahyanAnimatedRouteLogo extends StatefulWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;
  final VoidCallback? onComplete;
  final bool loop;
  final bool isDark;
  final Color? wordmarkColor;
  final Color? taglineColor;

  const SahyanAnimatedRouteLogo({
    super.key,
    this.size = 110.0,
    this.showWordmark = true,
    this.showTagline = true,
    this.onComplete,
    this.loop = false,
    this.isDark = true,
    this.wordmarkColor,
    this.taglineColor,
  });

  @override
  State<SahyanAnimatedRouteLogo> createState() =>
      _SahyanAnimatedRouteLogoState();
}

class _SahyanAnimatedRouteLogoState extends State<SahyanAnimatedRouteLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _strokeAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fillAnimation;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineFade;
  bool _hasNotifiedComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 0 -> 900ms (0.0 to 0.5): Corridor strokes draw in & converge
    _strokeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.52, curve: Curves.easeOutCubic),
    );

    // 600 -> 1100ms (0.33 to 0.62): Node pulses with mint glow
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.4),
            weight: 45,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.4, end: 1.0),
            weight: 55,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.65, curve: Curves.easeInOut),
          ),
        );

    // 700 -> 1200ms (0.4 to 0.68): Static brand mark fills and resolves
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.70, curve: Curves.easeIn),
    );

    // 1000 -> 1600ms (0.55 to 0.9): Wordmark reveals smoothly
    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.88, curve: Curves.easeOut),
    );
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 0.88, curve: Curves.easeOutCubic),
          ),
        );

    // 1300 -> 1800ms (0.72 to 1.0): Tagline fades in
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.loop) {
          _controller.repeat();
        } else if (!_hasNotifiedComplete) {
          _hasNotifiedComplete = true;
          widget.onComplete?.call();
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect system reduced-motion preference
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      if (!_hasNotifiedComplete) {
        _hasNotifiedComplete = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete?.call();
        });
      }
      return _buildStaticVersion();
    }

    final wordmarkColor =
        widget.wordmarkColor ??
        (widget.isDark ? AppColors.darkText : AppColors.brand);
    final taglineColor =
        widget.taglineColor ??
        (widget.isDark ? AppColors.darkMuted : AppColors.mutedLight);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Center Brand Convergence Mark
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: SahyanRouteConvergencePainter(
                  strokeProgress: _strokeAnimation.value,
                  pulseProgress: _pulseAnimation.value,
                  fillOpacity: _fillAnimation.value,
                  isDark: widget.isDark,
                ),
              ),
            ),

            if (widget.showWordmark) ...[
              const SizedBox(height: 16),
              SlideTransition(
                position: _wordmarkSlide,
                child: FadeTransition(
                  opacity: _wordmarkFade,
                  child: Text(
                    'Sahyān',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: (widget.size * 0.32).clamp(26.0, 38.0),
                      fontWeight: FontWeight.w800,
                      color: wordmarkColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
            ],

            if (widget.showTagline) ...[
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'Where journeys find company',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: (widget.size * 0.13).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w500,
                    color: taglineColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStaticVersion() {
    final wordmarkColor =
        widget.wordmarkColor ??
        (widget.isDark ? AppColors.darkText : AppColors.brand);
    final taglineColor =
        widget.taglineColor ??
        (widget.isDark ? AppColors.darkMuted : AppColors.mutedLight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SahyanRouteConvergenceMark(size: widget.size, isDark: widget.isDark),
        if (widget.showWordmark) ...[
          const SizedBox(height: 16),
          Text(
            'Sahyān',
            style: GoogleFonts.plusJakartaSans(
              fontSize: (widget.size * 0.32).clamp(26.0, 38.0),
              fontWeight: FontWeight.w800,
              color: wordmarkColor,
              letterSpacing: -0.6,
            ),
          ),
        ],
        if (widget.showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Where journeys find company',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: (widget.size * 0.13).clamp(12.0, 15.0),
              fontWeight: FontWeight.w500,
              color: taglineColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}
