import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';

/// Modal Dialog with radius 28 and selective frosted-glass styling.
class SahyanDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final Widget? content;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;

  const SahyanDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.content,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.isDestructive = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    Widget? content,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool isDestructive = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.54),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return SahyanDialog(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          content: content,
          primaryActionText: primaryActionText,
          onPrimaryAction: onPrimaryAction,
          secondaryActionText: secondaryActionText,
          onSecondaryAction: onSecondaryAction,
          isDestructive: isDestructive,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (icon != null) ...[
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (iconColor ?? AppColors.brand).withValues(
                              alpha: 0.12,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? AppColors.brand,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: mutedColor,
                        height: 1.45,
                      ),
                    ),

                    if (content != null) ...[
                      const SizedBox(height: 16),
                      content!,
                    ],

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        if (secondaryActionText != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onSecondaryAction?.call();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                secondaryActionText!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        if (primaryActionText != null) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onPrimaryAction?.call();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDestructive
                                    ? AppColors.error
                                    : AppColors.brand,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                primaryActionText!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
