import 'package:flutter/material.dart';
import 'sahyan_button.dart';

/// Standard Secondary Button component.
/// Consolidated to delegate directly to canonical [SahyanButton].
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SahyanButton(
      text: text,
      onPressed: onPressed,
      variant: SahyanButtonVariant.secondary,
      isLoading: isLoading,
      icon: icon,
    );
  }
}
