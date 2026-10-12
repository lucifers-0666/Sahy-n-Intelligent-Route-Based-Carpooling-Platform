import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../sahyan_route_convergence_logo.dart';

/// Branded loader for Sahyān that replaces raw CircularProgressIndicator.
/// Features a miniature pulsating route-convergence mark with smooth orbital glow.
class SahyanLoader extends StatefulWidget {
  final double size;
  final String? message;
  final bool isDark;

  const SahyanLoader({
    super.key,
    this.size = 36.0,
    this.message,
    this.isDark = false,
  });

  @override
  State<SahyanLoader> createState() => _SahyanLoaderState();
}

class _SahyanLoaderState extends State<SahyanLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.85),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.1415926,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        widget.isDark || Theme.of(context).brightness == Brightness.dark;

    final loaderWidget = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Orbital soft mint glow
              Container(
                width: widget.size * 1.3,
                height: widget.size * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mint.withValues(alpha: 0.18),
                ),
              ),
              // Spinning outer route ring
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.5),
                      width: 2.2,
                    ),
                  ),
                ),
              ),
              // Center Route Convergence Mark
              SahyanRouteConvergenceMark(
                size: widget.size * 0.72,
                isDark: effectiveIsDark,
              ),
            ],
          ),
        );
      },
    );

    if (widget.message == null || widget.message!.isEmpty) {
      return loaderWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        loaderWidget,
        const SizedBox(height: 12),
        Text(
          widget.message!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: effectiveIsDark ? AppColors.darkMuted : AppColors.mutedLight,
          ),
        ),
      ],
    );
  }
}

/// Shimmer Skeleton loading block for placeholder states
class SahyanSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SahyanSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadii.md,
  });

  @override
  State<SahyanSkeletonBox> createState() => _SahyanSkeletonBoxState();
}

class _SahyanSkeletonBoxState extends State<SahyanSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurface
        : AppColors.surfaceContainerLow;
    final highlightColor = isDark ? AppColors.darkSurfaceHigh : Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final current = Color.lerp(
          baseColor,
          highlightColor,
          _controller.value,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: current,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
