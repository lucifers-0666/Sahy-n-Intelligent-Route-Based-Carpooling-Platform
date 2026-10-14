import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';

enum SahyanToastType { success, info, warning, error }

/// Production glass pill toast notification widget.
///
/// Features:
/// - Sliding animation from top with spring curve
/// - Frosted glass background with opaque fallback
/// - Contextual type styling (success, error, warning, info) with rounded icons
/// - Optional action callback and button
/// - Micro progress indicator line indicating remaining display time
/// - Dismissible via vertical swipe
class SahyanToast extends StatefulWidget {
  final SahyanToastType type;
  final String message;
  final String? title;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Duration duration;

  const SahyanToast({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<SahyanToast> createState() => _SahyanToastState();
}

class _SahyanToastState extends State<SahyanToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss?.call();
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case SahyanToastType.success:
        return Icons.check_circle;
      case SahyanToastType.error:
        return Icons.error_outline;
      case SahyanToastType.warning:
        return Icons.warning_amber;
      case SahyanToastType.info:
        return Icons.info_outline;
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case SahyanToastType.success:
        return AppColors.brandBright;
      case SahyanToastType.error:
        return AppColors.error;
      case SahyanToastType.warning:
        return AppColors.marigold;
      case SahyanToastType.info:
        return AppColors.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isDark
        ? _accentColor.withValues(alpha: 0.35)
        : AppColors.border.withValues(alpha: 0.9);
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.up,
      onDismissed: (_) => widget.onDismiss?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Context Icon Circle
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentColor.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                          ),
                          child: Icon(_icon, color: _accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),

                        // Title & Message Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null &&
                                  widget.title!.isNotEmpty) ...[
                                Text(
                                  widget.title!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.message,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: widget.title != null
                                      ? mutedColor
                                      : textColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Optional Action Button
                        if (widget.onAction != null &&
                            widget.actionLabel != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              widget.onAction?.call();
                              widget.onDismiss?.call();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _accentColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Thin Auto-Dismiss Progress Line
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: 1.0 - _progressController.value,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _accentColor.withValues(alpha: 0.35),
                        ),
                        minHeight: 2.0,
                      );
                    },
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
