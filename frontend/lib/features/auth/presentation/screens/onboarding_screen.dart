import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/app_startup_provider.dart';
import 'package:sahyan/core/theme/app_theme.dart';

/// App Router bridge for Luxury Onboarding Screen
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxuryOnboardingScreen(
      onFinish: () async {
        await ref.read(appStartupProvider.notifier).completeOnboarding();
        if (context.mounted) {
          context.go('/auth-entry');
        }
      },
    );
  }
}

/// Standalone, responsive Luxury Light Onboarding presentation
class LuxuryOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const LuxuryOnboardingScreen({super.key, required this.onFinish});

  @override
  State<LuxuryOnboardingScreen> createState() => _LuxuryOnboardingScreenState();
}

class _LuxuryOnboardingScreenState extends State<LuxuryOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      badge: 'Intelligent Route Matching',
      title: 'Shared Journeys Along Your Highway Route',
      description:
          'Connect with verified co-travelers travelling in the same direction across Gujarat highways without inconvenient detours.',
      icon: Icons.alt_route_rounded,
    ),
    OnboardingData(
      badge: 'Fair & Transparent',
      title: 'Equitable Vehicle Seat Cost Sharing',
      description:
          'Contribute fairly towards fuel and highway toll expenses with transparent, automated cost-sharing on every seat.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    OnboardingData(
      badge: 'Trust & Accountability',
      title: 'Verified Community & Secure Travel',
      description:
          'Travel with peace of mind through government identity verification, verified vehicle registration, and community safety accountability.',
      icon: Icons.verified_user_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip button with 48x48 touch target
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextButton(
                  onPressed: widget.onFinish,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: SahyanColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // Responsive PageView Carousel
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final data = _pages[index];
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Center Visual: Elevated Squircle/Circle with Glowing Ring
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: SahyanColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SahyanColors.border, width: 1.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SahyanColors.primaryDark.withValues(alpha: 0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      color: SahyanColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      data.icon,
                                      size: 38,
                                      color: SahyanColors.primaryDark,
                                    ),
                                  ),
                                ),
                              )
                                  .animate(key: ValueKey('icon_$index'))
                                  .scale(
                                    duration: 450.ms,
                                    curve: Curves.easeOutBack,
                                    begin: const Offset(0.85, 0.85),
                                    end: const Offset(1.0, 1.0),
                                  )
                                  .fadeIn(duration: 400.ms),

                              const SizedBox(height: 28),

                              // Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SahyanColors.primaryLight,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: SahyanColors.primaryMint.withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  data.badge,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: SahyanColors.primaryDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                                  .animate(key: ValueKey('badge_$index'))
                                  .fadeIn(duration: 350.ms, delay: 50.ms)
                                  .slideY(begin: 0.2, end: 0),

                              const SizedBox(height: 18),

                              // Title
                              Text(
                                data.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: SahyanColors.textMain,
                                  letterSpacing: -0.5,
                                  height: 1.3,
                                ),
                              )
                                  .animate(key: ValueKey('title_$index'))
                                  .fadeIn(duration: 400.ms, delay: 100.ms)
                                  .slideY(begin: 0.15, end: 0),

                              const SizedBox(height: 12),

                              // Description
                              Text(
                                data.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13.5,
                                  color: SahyanColors.textMuted,
                                  height: 1.5,
                                ),
                              )
                                  .animate(key: ValueKey('desc_$index'))
                                  .fadeIn(duration: 450.ms, delay: 150.ms)
                                  .slideY(begin: 0.1, end: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom Navigation Dock
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Expanding Pill Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          final isActive = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive ? SahyanColors.primaryDark : SahyanColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Responsive Action Button: 52dp height, Pine #1B4D3E, rounded 16px
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SahyanColors.primaryDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _pages.length - 1 ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
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
      ),
    );
  }
}

class OnboardingData {
  final String badge;
  final String title;
  final String description;
  final IconData icon;

  const OnboardingData({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
  });
}
