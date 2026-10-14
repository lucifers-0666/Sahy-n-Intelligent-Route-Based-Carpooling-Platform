import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/localization/sahyan_language_selector.dart';
import '../../../../core/localization/sahyan_localizations.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../widgets/sahyan_highway_hero.dart';

/// Redesigned 2026 Welcome Screen for Sahyān.
///
/// Features:
/// - Preferred Gujarat highway sunrise illustration locally bundled and rendered
/// - Hero shared-element flight of the master brand mark to the top-left squircle tile
/// - Floating top-right English / Gujarati / Hindi language switcher pill
/// - Route corridor badge ("Ahmedabad → Vadodara") overlapping the lower hero boundary
/// - Content sheet directly beneath the illustration with zero unexplained gaps
/// - Staggered entrance animation: headline -> subline -> trust chips -> action buttons
/// - Standard BMP icons (no surrogate pairs) preventing broken glyphs on all Android versions
/// - ONE primary filled action ("Continue with phone")
/// - Text links for "Use email or password" and "Explore as guest · Browse rides"
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _headlineAnim;
  late final Animation<double> _sublineAnim;
  late final Animation<double> _chipsAnim;
  late final Animation<double> _actionsAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headlineAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
    );
    _sublineAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.20, 0.60, curve: Curves.easeOutCubic),
    );
    _chipsAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );
    _actionsAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _animController.value = 1.0;
      } else {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final bottomPadding = mediaQuery.padding.bottom;
    final l10n = SahyanLocalizations.of(context);

    // Responsive hero height (45-50% of available height)
    final heroHeight = (screenHeight * 0.46).clamp(270.0, 380.0);

    final cardBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.98)
        : Colors.white;
    final borderColor = isDark
        ? AppColors.darkSurfaceHigh
        : AppColors.border.withValues(alpha: 0.85);
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = AppColors.mutedLight;
    final scriptScale = l10n.languageCode == 'en' ? 0.0 : 1.5;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      body: Stack(
        children: [
          // 1. Top Hero Illustration with Top-Left Brand Mark
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: SahyanHighwaySunriseHero(
              height: heroHeight,
              isDark: isDark,
            ),
          ),

          // 2. Language Switcher Floating Badge (Top Right)
          Positioned(
            top: mediaQuery.padding.top + 10,
            right: 18,
            child: SahyanLanguageSelector(isDark: isDark),
          ),

          // 3. Main Content Sheet Starting Immediately Beneath the Hero
          Positioned(
            top: heroHeight - 16,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sheet),
                ),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.40 : 0.08,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24.0,
                        28.0,
                        24.0,
                        math.max(bottomPadding, 16.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Headline
                          FadeTransition(
                            opacity: _headlineAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(_headlineAnim),
                              child: Text(
                                l10n.welcomeHeadline,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: (screenWidth * 0.068).clamp(
                                    24.0,
                                    28.0,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.6,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle
                          FadeTransition(
                            opacity: _sublineAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(_sublineAnim),
                              child: Text(
                                l10n.welcomeSubline,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.0 + scriptScale,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Trust Chips Row ("Verified", "Fair cost", "Direct routes")
                          FadeTransition(
                            opacity: _chipsAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(_chipsAnim),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    _WelcomeTrustChip(
                                      icon: Icons.check_circle,
                                      label: l10n.chipVerified,
                                      isDark: isDark,
                                      fontSize: 12 + scriptScale,
                                    ),
                                    const SizedBox(width: 8),
                                    _WelcomeTrustChip(
                                      icon: Icons.account_balance_wallet,
                                      label: l10n.chipFairCost,
                                      isDark: isDark,
                                      fontSize: 12 + scriptScale,
                                    ),
                                    const SizedBox(width: 8),
                                    _WelcomeTrustChip(
                                      icon: Icons.alt_route,
                                      label: l10n.chipDirectRoutes,
                                      isDark: isDark,
                                      fontSize: 12 + scriptScale,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          FadeTransition(
                            opacity: _actionsAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(_actionsAnim),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Primary Action: Continue with phone
                                  SahyanButton(
                                    text: l10n.continueWithPhone,
                                    icon: Icons.phone_android,
                                    variant: SahyanButtonVariant.primary,
                                    size: SahyanButtonSize.large,
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(userModeProvider.notifier)
                                          .setAuthenticatedMode();
                                      context.push('/login?method=phone');
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // 2. Text Link: Use email or password
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(userModeProvider.notifier)
                                            .setAuthenticatedMode();
                                        context.push('/login?method=password');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.brandBright,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.useEmailOrPassword,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5 + scriptScale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // 3. Text Link: Explore as guest · Browse rides
                                  Center(
                                    child: TextButton.icon(
                                      icon: const Icon(
                                        Icons.explore,
                                        size: 15,
                                      ),
                                      label: Text(l10n.exploreAsGuest),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(userModeProvider.notifier)
                                            .setGuestMode();
                                        context.go('/home');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: mutedColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        textStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 13 + scriptScale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

          // 4. Route Corridor Badge Overlapping the Lower Edge of the Illustration
          Positioned(
            left: 20,
            top: heroHeight - 32,
            child: _RouteCorridorBadge(
              route: 'Ahmedabad → Vadodara',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Route Corridor Badge Overlapping the Hero Seam
class _RouteCorridorBadge extends StatefulWidget {
  final String route;
  final bool isDark;

  const _RouteCorridorBadge({
    required this.route,
    required this.isDark,
  });

  @override
  State<_RouteCorridorBadge> createState() => _RouteCorridorBadgeState();
}

class _RouteCorridorBadgeState extends State<_RouteCorridorBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
        _pulseController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 7 + _pulseController.value * 8,
                    height: 7 + _pulseController.value * 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mint.withValues(
                        alpha: (1.0 - _pulseController.value) * 0.55,
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mint,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            widget.route,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill Trust Chip inside the Welcome Sheet
class _WelcomeTrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final double fontSize;

  const _WelcomeTrustChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceHigh : const Color(0xFFEDF6F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isDark ? AppColors.mint : AppColors.brand).withValues(
            alpha: 0.20,
          ),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.mint : AppColors.brand,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F3D32),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
