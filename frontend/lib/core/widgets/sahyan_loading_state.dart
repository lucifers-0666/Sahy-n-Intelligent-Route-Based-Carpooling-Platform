import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān Loading State component.
/// Renders a calm forest-themed progress indicator with optional descriptive message.
class SahyanLoadingState extends StatelessWidget {
  final String? message;
  final double size;
  final bool isOverlay;

  const SahyanLoadingState({
    super.key,
    this.message,
    this.size = 36.0,
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryForest,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.base),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    if (isOverlay) {
      return Container(
        color: AppColors.warmBackground.withValues(alpha: 0.8),
        child: content,
      );
    }
    return content;
  }
}
