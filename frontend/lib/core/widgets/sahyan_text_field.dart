import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān Form Input Field component.
/// Provides consistent height, typography, prefix/suffix styling, and clear focus/error states.
/// Features a predictable structure: visible label above, clean input container, and helper/error below.
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
  final Iterable<String>? autofillHints;
  final String? errorText;
  final bool isValid;
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
    this.autofillHints,
    this.errorText,
    this.isValid = false,
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
  bool _hasFocus = false;

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
          // Universal BMP icons (no surrogate pairs) to avoid tofu on Android 8.1
          _obscured ? Icons.visibility : Icons.visibility_off,
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

    final hasError = widget.errorText != null;
    if (hasError) {
      effectiveSuffixIcon = const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.error_outline, color: AppColors.error, size: 20),
      );
    } else if (widget.isValid && effectiveSuffixIcon == null) {
      effectiveSuffixIcon = const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Visible External Label (Predictable structure, never crammed inside)
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // 2. Consistent Input Container (Height 54dp, rounded border, focus glow)
        Focus(
          onFocusChange: (hasFocus) {
            if (_hasFocus != hasFocus) setState(() => _hasFocus = hasFocus);
          },
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : (_hasFocus ? focusColor : borderColor),
                width: _hasFocus ? 2 : 1.5,
              ),
              boxShadow: _hasFocus && !hasError
                  ? [
                      BoxShadow(
                        color: focusColor.withValues(alpha: 0.14),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
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
              autofillHints: widget.autofillHints,
              maxLines: widget.isPassword ? 1 : widget.maxLines,
              minLines: widget.minLines,
              style: AppTypography.bodyLarge.copyWith(color: textColor),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.secondary.copyWith(color: hintColor),
                prefixIcon: widget.prefixIcon,
                suffixIcon: effectiveSuffixIcon,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                constraints: const BoxConstraints(minHeight: 54),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
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
          ),
        ),

        // 3. Helper or Error Message Area (Clearly positioned below the field)
        if (hasError || widget.helperText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasError ? AppColors.error : hintColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
