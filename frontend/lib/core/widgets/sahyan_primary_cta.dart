import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_elevation.dart';
import '../../app/theme/app_spacing.dart';
import 'sahyan_button.dart';

/// Standardized floating / bottom-docked primary call-to-action container.
/// Strictly respects bottom SafeArea and viewport constraints.
class SahyanPrimaryCTA extends StatelessWidget {
  final String primaryText;
  final VoidCallback? onPrimaryPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? primaryIcon;
  final String? secondaryText;
  final VoidCallback? onSecondaryPressed;
  final Widget? leadingWidget;

  const SahyanPrimaryCTA({
    super.key,
    required this.primaryText,
    this.onPrimaryPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.primaryIcon,
    this.secondaryText,
    this.onSecondaryPressed,
    this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppElevation.floating,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.containerMargin,
        right: AppSpacing.containerMargin,
        top: AppSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leadingWidget != null) ...[
            leadingWidget!,
            const SizedBox(width: AppSpacing.md),
          ],
          if (secondaryText != null) ...[
            Expanded(
              flex: 1,
              child: SahyanButton(
                text: secondaryText!,
                variant: SahyanButtonVariant.outline,
                onPressed: onSecondaryPressed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            flex: 2,
            child: SahyanButton(
              text: primaryText,
              icon: primaryIcon,
              isLoading: isLoading,
              isDisabled: isDisabled,
              onPressed: onPrimaryPressed,
            ),
          ),
        ],
      ),
    );
  }
}
