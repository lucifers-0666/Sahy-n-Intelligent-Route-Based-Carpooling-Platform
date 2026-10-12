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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final hintColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;
    final fillColor = widget.enabled
        ? (isDark ? AppColors.darkSurface : Colors.white)
        : (isDark ? AppColors.darkSurfaceHigh : AppColors.surfaceContainerLow);
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final focusColor = isDark ? AppColors.mint : AppColors.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.fieldLabel.copyWith(
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
          ),
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
          style: AppTypography.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.secondary.copyWith(color: hintColor),
            helperText: widget.helperText,
            helperStyle: AppTypography.caption.copyWith(color: hintColor),
            errorText: widget.errorText,
            errorStyle: AppTypography.validationMessage.copyWith(
              color: AppColors.error,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: focusColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
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
