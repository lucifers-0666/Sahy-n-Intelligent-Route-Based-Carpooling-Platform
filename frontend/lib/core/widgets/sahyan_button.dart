import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum SahyanButtonVariant { primary, secondary, outline, ghost, destructive }

enum SahyanButtonSize { regular, compact, small }

/// Standardized Sahyān Brand Button component.
/// Provides consistent touch target height, typography, loading states,
/// press scale (0.97x) micro-interaction, haptic feedback, and visual hierarchy.
class SahyanButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SahyanButtonVariant variant;
  final SahyanButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool iconLeading;
  final bool isFullWidth;

  const SahyanButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SahyanButtonVariant.primary,
    this.size = SahyanButtonSize.regular,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconLeading = true,
    this.isFullWidth = true,
  });

  @override
  State<SahyanButton> createState() => _SahyanButtonState();
}

class _SahyanButtonState extends State<SahyanButton> {
  bool _isPressed = false;

  double get _height {
    switch (widget.size) {
      case SahyanButtonSize.regular:
        return 52.0;
      case SahyanButtonSize.compact:
        return 44.0;
      case SahyanButtonSize.small:
        return 36.0;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case SahyanButtonSize.regular:
        return AppSpacing.paddingButton;
      case SahyanButtonSize.compact:
        return AppSpacing.paddingButtonCompact;
      case SahyanButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  TextStyle get _textStyle {
    switch (widget.size) {
      case SahyanButtonSize.regular:
        return AppTypography.button;
      case SahyanButtonSize.compact:
        return AppTypography.button.copyWith(fontSize: 14);
      case SahyanButtonSize.small:
        return AppTypography.caption.copyWith(fontWeight: FontWeight.w600);
    }
  }

  Color _backgroundColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    }
    switch (widget.variant) {
      case SahyanButtonVariant.primary:
        return isDark ? AppColors.brandBright : AppColors.brand;
      case SahyanButtonVariant.secondary:
        return isDark ? AppColors.darkSurfaceHigh : AppColors.softForest;
      case SahyanButtonVariant.outline:
      case SahyanButtonVariant.ghost:
        return Colors.transparent;
      case SahyanButtonVariant.destructive:
        return AppColors.error;
    }
  }

  Color _foregroundColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark ? AppColors.darkMuted : AppColors.textTertiary;
    }
    switch (widget.variant) {
      case SahyanButtonVariant.primary:
        return Colors.white;
      case SahyanButtonVariant.secondary:
        return isDark ? AppColors.mint : AppColors.brand;
      case SahyanButtonVariant.outline:
        return isDark ? AppColors.mint : AppColors.brand;
      case SahyanButtonVariant.ghost:
        return isDark ? AppColors.mint : AppColors.brand;
      case SahyanButtonVariant.destructive:
        return Colors.white;
    }
  }

  BorderSide? _borderSide(bool isDark) {
    if (widget.variant == SahyanButtonVariant.outline) {
      return BorderSide(
        color: widget.isDisabled
            ? (isDark ? AppColors.darkSurfaceHigh : AppColors.border)
            : (isDark ? AppColors.mint : AppColors.brand),
        width: 1.5,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive =
        !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

    final bgColor = _backgroundColor(isDark);
    final fgColor = _foregroundColor(isDark);
    final border = _borderSide(isDark);

    Widget content = widget.isLoading
        ? SizedBox(
            width: widget.size == SahyanButtonSize.small ? 16 : 22,
            height: widget.size == SahyanButtonSize.small ? 16 : 22,
            child: _MiniBrandProgressRing(color: fgColor),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.isFullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              if (widget.icon != null && widget.iconLeading) ...[
                Icon(
                  widget.icon,
                  size: widget.size == SahyanButtonSize.small ? 16 : 18,
                  color: fgColor,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: _textStyle.copyWith(color: fgColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (widget.icon != null && !widget.iconLeading) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  widget.icon,
                  size: widget.size == SahyanButtonSize.small ? 16 : 18,
                  color: fgColor,
                ),
              ],
            ],
          );

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        height: _height,
        width: widget.isFullWidth ? double.infinity : null,
        child: Material(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: border ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isInteractive
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed?.call();
                  }
                : null,
            onTapDown: isInteractive
                ? (_) {
                    setState(() => _isPressed = true);
                  }
                : null,
            onTapUp: isInteractive
                ? (_) {
                    setState(() => _isPressed = false);
                  }
                : null,
            onTapCancel: isInteractive
                ? () {
                    setState(() => _isPressed = false);
                  }
                : null,
            child: Padding(
              padding: _padding,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded micro progress ring for button loading states
class _MiniBrandProgressRing extends StatefulWidget {
  final Color color;

  const _MiniBrandProgressRing({required this.color});

  @override
  State<_MiniBrandProgressRing> createState() => _MiniBrandProgressRingState();
}

class _MiniBrandProgressRingState extends State<_MiniBrandProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: CustomPaint(painter: _MiniRingPainter(color: widget.color)),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final Color color;

  _MiniRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    // Draw 270 degree arc
    canvas.drawArc(rect, 0, 4.71, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
