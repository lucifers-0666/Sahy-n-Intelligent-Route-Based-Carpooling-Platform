import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';
import 'package:sahyan/shared/widgets/sahyan_logo.dart';

class AuthDecisionScreen extends ConsumerWidget {
  const AuthDecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final emblemSize = (screenWidth * 0.22).clamp(72.0, 92.0);

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Top Hero Section: Ambient radial glow with Deep Pine Squircle Emblem
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Mint Ambient Radial Glow
                        Container(
                          width: emblemSize * 1.5,
                          height: emblemSize * 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                SahyanColors.primaryLight,
                                SahyanColors.primaryLight.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Pine Squircle Container with Carpool Emblem
                        Container(
                          width: emblemSize,
                          height: emblemSize,
                          decoration: BoxDecoration(
                            color: SahyanColors.primaryDark,
                            borderRadius: BorderRadius.circular(emblemSize * 0.28),
                            boxShadow: [
                              BoxShadow(
                                color: SahyanColors.primaryDark.withValues(alpha: 0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SahyanLogo(
                              variant: SahyanLogoVariant.symbolOnly,
                              theme: SahyanLogoTheme.monochromeWhite,
                              size: emblemSize * 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Brand Title
                  const Text(
                    'Sahyān',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.primaryDark,
                      letterSpacing: -0.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  // Headline
                  const Text(
                    'Where Journeys Find Company',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.textMain,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    "India's premier verified intercity highway carpooling network.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SahyanColors.textMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Responsive Trust Badges — Wrap reflows on narrow screens
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _TrustBadge(
                        icon: Icons.verified_user_rounded,
                        label: '✓ Verified Profiles',
                      ),
                      _TrustBadge(
                        icon: Icons.shield_outlined,
                        label: '🛡️ Fair Cost Sharing',
                      ),
                      _TrustBadge(
                        icon: Icons.bolt_rounded,
                        label: '⚡ Direct Routes',
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Auth Actions Bento Container
                  BentoContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary Button: Create an Account (with 0.97x press scale)
                        _ScaleTap(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(userModeProvider.notifier)
                                .setAuthenticatedMode();
                            context.push('/register');
                          },
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(userModeProvider.notifier)
                                    .setAuthenticatedMode();
                                context.push('/register');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SahyanColors.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Create an Account',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Secondary Button: Log In (with 0.97x press scale)
                        _ScaleTap(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(userModeProvider.notifier)
                                .setAuthenticatedMode();
                            context.push('/login');
                          },
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(userModeProvider.notifier)
                                    .setAuthenticatedMode();
                                context.push('/login');
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: SahyanColors.surface,
                                foregroundColor: SahyanColors.textMain,
                                side: const BorderSide(
                                  color: SahyanColors.border,
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.login_rounded,
                                      size: 18,
                                      color: SahyanColors.primaryDark,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: SahyanColors.textMain,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // OR Divider
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: SahyanColors.border,
                                height: 1,
                                thickness: 0.8,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.0),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: SahyanColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: SahyanColors.border,
                                height: 1,
                                thickness: 0.8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Explore as Guest Card (with 0.97x press scale)
                        _ScaleTap(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(userModeProvider.notifier).setGuestMode();
                            context.go('/home');
                          },
                          child: Material(
                            color: SahyanColors.canvas,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                ref.read(userModeProvider.notifier).setGuestMode();
                                context.go('/home');
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: SahyanColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: SahyanColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.explore_outlined,
                                        color: SahyanColors.primaryDark,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Explore as Guest',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: SahyanColors.textMain,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Browse active corridors and fair pricing without signing in',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: SahyanColors.textMuted,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: SahyanColors.textMuted,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Responsive trust badge capsule — used inside a Wrap for narrow-screen reflow.
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: SahyanColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SahyanColors.primaryMint.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SahyanColors.primaryMint),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SahyanColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a child with AnimatedScale (0.97×) on tap — premium press feel.
class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
