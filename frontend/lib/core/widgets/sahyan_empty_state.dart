import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'sahyan_button.dart';

/// Standardized Sahyān Empty State component.
/// Displays an intentional, polished empty state with icon, title, message, and optional action.
class SahyanEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customAction;
  final double iconSize;

  const SahyanEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.customAction,
    this.iconSize = 48.0,
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
              width: iconSize + 36,
              height: iconSize + 36,
              decoration: const BoxDecoration(
                color: AppColors.softForest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.primaryForest,
                ),
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
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (customAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              customAction!,
            ] else if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: SahyanButton(
                  text: actionText!,
                  onPressed: onAction,
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
