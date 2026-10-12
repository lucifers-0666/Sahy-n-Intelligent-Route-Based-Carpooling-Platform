import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

/// Bottom Sheet with radius 28, drag handle, and selective frosted-glass styling.
class SahyanSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  final bool showCloseButton;

  const SahyanSheet({
    super.key,
    this.title,
    required this.child,
    this.trailing,
    this.showCloseButton = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool showCloseButton = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) {
        return SahyanSheet(
          title: title,
          trailing: trailing,
          showCloseButton: showCloseButton,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;

    const sheetRadius = BorderRadius.vertical(top: Radius.circular(28.0));

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          borderRadius: sheetRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 36,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: sheetRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: sheetRadius,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.2),
                  left: BorderSide(color: borderColor, width: 1.2),
                  right: BorderSide(color: borderColor, width: 1.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Centered drag handle pill
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkMuted.withValues(alpha: 0.4)
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          ?trailing,
                          if (showCloseButton)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                              splashRadius: 20,
                            ),
                        ],
                      ),
                    ),
                    Divider(color: borderColor, height: 1),
                  ],

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
