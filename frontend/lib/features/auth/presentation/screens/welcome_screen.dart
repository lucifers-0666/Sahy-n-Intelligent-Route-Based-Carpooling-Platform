import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../widgets/sahyan_highway_hero.dart';

/// Redesigned 2026 Welcome & Auth Gateway Screen for Sahyān.
///
/// Features:
/// - Original vector hero illustration of Gujarat highway at sunrise with passengers
/// - Frosted glass bottom surface with clean visual hierarchy
/// - Headline: "Share the journey, not just the ride."
/// - Three compact trust indicators on ONE row: "Verified", "Fair cost", "Direct routes"
/// - Primary action: Continue with phone (navigates to Phone OTP primary login)
/// - Secondary action: Explore as guest (for real guest browsing)
/// - Fallback path: Use email instead
/// - Resilient responsive layout avoiding overflow on screens 320dp to 600dp+
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Adapt hero height for short devices
    final heroHeight = (screenHeight * 0.44).clamp(240.0, 380.0);

    final cardBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDark
        ? AppColors.darkSurfaceHigh
        : AppColors.border.withValues(alpha: 0.85);
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      body: Stack(
        children: [
          // 1. Top Hero Illustration (Gujarat Highway Sunrise)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + 36, // overlap beneath bottom card
            child: SahyanHighwaySunriseHero(
              height: heroHeight + 36,
              isDark: isDark,
            ),
          ),

          // 2. Main Content & Glass Bottom Surface
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Status Bar Spacer
                SizedBox(height: heroHeight * 0.72),

                // Frosted Glass Content Surface
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadii.sheet),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadii.sheet),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadii.sheet),
                            ),
                            border: Border(
                              top: BorderSide(color: borderColor, width: 1.2),
                            ),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 20.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Brand Lockup Header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SahyanRouteConvergenceMark(
                                          size: 26,
                                          isDark: isDark,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sahyān',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? AppColors.darkText
                                                : AppColors.brand,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Primary Headline
                                    Text(
                                      'Share the journey, not just the ride.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: (screenWidth * 0.058).clamp(
                                          21.0,
                                          26.0,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                        letterSpacing: -0.4,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Concise Product Message
                                    Text(
                                      'Verified intercity carpooling across Gujarat highway corridors. Connect with trusted companions travelling your exact route.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: mutedColor,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // 3 Compact Trust Indicators on ONE Single Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: const [
                                        _TrustChip(
                                          icon: Icons.verified_user_rounded,
                                          label: 'Verified',
                                        ),
                                        _TrustChip(
                                          icon: Icons.savings_outlined,
                                          label: 'Fair cost',
                                        ),
                                        _TrustChip(
                                          icon: Icons.alt_route_rounded,
                                          label: 'Direct routes',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 26),

                                    // Primary Action: Continue with phone
                                    SahyanButton(
                                      text: 'Continue with phone',
                                      icon: Icons.phone_android_rounded,
                                      variant: SahyanButtonVariant.primary,
                                      size: SahyanButtonSize.regular,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        ref
                                            .read(userModeProvider.notifier)
                                            .setAuthenticatedMode();
                                        context.push('/login');
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Secondary Action: Explore as guest
                                    SahyanButton(
                                      text: 'Explore as guest',
                                      icon: Icons.explore_outlined,
                                      variant: SahyanButtonVariant.secondary,
                                      size: SahyanButtonSize.regular,
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(userModeProvider.notifier)
                                            .setGuestMode();
                                        context.go('/home');
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Small secondary text link: Use email instead
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          context.push(
                                            '/login?method=password',
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.mint
                                              : AppColors.brand,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),
                                        child: Text(
                                          'Use email or password instead',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Trust Chip that fits 3 items on a single row without wrapping
class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceHigh.withValues(alpha: 0.7)
        : AppColors.canvasLight;
    final borderColor = isDark
        ? AppColors.darkSurfaceHigh
        : AppColors.border.withValues(alpha: 0.6);
    final iconColor = isDark ? AppColors.mint : AppColors.brand;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
