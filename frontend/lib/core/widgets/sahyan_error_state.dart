import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'sahyan_button.dart';

/// Standardized Sahyān Error State component.
/// Provides clear error messaging with organic muted rust accents and an actionable retry callback.
class SahyanErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const SahyanErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerMargin,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.mutedRust.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 36, color: AppColors.mutedRust),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: SahyanButton(
                  text: retryLabel,
                  onPressed: onRetry,
                  variant: SahyanButtonVariant.outline,
                  size: SahyanButtonSize.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
