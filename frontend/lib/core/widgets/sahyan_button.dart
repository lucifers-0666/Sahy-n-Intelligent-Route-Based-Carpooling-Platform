import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum SahyanButtonVariant { primary, secondary, outline, ghost, destructive }

enum SahyanButtonSize { regular, compact, small }

/// Standardized Sahyān Brand Button component.
/// Provides consistent touch target height, typography, loading states, and visual hierarchy.
class SahyanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SahyanButtonVariant variant;
  final SahyanButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool iconLeading;
  final bool isFullWidth;

  const SahyanButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SahyanButtonVariant.primary,
    this.size = SahyanButtonSize.regular,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconLeading = true,
    this.isFullWidth = true,
  });

  double get _height {
    switch (size) {
      case SahyanButtonSize.regular:
        return 50.0;
      case SahyanButtonSize.compact:
        return 42.0;
      case SahyanButtonSize.small:
        return 34.0;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case SahyanButtonSize.regular:
        return AppSpacing.paddingButton;
      case SahyanButtonSize.compact:
        return AppSpacing.paddingButtonCompact;
      case SahyanButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  TextStyle get _textStyle {
    switch (size) {
      case SahyanButtonSize.regular:
        return AppTypography.button;
      case SahyanButtonSize.compact:
        return AppTypography.button.copyWith(fontSize: 14);
      case SahyanButtonSize.small:
        return AppTypography.caption.copyWith(fontWeight: FontWeight.w600);
    }
  }

  Color get _backgroundColor {
    if (isDisabled) {
      return AppColors.border;
    }
    switch (variant) {
      case SahyanButtonVariant.primary:
        return AppColors.primaryForest;
      case SahyanButtonVariant.secondary:
        return AppColors.softForest;
      case SahyanButtonVariant.outline:
      case SahyanButtonVariant.ghost:
        return Colors.transparent;
      case SahyanButtonVariant.destructive:
        return AppColors.mutedRust;
    }
  }

  Color get _foregroundColor {
    if (isDisabled) {
      return AppColors.textTertiary;
    }
    switch (variant) {
      case SahyanButtonVariant.primary:
        return AppColors.white;
      case SahyanButtonVariant.secondary:
        return AppColors.deepForest;
      case SahyanButtonVariant.outline:
        return AppColors.primaryForest;
      case SahyanButtonVariant.ghost:
        return AppColors.primaryForest;
      case SahyanButtonVariant.destructive:
        return AppColors.white;
    }
  }

  BorderSide? get _borderSide {
    if (variant == SahyanButtonVariant.outline) {
      return BorderSide(
        color: isDisabled ? AppColors.border : AppColors.primaryForest,
        width: 1.5,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;

    Widget content = isLoading
        ? SizedBox(
            width: size == SahyanButtonSize.small ? 16 : 20,
            height: size == SahyanButtonSize.small ? 16 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: _foregroundColor,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null && iconLeading) ...[
                Icon(
                  icon,
                  size: size == SahyanButtonSize.small ? 16 : 18,
                  color: _foregroundColor,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  text,
                  style: _textStyle.copyWith(color: _foregroundColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (icon != null && !iconLeading) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  icon,
                  size: size == SahyanButtonSize.small ? 16 : 18,
                  color: _foregroundColor,
                ),
              ],
            ],
          );

    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: _backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: _borderSide ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnPressed,
          child: Padding(
            padding: _padding,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
