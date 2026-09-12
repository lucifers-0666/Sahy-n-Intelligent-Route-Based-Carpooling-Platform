import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/app_startup_provider.dart';
import 'package:sahyan/core/theme/app_theme.dart';

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
                  // Responsive Animated Squircle Container
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: SahyanColors.primaryDark,
                      borderRadius: BorderRadius.circular(logoSize * 0.28),
                      boxShadow: [
                        BoxShadow(
                          color: SahyanColors.primaryDark.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(logoSize * 0.58, logoSize * 0.58),
                          painter: _GeometricCarpoolEmblemPainter(),
                        ),
                        // Mint accent node
                        Positioned(
                          right: logoSize * 0.22,
                          top: logoSize * 0.24,
                          child: Container(
                            width: (logoSize * 0.08).clamp(6.0, 9.0),
                            height: (logoSize * 0.08).clamp(6.0, 9.0),
                            decoration: BoxDecoration(
                              color: SahyanColors.primaryMint,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: SahyanColors.primaryMint.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.15, end: 0, duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.easeOut,
                      ),

                  SizedBox(height: (logoSize * 0.24).clamp(16.0, 24.0)),

                  // App Title
                  const Text(
                    'Sahyān',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.textMain,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 800.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.15, end: 0, duration: 800.ms, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  // Brand Tagline
                  const Text(
                    'SMART ROUTE CARPOOLING',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.textMuted,
                      letterSpacing: 2.0,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 800.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.15, end: 0, duration: 800.ms, curve: Curves.easeOut),

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

/// Custom geometric carpool emblem painter:
/// Two converging route paths forming a minimalist S-symbol.
class _GeometricCarpoolEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Route Path 1 (Top curve forming upper loop of S)
    final path1 = Path();
    path1.moveTo(size.width * 0.25, size.height * 0.35);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.15,
      size.width * 0.75,
      size.height * 0.18,
      size.width * 0.65,
      size.height * 0.45,
    );
    path1.cubicTo(
      size.width * 0.60,
      size.height * 0.55,
      size.width * 0.40,
      size.height * 0.52,
      size.width * 0.35,
      size.height * 0.62,
    );
    path1.cubicTo(
      size.width * 0.28,
      size.height * 0.78,
      size.width * 0.65,
      size.height * 0.85,
      size.width * 0.75,
      size.height * 0.68,
    );

    canvas.drawPath(path1, paint);

    // Accent line representing converging feeder corridor in energetic mint
    final feederPaint = Paint()
      ..color = SahyanColors.primaryMint
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final feederPath = Path();
    feederPath.moveTo(size.width * 0.2, size.height * 0.65);
    feederPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.52,
    );
    canvas.drawPath(feederPath, feederPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
