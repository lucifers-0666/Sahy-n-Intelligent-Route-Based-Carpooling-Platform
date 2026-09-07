import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';

class AuthDecisionScreen extends ConsumerWidget {
  const AuthDecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Brand Icon
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.primaryForest,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryForest.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            size: 42,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Brand Title
                      Text(
                        'Sahyān',
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 32,
                          color: AppColors.deepForest,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Chosen Tagline
                      Text(
                        'Where Journeys Find Company.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Trust Badges Grid/Wrap
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _FeaturePill(
                            icon: Icons.verified_user_outlined,
                            label: 'Verified Profiles',
                          ),
                          _FeaturePill(
                            icon: Icons.shield_outlined,
                            label: 'Fair Cost Sharing',
                          ),
                          _FeaturePill(
                            icon: Icons.alt_route_rounded,
                            label: 'Direct Highway Routes',
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),

                      // Primary Action: Sign Up
                      PrimaryButton(
                        text: 'Create an Account',
                        icon: Icons.person_add_outlined,
                        onPressed: () {
                          ref
                              .read(userModeProvider.notifier)
                              .setAuthenticatedMode();
                          context.push('/register');
                        },
                      ),
                      const SizedBox(height: 14),

                      // Secondary Action: Log In
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.white,
                        ),
                        icon: const Icon(
                          Icons.login_rounded,
                          color: AppColors.primaryForest,
                          size: 20,
                        ),
                        label: Text(
                          'Log In',
                          style: AppTypography.button.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(userModeProvider.notifier)
                              .setAuthenticatedMode();
                          context.push('/login');
                        },
                      ),
                      const SizedBox(height: 24),

                      // Divider with Text
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.border),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            child: Text(
                              'OR',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.border),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tertiary Action: Explore as Guest (Without Underline)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.explore_outlined,
                          color: AppColors.primaryForest,
                          size: 20,
                        ),
                        label: Text(
                          'Explore as Guest',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () {
                          ref.read(userModeProvider.notifier).setGuestMode();
                          context.go('/home');
                        },
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Browse active routes and trip contribution costs without signing in.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softForest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryForest),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryForest,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
