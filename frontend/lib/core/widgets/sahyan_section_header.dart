import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān Section Header component.
/// Provides consistent typography, hierarchy, and optional trailing action button.
class SahyanSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SahyanSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.secondary.copyWith(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
          ] else if (actionLabel != null && onActionTap != null) ...[
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: AppTypography.button.copyWith(
                  color: AppColors.primaryForest,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
