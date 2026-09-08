import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān Form Input Field component.
/// Provides consistent height, typography, prefix/suffix styling, and clear focus/error states.
class SahyanTextField extends StatefulWidget {
  final String? label;
  final String hint;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool isPassword;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;

  const SahyanTextField({
    super.key,
    this.label,
    required this.hint,
    this.helperText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.errorText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<SahyanTextField> createState() => _SahyanTextFieldState();
}

class _SahyanTextFieldState extends State<SahyanTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword ? true : widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant SahyanTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPassword && oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;

    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        splashRadius: 20,
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () {
          setState(() {
            _obscured = !_obscured;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.fieldLabel),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          obscureText: _obscured,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          onTap: widget.onTap,
          validator: widget.validator,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.minLines,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperStyle: AppTypography.caption,
            errorText: widget.errorText,
            errorStyle: AppTypography.validationMessage,
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffixIcon,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.white
                : AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(
                color: AppColors.primaryForest,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.mutedRust),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(
                color: AppColors.mutedRust,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ),
      ],
    );
  }
}
