import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../auth_provider.dart';

class AuthSuccessScreen extends ConsumerWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final phone = authState.otpSentToPhone ?? user?.phone ?? '+91 98765 43210';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Identity Verification',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Shield Badge with Ambient Halo
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.softForest.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.softForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primaryForest,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Main Verified Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Step Monogram Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmBackground,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryForest,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Step 2 of 3 · Verified',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryForest,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      "You're all set",
                      style: AppTypography.screenTitle.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Your Sahyan account has been successfully verified. You are now part of a mindful community sharing everyday journeys across highway corridors.',
                      style: AppTypography.secondary,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Verification Trust Pillars
                    _buildTrustPillar(
                      Icons.check_rounded,
                      'Phone Authenticated ($phone)',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTrustPillar(
                      Icons.check_rounded,
                      'Zero-Spam Direct Messaging Active',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTrustPillar(
                      Icons.check_rounded,
                      'SafePass Trust Protocol Enabled',
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Unified Account Ethos Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.softForest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primaryForest,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Sahyan is a unified ecosystem. Whether choosing to travel as a passenger or share vacant seats as a carpool host, your validated trust tier travels with you everywhere.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.deepForest,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Corridor Ambient Visual Banner
                    Container(
                      constraints: const BoxConstraints(minHeight: 72),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.deepForest,
                            AppColors.primaryForest,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: const Icon(
                              Icons.alt_route_rounded,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Western Ghats & Intercity Transit',
                                  style: AppTypography.cardTitle.copyWith(
                                    color: AppColors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Real-time corridor matching active',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.softForest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Actions
                    SahyanButton(
                      text: 'Complete Your Profile',
                      icon: Icons.arrow_forward_rounded,
                      isFullWidth: true,
                      onPressed: () => context.push('/personal-details'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SahyanButton(
                      text: 'Explore Routes First',
                      variant: SahyanButtonVariant.outline,
                      isFullWidth: true,
                      onPressed: () => context.go('/home'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Security Footnote
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '256-bit Encrypted Member Identity',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustPillar(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBackground,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.softForest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryForest, size: 14),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
