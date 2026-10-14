import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/error_mapper.dart';
import 'sahyan_toast.dart';
export 'sahyan_toast.dart';

/// Centralized In-App Feedback Service for Sahyān.
/// Replaces all raw Flutter SnackBar / ScaffoldMessenger calls with custom glass toasts.
class FeedbackService {
  static OverlayEntry? _currentEntry;

  /// Display a customized glass toast notification respecting safe area and 12dp margins.
  static void showToast(
    BuildContext context, {
    required SahyanToastType type,
    required String message,
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    // Provide appropriate haptic feedback tinted by severity
    switch (type) {
      case SahyanToastType.error:
        HapticFeedback.heavyImpact();
        break;
      case SahyanToastType.warning:
        HapticFeedback.mediumImpact();
        break;
      case SahyanToastType.success:
      case SahyanToastType.info:
        HapticFeedback.lightImpact();
        break;
    }

    _removeCurrentToast();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Map error through ErrorMapper to prevent raw technical strings in UI
    final displayMessage = type == SahyanToastType.error
        ? ErrorMapper.map(message)
        : message;

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _ToastSlideContainer(
          duration: duration,
          onDismiss: () {
            if (_currentEntry == entry) {
              _removeCurrentToast();
            }
          },
          child: SahyanToast(
            type: type,
            title: title,
            message: displayMessage,
            duration: duration,
            onAction: onAction,
            actionLabel: actionLabel,
            onDismiss: () {
              if (_currentEntry == entry) {
                _removeCurrentToast();
              }
            },
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Single API alias matching the master brief specification
  static void toast(
    BuildContext context,
    SahyanToastType type,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    showToast(
      context,
      type: type,
      message: message,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a success toast
  static void success(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    showToast(
      context,
      type: SahyanToastType.success,
      title: title,
      message: message,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an error toast
  static void error(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    showToast(
      context,
      type: SahyanToastType.error,
      title: title,
      message: message,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a warning toast
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    showToast(
      context,
      type: SahyanToastType.warning,
      title: title,
      message: message,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an info toast
  static void info(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    showToast(
      context,
      type: SahyanToastType.info,
      title: title,
      message: message,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void _removeCurrentToast() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _ToastSlideContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastSlideContainer({
    required this.child,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastSlideContainer> createState() => _ToastSlideContainerState();
}

class _ToastSlideContainerState extends State<_ToastSlideContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, -0.6), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 12,
      left: 12,
      right: 12,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
        ),
      ),
    );
  }
}
