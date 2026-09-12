import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable Bento container with surface background, 22px border radius,
/// 0.8px border, and subtle ambient drop shadow.
class BentoContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? borderSide;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  const BentoContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.borderSide,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(22);
    final effectiveBorder = borderSide ??
        const BorderSide(
          color: SahyanColors.border,
          width: 0.8,
        );

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? SahyanColors.surface) : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: [
          BoxShadow(
            color: SahyanColors.textMain.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: SahyanColors.primaryMint.withValues(alpha: 0.08),
          highlightColor: SahyanColors.primaryMint.withValues(alpha: 0.04),
          child: container,
        ),
      );
    }

    return container;
  }
}
