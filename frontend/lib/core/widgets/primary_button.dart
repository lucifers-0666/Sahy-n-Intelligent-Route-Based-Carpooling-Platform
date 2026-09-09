import 'package:flutter/material.dart';
import 'sahyan_button.dart';

/// Standard Primary CTA Button component.
/// Consolidated to delegate directly to canonical [SahyanButton].
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SahyanButton(
      text: text,
      onPressed: onPressed,
      variant: SahyanButtonVariant.primary,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
    );
  }
}
