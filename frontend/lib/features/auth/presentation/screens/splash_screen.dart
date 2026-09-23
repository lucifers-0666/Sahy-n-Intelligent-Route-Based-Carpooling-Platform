import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/app_startup_provider.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/shared/widgets/sahyan_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _handleNavigation(AppStartupStatus status) {
    if (!mounted) return;
    switch (status) {
      case AppStartupStatus.onboardingRequired:
        context.go('/onboarding');
        break;
      case AppStartupStatus.authEntryRequired:
        context.go('/auth-entry');
        break;
      case AppStartupStatus.ready:
        context.go('/home');
        break;
      case AppStartupStatus.initializing:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppStartupState>(appStartupProvider, (previous, next) {
      if (next.status != AppStartupStatus.initializing) {
        _handleNavigation(next.status);
      }
    });

    final startupState = ref.watch(appStartupProvider);
    if (startupState.status != AppStartupStatus.initializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(startupState.status);
      });
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = (screenWidth * 0.22).clamp(80.0, 108.0);

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      body: Stack(
        children: [
          // Ambient radial glow in soft mint
          Positioned.fill(
            child: CustomPaint(
              painter: _AmbientGlowPainter(),
            ),
          ),

          // Center Brand Lockup with Responsive Clamping & Fluid Layout
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Official Sahyān Brand Identity (Converging Corridor Symbol + Wordmark + Tagline)
                  Container(
                    padding: EdgeInsets.all((logoSize * 0.16).clamp(16.0, 24.0)),
                    decoration: BoxDecoration(
                      color: SahyanColors.surface,
                      borderRadius: BorderRadius.circular(logoSize * 0.28),
                      border: Border.all(
                        color: SahyanColors.border,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SahyanColors.primaryDark.withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: SahyanLogo(
                      variant: SahyanLogoVariant.stacked,
                      theme: SahyanLogoTheme.primaryGreen,
                      size: (logoSize * 0.72).clamp(72.0, 100.0),
                      showTagline: true,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.12, end: 0, duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 32),

                  // Discreet 3-dot mint animated pulse
                  const _PulsingMintDots()
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms),
                ],
              ),
            ),
          ),

          // Bottom Pinned Zone (SafeArea constrained)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: SahyanColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SahyanColors.border, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: SahyanColors.textMain.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        size: 14,
                        color: SahyanColors.primaryMint,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Verified Intercity Corridors · Gujarat 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: SahyanColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 700.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Discreet 3 small mint dots oscillating gently
class _PulsingMintDots extends StatelessWidget {
  const _PulsingMintDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: SahyanColors.primaryMint,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
              delay: (index * 180).ms,
            )
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.3, 1.3),
              duration: 600.ms,
              curve: Curves.easeInOut,
            )
            .fade(begin: 0.35, end: 1.0);
      }),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          SahyanColors.primaryLight.withValues(alpha: 0.9),
          SahyanColors.primaryLight.withValues(alpha: 0.0),
        ],
        radius: 0.85,
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));

    canvas.drawCircle(center, size.width * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

