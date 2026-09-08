import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān Chip for tags, filters, and selection states.
class SahyanChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? activeColor;
  final Color? activeTextColor;

  const SahyanChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.activeColor,
    this.activeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected
        ? (activeColor ?? AppColors.primaryForest)
        : AppColors.white;
    final effectiveTextColor = isSelected
        ? (activeTextColor ?? AppColors.white)
        : AppColors.textPrimary;
    final effectiveBorderColor = isSelected
        ? (activeColor ?? AppColors.primaryForest)
        : AppColors.border;

    return Material(
      color: effectiveBg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.radiusPill,
        side: BorderSide(color: effectiveBorderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: effectiveTextColor),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: effectiveTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
