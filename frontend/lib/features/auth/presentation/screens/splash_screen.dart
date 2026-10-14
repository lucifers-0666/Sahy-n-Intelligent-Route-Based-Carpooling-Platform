import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers/app_startup_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';

/// Redesigned 2026 Production Launch & Splash Screen for Sahyān.
///
/// Implements:
/// - Rich forest-green-to-emerald gradient with restrained depth
/// - Radial mint glow behind the converging corridor brand mark
/// - Animated route-convergence logo (under one second) with reduced-motion fallback
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
    if (startupState.status == AppStartupStatus.ready) {
      _hasNavigated = true;
      context.go('/home');
      return;
    }

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
    final mediaQuery = MediaQuery.of(context);
    final disableAnimations = mediaQuery.disableAnimations;

    // If reduced motion is requested, immediately evaluate once startup resolves
    if (disableAnimations &&
        startupState.status != AppStartupStatus.initializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evaluateAndNavigate();
      });
    }

    const logoSize = 92.0;

    if (startupState.status == AppStartupStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evaluateAndNavigate();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.brand)),
          Center(
            child: SahyanAnimatedRouteLogo(
              size: logoSize,
              isDark: true,
              showWordmark: true,
              showTagline: true,
              wordmarkColor: Colors.white,
              taglineColor: Colors.white.withValues(alpha: 0.9),
              onComplete: _onAnimationCompleted,
            ),
          ),
        ],
      ),
    );
  }
}
