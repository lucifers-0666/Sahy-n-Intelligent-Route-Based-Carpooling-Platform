import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/user_mode_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';

class AuthGateDialog extends ConsumerWidget {
  final String title;
  final String message;
  final String? intendedRoute;

  const AuthGateDialog({
    super.key,
    this.title = 'Account Required',
    this.message =
        'To ensure community safety, route verification, and seat allocation, please sign in or create a Sahyān account.',
    this.intendedRoute,
  });

  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? intendedRoute,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AuthGateDialog(
        title: title ?? 'Account Required',
        message:
            message ??
            'To ensure community safety, route verification, and seat allocation, please sign in or create a Sahyān account.',
        intendedRoute: intendedRoute,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softForest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primaryForest,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.screenTitle.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTypography.secondary.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Create Account',
                onPressed: () {
                  if (intendedRoute != null) {
                    ref
                        .read(userModeProvider.notifier)
                        .setPendingProtectedIntent(intendedRoute);
                  }
                  Navigator.of(context).pop(false);
                  context.push('/register');
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (intendedRoute != null) {
                    ref
                        .read(userModeProvider.notifier)
                        .setPendingProtectedIntent(intendedRoute);
                  }
                  Navigator.of(context).pop(false);
                  context.push('/login');
                },
                child: Text(
                  'Log In to Existing Account',
                  style: AppTypography.button.copyWith(
                    color: AppColors.primaryForest,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Continue Exploring',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
