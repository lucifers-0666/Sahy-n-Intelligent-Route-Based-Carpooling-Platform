import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Ultra-premium frosted glass card component for Sahyān.
/// Renders hardware-accelerated BackdropFilter with subtle gradient borders
/// and translucent surface tints tailored for light and dark themes.
class SahyanGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final bool showHighlight;

  const SahyanGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22.0,
    this.blur = 16.0,
    this.showHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark
        ? const Color(0xFF11221B).withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.85);

    final borderColor = isDark
        ? AppColors.mint.withValues(alpha: 0.22)
        : AppColors.brand.withValues(alpha: 0.12);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : AppColors.brand.withValues(alpha: 0.07);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
