import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum SahyanButtonVariant { primary, secondary, outline, ghost, destructive }

enum SahyanButtonSize { large, regular, compact, small }

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
  final bool isInvalid;
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
    this.isInvalid = false,
    this.icon,
    this.iconLeading = true,
    this.isFullWidth = true,
  });

  @override
  State<SahyanButton> createState() => _SahyanButtonState();
}

class _SahyanButtonState extends State<SahyanButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 20),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 15),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case SahyanButtonSize.large:
        return 56.0;
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
      case SahyanButtonSize.large:
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
      case SahyanButtonSize.large:
        return AppTypography.button.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        );
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
      if (widget.variant == SahyanButtonVariant.primary) {
        return (isDark ? AppColors.brandBright : AppColors.brand).withValues(
          alpha: 0.40,
        );
      }
      return isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    }
    switch (widget.variant) {
      case SahyanButtonVariant.primary:
        return isDark ? AppColors.brandBright : AppColors.brand;
      case SahyanButtonVariant.secondary:
        return Colors.transparent;
      case SahyanButtonVariant.outline:
      case SahyanButtonVariant.ghost:
        return Colors.transparent;
      case SahyanButtonVariant.destructive:
        return AppColors.error;
    }
  }

  Color _foregroundColor(bool isDark) {
    if (widget.isDisabled) {
      if (widget.variant == SahyanButtonVariant.primary) {
        return Colors.white.withValues(alpha: 0.90);
      }
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
    if (widget.variant == SahyanButtonVariant.outline ||
        widget.variant == SahyanButtonVariant.secondary) {
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

    return AnimatedBuilder(
      animation: _shakeAnimation,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: _height,
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.input),
            boxShadow:
                widget.variant == SahyanButtonVariant.primary &&
                    !widget.isDisabled
                ? [
                    BoxShadow(
                      color: (isDark ? AppColors.mint : AppColors.brand)
                          .withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              side: border ?? BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isInteractive
                  ? () {
                      HapticFeedback.lightImpact();
                      if (widget.isInvalid &&
                          !(MediaQuery.maybeOf(context)?.disableAnimations ??
                              false)) {
                        _shakeController.forward(from: 0);
                      }
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
      ),
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
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
