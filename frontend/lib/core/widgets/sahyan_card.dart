import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_elevation.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';

/// Standardized Sahyān Information Card component.
/// Delivers clean content grouping with tactile forest depth and moderate curvature.
class SahyanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final bool hasBorder;
  final bool hasShadow;

  const SahyanCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingCard,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.hasBorder = true,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(borderRadius ?? AppRadii.lg);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: hasShadow ? AppElevation.card : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: backgroundColor ?? AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: effectiveRadius,
          side: hasBorder
              ? BorderSide(color: borderColor ?? AppColors.border, width: 1.0)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}
