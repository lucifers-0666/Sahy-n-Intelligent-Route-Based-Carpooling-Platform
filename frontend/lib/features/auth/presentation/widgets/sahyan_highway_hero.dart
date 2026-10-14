import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/sahyan_logo.dart';

/// Hero Illustration Component for the Sahyān Welcome Screen.
///
/// Features:
/// - Locally bundled Gujarat highway illustration (offline-first, no remote dependency)
/// - Robust loading with fallback from .webp to .jpg
/// - Full-bleed display with deliberate BoxFit.cover and Alignment.topCenter
/// - Slow ambient zoom (1.0 to 1.02 over 14s, reduced-motion aware)
/// - Top-left master brand mark tile with Hero shared-element transition
class SahyanHighwaySunriseHero extends StatefulWidget {
  final double height;
  final bool isDark;

  const SahyanHighwaySunriseHero({
    super.key,
    this.height = 360,
    this.isDark = false,
  });

  @override
  State<SahyanHighwaySunriseHero> createState() =>
      _SahyanHighwaySunriseHeroState();
}

class _SahyanHighwaySunriseHeroState extends State<SahyanHighwaySunriseHero>
    with SingleTickerProviderStateMixin {
  static const _heroWebp = 'assets/branding/sahyan_highway_hero.webp';
  static const _heroJpg = 'assets/branding/sahyan_highway_hero.jpg';

  late final AnimationController _zoomController;
  bool? _animationsEnabled;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up image asset cache safely without ResizeImage decode restrictions
    unawaited(precacheImage(const AssetImage(_heroWebp), context));

    final media = MediaQuery.of(context);
    final shouldAnimate = !media.disableAnimations;
    if (_animationsEnabled == shouldAnimate) return;
    _animationsEnabled = shouldAnimate;

    if (!shouldAnimate) {
      _zoomController.stop();
      return;
    }

    _zoomController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient Background Base (Sunrise sky tone)
            const ColoredBox(color: Color(0xFFD4EAE2)),

            // 2. Full-bleed Gujarat Highway Illustration with Subtle Ambient Zoom
            AnimatedBuilder(
              animation: _zoomController,
              builder: (context, child) {
                final scale = _animationsEnabled == false
                    ? 1.0
                    : 1.0 + (_zoomController.value * 0.02);
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: Image.asset(
                _heroWebp,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    _heroJpg,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(color: AppColors.heroSky);
                    },
                  );
                },
              ),
            ),

            // 3. Ambient Dark Mode Tint
            if (widget.isDark)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),

            // 4. Subtle Bottom Gradient to seamlessly meet the lower sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (widget.isDark ? AppColors.darkBg : AppColors.canvasLight)
                          .withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Top-Left Master Logo Squircle Tile (Hero shared-element from splash)
            Positioned(
              top: topPadding + 10,
              left: 18,
              child: Hero(
                tag: 'sahyan_brand_mark',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SahyanLogo.mark(size: 24, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
