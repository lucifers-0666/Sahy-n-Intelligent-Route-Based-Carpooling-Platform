import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers/app_startup_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../auth_provider.dart';

/// Redesigned Minimal & Premium Splash Screen for Sahyān.
///
/// Features:
/// - Full-screen Deep Emerald background (#0B5D4B) with subtle radial route glow
/// - Centered animated route-convergence brand mark with vehicles, wordmark, and tagline
/// - Tagline: "Different paths. One shared journey."
/// - Minimalist circular loading indicator only if startup takes longer than the animation
/// - Safe 3.5s timeout prevents hanging indefinitely on backend/storage delays
/// - Honors reduced-motion accessibility preferences
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isAnimationFinished = false;
  bool _hasNavigated = false;
  Timer? _safetyTimeoutTimer;

  @override
  void initState() {
    super.initState();
    // Safety fallback: Never block user indefinitely if storage or backend is slow
    _safetyTimeoutTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && !_hasNavigated) {
        _isAnimationFinished = true;
        _evaluateAndNavigate(force: true);
      }
    });
  }

  @override
  void dispose() {
    _safetyTimeoutTimer?.cancel();
    super.dispose();
  }

  void _onAnimationCompleted() {
    if (!mounted) return;
    setState(() {
      _isAnimationFinished = true;
    });
    _evaluateAndNavigate();
  }

  void _evaluateAndNavigate({bool force = false}) {
    if (_hasNavigated || !mounted) return;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Ensure the brand convergence animation completes unless reduced-motion is requested or forced
    if (!_isAnimationFinished && !disableAnimations && !force) {
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      _hasNavigated = true;
      _safetyTimeoutTimer?.cancel();
      context.go('/home');
      return;
    }

    final startupState = ref.read(appStartupProvider);

    // Still initializing backend session / storage
    if (startupState.status == AppStartupStatus.initializing && !force) {
      return;
    }

    _hasNavigated = true;
    _safetyTimeoutTimer?.cancel();

    switch (startupState.status) {
      case AppStartupStatus.ready:
        context.go('/home');
        break;
      case AppStartupStatus.onboardingRequired:
        context.go('/onboarding');
        break;
      case AppStartupStatus.authEntryRequired:
      case AppStartupStatus.initializing:
        context.go('/welcome');
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

    // Listen for auth changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _evaluateAndNavigate();
      }
    });

    final startupState = ref.watch(appStartupProvider);
    final mediaQuery = MediaQuery.of(context);
    final disableAnimations = mediaQuery.disableAnimations;

    // If reduced motion is requested, immediately evaluate once startup resolves
    if (disableAnimations &&
        startupState.status != AppStartupStatus.initializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evaluateAndNavigate();
      });
    }

    // Show elegant bottom spinner only if animation completed but startup is still waiting
    final showWaitingLoader =
        _isAnimationFinished &&
        startupState.status == AppStartupStatus.initializing;

    // Responsive size: keeps balanced layout on narrow screens (320dp) up to large displays
    final logoSize = (mediaQuery.size.width * 0.32).clamp(90.0, 135.0);

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Stack(
        children: [
          // Deep Emerald Canvas (#0B5D4B)
          const Positioned.fill(child: ColoredBox(color: AppColors.brand)),

          // Subtle Route Ambient Glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.15),
                  radius: 0.85,
                  colors: [
                    AppColors.brandBright.withValues(alpha: 0.35),
                    AppColors.mintGlow.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Centered Brand Symbol + Vehicles + Wordmark + Tagline
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SahyanAnimatedRouteLogo(
                  size: logoSize,
                  isDark: true,
                  showWordmark: true,
                  showTagline: true,
                  wordmarkColor: Colors.white,
                  taglineColor: Colors.white.withValues(alpha: 0.90),
                  onComplete: _onAnimationCompleted,
                ),
              ),
            ),
          ),

          // Minimalist bottom loader (only if startup genuinely takes longer than animation)
          Positioned(
            left: 0,
            right: 0,
            bottom: mediaQuery.padding.bottom + 48,
            child: AnimatedOpacity(
              opacity: showWaitingLoader ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
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
