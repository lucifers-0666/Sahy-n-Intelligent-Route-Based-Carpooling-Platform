import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān Header AppBar component.
/// Delivers an airy, unhurried navigation header adhering to the Stitch visual style.
class SahyanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color backgroundColor;
  final bool centerTitle;

  const SahyanAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor = AppColors.warmBackground,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 64.0 : 56.0);

  @override
  Widget build(BuildContext context) {
    final canPop =
        Navigator.of(context).canPop() ||
        (GoRouter.maybeOf(context)?.canPop() ?? false);

    return AppBar(
      backgroundColor: backgroundColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: (showBackButton && canPop)
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              tooltip: 'Back',
              onPressed:
                  onBackPressed ??
                  () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else if (GoRouter.maybeOf(context)?.canPop() ?? false) {
                      context.pop();
                    }
                  },
            )
          : null,
      title: Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
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
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      actions: actions != null
          ? [...actions!, const SizedBox(width: AppSpacing.sm)]
          : null,
    );
  }
}
