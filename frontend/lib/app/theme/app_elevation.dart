import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized elevation and shadow tokens for the Sahyān design system.
/// Implements forest-tinted ambient depth without heavy harsh dark drop-shadows.
abstract class AppElevation {
  /// Subtle resting shadow for cards and elevated panels
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.primaryForest.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Standard card elevation with soft ambient depth
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primaryForest.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Floating surface elevation (floating bottom nav, floating CTAs)
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.primaryForest.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Modal and bottom sheet elevation
  static List<BoxShadow> get modal => [
    BoxShadow(
      color: AppColors.deepForest.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
  ];
}
