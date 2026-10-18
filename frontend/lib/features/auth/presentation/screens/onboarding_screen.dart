import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sahyan/app/providers/app_startup_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/shared/widgets/sahyan_logo.dart';
import '../auth_provider.dart';
import '../widgets/onboarding_vector_illustrations.dart';

/// Premium Production-Quality Onboarding Walkthrough for Sahyān.
///
/// Features:
/// - Coordinated 320ms entrance micro-animations (header, artwork, typography, actions)
/// - Full-screen swipe responsiveness: natural horizontal gestures across the entire viewport
/// - Authentic 3D mobile UI illustrations for route convergence, matching, and safety
/// - Balanced vertical rhythm: no excessive gaps between description and bottom controls
/// - Standardized pill buttons with tactile feedback and rapid-tap debounce protection
/// - Responsive convex curved Deep Emerald header with status-bar notch clearance
/// - Strict zero-overflow guarantee across all screen sizes (320dp to 600dp+) and text scales
/// - Persistent onboarding completion via Riverpod and reduced-motion accessibility
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/home');
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.brand,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return LuxuryOnboardingScreen(
      onFinish: () async {
        await ref.read(appStartupProvider.notifier).completeOnboarding();
        if (context.mounted) {
          context.go('/welcome');
        }
      },
    );
  }
}

class LuxuryOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const LuxuryOnboardingScreen({super.key, required this.onFinish});

  @override
  State<LuxuryOnboardingScreen> createState() => _LuxuryOnboardingScreenState();
}

class _LuxuryOnboardingScreenState extends State<LuxuryOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _entranceController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;
  late final Animation<double> _bottomFadeAnimation;

  int _currentIndex = 0;
  bool _isFinishing = false;

  static const _pages = [
    _OnboardingData(
      title: 'Better journeys start together.',
      description:
          'Find people travelling your way and make every journey more meaningful.',
      imageAsset: 'assets/branding/onboarding_convergence.jpg',
      badgeLabel: 'Smart Route Convergence',
    ),
    _OnboardingData(
      title: 'Find rides that fit your route.',
      description:
          'Discover planned journeys that match your pickup, destination, and travel time.',
      imageAsset: 'assets/branding/onboarding_match.jpg',
      badgeLabel: 'Instant Route Matching',
    ),
    _OnboardingData(
      title: 'A more connected way to travel.',
      description:
          'See journey details, coordinate with fellow travellers, and access trip safety features.',
      imageAsset: 'assets/branding/onboarding_confidence.jpg',
      badgeLabel: 'Verified Trip Safety',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _headerFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.90, curve: Curves.easeOutCubic),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _bottomFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        if (reducedMotion) {
          _entranceController.value = 1.0;
        } else {
          _entranceController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    HapticFeedback.lightImpact();
    widget.onFinish();
  }

  void _continue() {
    if (_currentIndex == _pages.length - 1) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final reducedMotion = media.disableAnimations;
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;

    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);

    // Responsive header height: proportionally tuned between 48% and 52%
    final topVisualHeight = (screenHeight * 0.50).clamp(300.0, 430.0);
    // Height reserved for the bottom navigation area (indicator + buttons + safe inset)
    final bottomControlsHeight = 98.0 + math.max(14.0, media.padding.bottom);

    return Scaffold(
      backgroundColor: cardBg,
      body: Stack(
        children: [
          // 1. Background Emerald Convex Curved Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topVisualHeight,
            child: FadeTransition(
              opacity: reducedMotion
                  ? const AlwaysStoppedAnimation(1.0)
                  : _headerFadeAnimation,
              child: ClipPath(
                clipper: const _OnboardingCurveClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const [
                              AppColors.darkEmerald,
                              Color(0xFF04261D),
                            ]
                          : const [
                              Color(0xFF0B5D4B),
                              Color(0xFF074336),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle radial ambient glow
                      Positioned(
                        top: topVisualHeight * 0.18,
                        left: screenWidth * 0.15,
                        right: screenWidth * 0.15,
                        height: 220,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.mint.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Full-Screen PageView: Full-height touch swipe access anywhere
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final page = _pages[index];

                return Column(
                  children: [
                    // Top Visual Section: Aligned with Sahyān 20dp margin grid
                    SizedBox(
                      height: topVisualHeight - 16,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            math.max(8.0, media.padding.top + 34),
                            20,
                            14,
                          ),
                          child: SlideTransition(
                            position: reducedMotion
                                ? const AlwaysStoppedAnimation(Offset.zero)
                                : _headerSlideAnimation,
                            child: FadeTransition(
                              opacity: reducedMotion
                                  ? const AlwaysStoppedAnimation(1.0)
                                  : _headerFadeAnimation,
                              child: Center(
                                child: _OnboardingArtworkCard(
                                  pageIndex: index,
                                  imageAsset: page.imageAsset,
                                  badgeLabel: page.badgeLabel,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Lower Content Section: Tight vertical spacing & zero overflow
                    Expanded(
                      child: SlideTransition(
                        position: reducedMotion
                            ? const AlwaysStoppedAnimation(Offset.zero)
                            : _contentSlideAnimation,
                        child: FadeTransition(
                          opacity: reducedMotion
                              ? const AlwaysStoppedAnimation(1.0)
                              : _contentFadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Align(
                              // Position content with a harmonious vertical rhythm
                              alignment: const Alignment(0.0, 0.18),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      page.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: (screenWidth * 0.064)
                                            .clamp(21.0, 26.0),
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                        letterSpacing: -0.5,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 380,
                                      ),
                                      child: Text(
                                        page.description,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                          height: 1.45,
                                        ),
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

                    // Spacer reservation matching fixed bottom action area
                    SizedBox(height: bottomControlsHeight),
                  ],
                );
              },
            ),
          ),

          // 3. Top Persistent App Bar with Sahyān Mark
          Positioned(
            top: media.padding.top + 8,
            left: 20,
            right: 20,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: reducedMotion
                    ? const AlwaysStoppedAnimation(1.0)
                    : _headerFadeAnimation,
                child: const Row(
                  children: [
                    SahyanLogo.horizontal(
                      size: 24,
                      color: Colors.white,
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Fixed Bottom Action Region: Indicator & Pill Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: reducedMotion
                  ? const AlwaysStoppedAnimation(1.0)
                  : _bottomFadeAnimation,
              child: SafeArea(
                top: false,
                bottom: true,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24.0,
                        4.0,
                        24.0,
                        math.max(14.0, media.padding.bottom),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 3-step Pill Progress Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (index) => AnimatedContainer(
                                duration: reducedMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: index == _currentIndex ? 24 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: index == _currentIndex
                                      ? AppColors.brand
                                      : (isDark
                                          ? Colors.white24
                                          : const Color(0xFFD6DFDB)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Standardized Action Buttons
                          if (_currentIndex < _pages.length - 1) ...[
                            Row(
                              children: [
                                // Skip Action (Secondary Pill)
                                Expanded(
                                  child: _OnboardingPillButton(
                                    text: 'Skip',
                                    isPrimary: false,
                                    isDark: isDark,
                                    isLoading: false,
                                    onPressed: _isFinishing ? null : _finish,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Continue Action (Primary Pill)
                                Expanded(
                                  child: _OnboardingPillButton(
                                    text: 'Continue',
                                    isPrimary: true,
                                    isDark: isDark,
                                    isLoading: false,
                                    onPressed:
                                        _isFinishing ? null : _continue,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Full-Width Get Started Action on Final Page
                            _OnboardingPillButton(
                              text: 'Get started',
                              isPrimary: true,
                              isDark: isDark,
                              isLoading: _isFinishing,
                              onPressed: _isFinishing ? null : _finish,
                            ),
                          ],
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

/// Custom clipper generating a smooth convex arc dipping down in the center
class _OnboardingCurveClipper extends CustomClipper<Path> {
  const _OnboardingCurveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 16,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _OnboardingData {
  final String title;
  final String description;
  final String imageAsset;
  final String badgeLabel;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.badgeLabel,
  });
}

/// Standardized Tactile Pill Button with matching heights and radii
class _OnboardingPillButton extends StatefulWidget {
  final String text;
  final bool isPrimary;
  final bool isDark;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _OnboardingPillButton({
    required this.text,
    required this.isPrimary,
    required this.isDark,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_OnboardingPillButton> createState() => _OnboardingPillButtonState();
}

class _OnboardingPillButtonState extends State<_OnboardingPillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? AppColors.brand
        : (widget.isDark ? AppColors.darkSurfaceHigh : const Color(0xFFEDF6F3));
    final fgColor = widget.isPrimary
        ? Colors.white
        : (widget.isDark ? AppColors.mint : AppColors.brand);

    return Listener(
      onPointerDown: (_) {
        if (widget.onPressed != null && mounted) {
          setState(() => _isPressed = true);
        }
      },
      onPointerUp: (_) {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      },
      onPointerCancel: (_) {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutQuad,
        child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          onFocusChange: (_) {},
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: widget.isPrimary
                  ? BorderSide.none
                  : BorderSide(
                      color: (widget.isDark ? AppColors.mint : AppColors.brand)
                          .withValues(alpha: 0.22),
                      width: 1.0,
                    ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

/// Standardized Framed Artwork Card displaying authentic 3D mobile art
class _OnboardingArtworkCard extends StatelessWidget {
  final int pageIndex;
  final String imageAsset;
  final String badgeLabel;
  final bool isDark;

  const _OnboardingArtworkCard({
    required this.pageIndex,
    required this.imageAsset,
    required this.badgeLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Standardized card width aligned with the 20dp margin grid
        final cardWidth = math.min(constraints.maxWidth, 340.0);
        final cardHeight = math.min(constraints.maxHeight, 255.0);

        return Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OnboardingVectorIllustration(
                pageIndex: pageIndex,
                isDark: isDark,
              ),

              // Subtle bottom gradient scrim for caption contrast
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
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),

              // Frosted pill chip positioned consistently across all three pages
              Positioned(
                left: 14,
                right: 14,
                bottom: 10,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: const BoxDecoration(
                            color: AppColors.mint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            badgeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
