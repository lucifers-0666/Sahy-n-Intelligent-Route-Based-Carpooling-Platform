import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import 'sahyan_logo.dart';

/// Animated master brand mark for the Sahyān splash screen.
///
/// Implements the coordinated sequence:
/// 1. Deep emerald canvas
/// 2. Two origin dots appear with smooth scale transition
/// 3. Two route paths draw toward the convergence point and continue as one route (750 ms)
/// 4. Junction node gives one subtle mint pulse (220 ms)
/// 5. Sahyān wordmark reveals and moves into place (300 ms)
/// 6. The official tagline fades in (250 ms)
/// Target total sequence: ~1.6 seconds.
class SahyanAnimatedRouteLogo extends StatefulWidget {
  final double size;
  final bool isDark;
  final bool showWordmark;
  final bool showTagline;
  final Color? wordmarkColor;
  final Color? taglineColor;
  final VoidCallback? onComplete;

  const SahyanAnimatedRouteLogo({
    super.key,
    this.size = 130,
    this.isDark = true,
    this.showWordmark = true,
    this.showTagline = true,
    this.wordmarkColor,
    this.taglineColor,
    this.onComplete,
  });

  @override
  State<SahyanAnimatedRouteLogo> createState() =>
      _SahyanAnimatedRouteLogoState();
}

class _SahyanAnimatedRouteLogoState extends State<SahyanAnimatedRouteLogo>
    with TickerProviderStateMixin {
  late final AnimationController _drawController;
  late final AnimationController _pulseController;
  late final AnimationController _textController;

  late final Animation<double> _drawAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _wordmarkAnimation;
  late final Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Path drawing controller (750 ms)
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOutCubic,
    );

    // 2. Pulse ring controller (220 ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );

    // 3. Typography controller (550 ms: wordmark 300ms, tagline 250ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _wordmarkAnimation = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _taglineAnimation = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.forward();
        _textController.forward();
      }
    });

    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _drawController.value = 1.0;
        _pulseController.value = 1.0;
        _textController.value = 1.0;
        widget.onComplete?.call();
      } else {
        _drawController.forward();
      }
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markColor = widget.isDark ? AppColors.mint : AppColors.brand;
    final wordmarkColor =
        widget.wordmarkColor ??
        (widget.isDark ? Colors.white : AppColors.brand);
    final taglineColor =
        widget.taglineColor ?? AppColors.mint.withValues(alpha: 0.9);

    final letters = ['S', 'a', 'h', 'y', 'ā', 'n'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hero-tagged Master Route Convergence Mark
        Hero(
          tag: 'sahyan_brand_mark',
          child: AnimatedBuilder(
            animation: Listenable.merge([_drawAnimation, _pulseAnimation]),
            builder: (context, _) {
              return SahyanLogo.mark(
                size: widget.size,
                color: markColor,
                progress: _drawAnimation.value,
                pulseProgress: _pulseAnimation.value,
              );
            },
          ),
        ),

        if (widget.showWordmark) ...[
          SizedBox(height: widget.size * 0.16),
          // Wordmark reveal
          AnimatedBuilder(
            animation: _wordmarkAnimation,
            builder: (context, _) {
              final val = _wordmarkAnimation.value;
              return Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 6 * (1.0 - val)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final letter in letters)
                        Text(
                          letter,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: widget.size * 0.32,
                            fontWeight: FontWeight.w800,
                            color: wordmarkColor,
                            letterSpacing: -0.6,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],

        if (widget.showTagline) ...[
          const SizedBox(height: 6),
          // Tagline fade
          AnimatedBuilder(
            animation: _taglineAnimation,
            builder: (context, _) {
              final val = _taglineAnimation.value;
              return Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 4 * (1.0 - val)),
                  child: Text(
                    'Intelligent journeys, shared naturally.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: taglineColor,
                      letterSpacing: 0.2,
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
      color: isDark ? AppColors.brandBright : AppColors.brand,
    );
  }
}
