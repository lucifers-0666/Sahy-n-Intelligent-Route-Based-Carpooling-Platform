import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/app_startup_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.route_rounded,
      tag: 'Intelligent Route Matching',
      title: 'Shared Journeys Along Your Highway Route',
      description:
          'Connect with verified co-travelers travelling in the same direction across Gujarat highways without inconvenient detours.',
    ),
    _OnboardingItem(
      icon: Icons.account_balance_wallet_outlined,
      tag: 'Fair & Transparent',
      title: 'Equitable Vehicle Seat Cost Sharing',
      description:
          'Contribute fairly towards fuel and highway toll expenses with transparent, automated cost-sharing on every seat.',
    ),
    _OnboardingItem(
      icon: Icons.verified_user_outlined,
      tag: 'Trust & Accountability',
      title: 'Verified Community & Secure Travel',
      description:
          'Travel with peace of mind through government identity verification, verified vehicle registration, and community safety accountability.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSkip() async {
    await ref.read(appStartupProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/auth-entry');
    }
  }

  void _handleNext() async {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await ref.read(appStartupProvider.notifier).completeOnboarding();
      if (mounted) {
        context.go('/auth-entry');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_currentPage < _items.length - 1)
            TextButton(
              onPressed: _handleSkip,
              child: Text(
                'Skip',
                style: AppTypography.button.copyWith(
                  color: AppColors.primaryForest,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28.0,
                              vertical: 12.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: AppColors.softForest,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryForest.withValues(
                                        alpha: 0.15,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 52,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softForest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.tag,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryForest,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  item.title,
                                  style: AppTypography.screenTitle.copyWith(
                                    color: AppColors.deepForest,
                                    height: 1.25,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  item.description,
                                  style: AppTypography.secondary.copyWith(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Controls Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _items.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentPage == index ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? AppColors.primaryForest
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: _currentPage == _items.length - 1
                                ? 'Get Started'
                                : 'Next',
                            icon: _currentPage == _items.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_ios_rounded,
                            onPressed: _handleNext,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String tag;
  final String title;
  final String description;

  const _OnboardingItem({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
  });
}
