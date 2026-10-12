import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/providers/app_startup_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/feedback/sahyan_loader.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';

/// Redesigned 2026 Production Launch & Splash Screen for Sahyān.
///
/// Implements:
/// - Rich forest-green-to-emerald gradient with restrained depth
/// - Radial mint glow behind the converging corridor brand mark
/// - Unique animated route-convergence logo (~1.8s) with static reduced-motion fallback
/// - Seamless startup state resolution without false delays or navigation traps
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isAnimationFinished = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
  }

  void _onAnimationCompleted() {
    if (!mounted) return;
    setState(() {
      _isAnimationFinished = true;
    });
    _evaluateAndNavigate();
  }

  void _evaluateAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final startupState = ref.read(appStartupProvider);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Wait until animation completes (unless reduced motion is enabled)
    if (!_isAnimationFinished && !disableAnimations) {
      return;
    }

    // Still initializing backend session / storage
    if (startupState.status == AppStartupStatus.initializing) {
      return;
    }

    _hasNavigated = true;

    switch (startupState.status) {
      case AppStartupStatus.ready:
        context.go('/home');
        break;
      case AppStartupStatus.onboardingRequired:
        context.go('/onboarding');
        break;
      case AppStartupStatus.authEntryRequired:
        context.go('/welcome');
        break;
      case AppStartupStatus.initializing:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for startup changes
    ref.listen<AppStartupState>(appStartupProvider, (previous, next) {
      if (next.status != AppStartupStatus.initializing) {
        _evaluateAndNavigate();
      }
    });

    final startupState = ref.watch(appStartupProvider);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // If reduced motion is requested, immediately evaluate once startup resolves
    if (disableAnimations &&
        startupState.status != AppStartupStatus.initializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evaluateAndNavigate();
      });
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = (screenWidth * 0.28).clamp(96.0, 120.0);
    final isStillInitializing =
        startupState.status == AppStartupStatus.initializing &&
        _isAnimationFinished;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // 1. Rich Forest-Green to Emerald Canvas Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07382D), // Deep Forest Night
                    Color(0xFF0B5D4B), // Approved Sahyān Brand Green
                    Color(0xFF0F7A5F), // Brand Bright Emerald
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Restrained Mint Radial Depth Glow behind Logo
          Positioned.fill(child: CustomPaint(painter: _SplashGlowPainter())),

          // 3. Centered Brand Lockup (Route Convergence Symbol + Wordmark + Tagline)
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SahyanAnimatedRouteLogo(
                    size: logoSize,
                    isDark: true,
                    showWordmark: true,
                    showTagline: true,
                    wordmarkColor: Colors.white,
                    taglineColor: AppColors.darkMuted,
                    onComplete: _onAnimationCompleted,
                  ),

                  const SizedBox(height: 36),

                  // 4. Subtle Branded Loader only when startup work is still pending
                  AnimatedOpacity(
                    opacity: isStillInitializing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const SizedBox(
                      height: 32,
                      child: SahyanLoader(size: 26, isDark: true),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Pinned Bottom Micro Trust Tag
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: AppColors.mint,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verified Intercity Corridors · Gujarat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _SplashGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final radius = size.width * 0.55;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.mint.withValues(alpha: 0.22),
          AppColors.mint.withValues(alpha: 0.08),
          AppColors.mint.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
