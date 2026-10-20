import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

/// Formats 10-digit Indian numbers as '98765 43210' while strictly preserving
/// cursor offset and preventing cursor jumps to the end of input during editing.
class IndianPhoneInputFormatter extends TextInputFormatter {
  const IndianPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = rawDigits.length > 10
        ? rawDigits.substring(0, 10)
        : rawDigits;

    if (limitedDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final rawCursor = newValue.selection.baseOffset;
    int digitsBeforeCursor = 0;
    if (rawCursor > 0) {
      final safeCursor = math.min(rawCursor, newValue.text.length);
      final textBeforeCursor = newValue.text.substring(0, safeCursor);
      digitsBeforeCursor = textBeforeCursor
          .replaceAll(RegExp(r'\D'), '')
          .length;
      if (digitsBeforeCursor > 10) digitsBeforeCursor = 10;
    }

    final StringBuffer formatted = StringBuffer();
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 5) {
        formatted.write(' ');
      }
      formatted.write(limitedDigits[i]);
    }
    final formattedString = formatted.toString();

    int newOffset = digitsBeforeCursor;
    if (digitsBeforeCursor > 5) {
      newOffset += 1;
    }
    if (newOffset > formattedString.length) {
      newOffset = formattedString.length;
    }

    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

/// Alias for [IndianPhoneInputFormatter] as specified in design guidelines.
typedef IndianMobileFormatter = IndianPhoneInputFormatter;

/// Validates whether a given phone number is a valid 10-digit Indian mobile number (starting with 6-9).
bool isValidIndianMobile(String phone) {
  final clean = phone.replaceAll(RegExp(r'\D'), '');
  final digits = clean.length == 12 && clean.startsWith('91')
      ? clean.substring(2)
      : clean;
  return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
}

/// Standardized Sahyān Form Input Field component (Style C: Outlined, Label on Border).
///
/// Features:
/// - Single border owner: Flutter's [OutlineInputBorder] cuts the notch gap automatically
/// - Label sits on the border with [FloatingLabelBehavior.always]
/// - Never fakes the notch with a background chip (works cleanly over gradients & route lines)
/// - Radius 14 dp, Rest border 1.5 dp (#7C918A), Focus 2 dp brand (#0B5D4B)
/// - Error border 1.5-2 dp (#C23B2F) with icon + message below
/// - Label 13 sp w600 sitting on the border (muted at rest, brand on focus, red on error)
/// - Field fill white ~70% (#B3FFFFFF) via token [fieldFill] (can be set to Colors.transparent)
/// - Height ~58 dp with accessible touch targets >= 48 dp
class SahyanTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? hintText;
  final String? helper;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? prefixText;
  final Widget? prefixIcon;
  final Widget? trailing;
  final Widget? suffixIcon;
  final bool isValid;
  final bool obscureText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onFieldSubmitted;
  final Color? fieldFill;
  final double borderRadius;

  const SahyanTextField({
    super.key,
    this.label,
    this.hint,
    this.hintText,
    this.helper,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.prefixText,
    this.prefixIcon,
    this.trailing,
    this.suffixIcon,
    this.isValid = false,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onFieldSubmitted,
    this.fieldFill,
    this.borderRadius = 14.0,
  });

  @override
  State<SahyanTextField> createState() => _SahyanTextFieldState();
}

class _SahyanTextFieldState extends State<SahyanTextField> {
  FocusNode? _internalFocusNode;
  late bool _obscured;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword ? true : widget.obscureText;
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant SahyanTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPassword && oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  OutlineInputBorder _border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Design Tokens - Style C (Outline on border)
    final brand = isDark ? AppColors.mint : const Color(0xFF0B5D4B);
    final brandBright = isDark ? AppColors.mint : const Color(0xFF0F7A5F);
    final ink = isDark ? AppColors.darkText : const Color(0xFF0A1F1A);
    final muted = isDark ? AppColors.darkMuted : const Color(0xFF5B6B66);
    final hint = isDark
        ? AppColors.darkMuted.withValues(alpha: 0.75)
        : const Color(0xFF6F8079);
    final rest = isDark ? const Color(0xFF5A6E67) : const Color(0xFF7C918A);
    const error = Color(0xFFC23B2F);
    final defaultFieldFill =
        isDark ? const Color(0xB312302A) : const Color(0xB3FFFFFF);
    final effectiveFieldFill = widget.fieldFill ?? defaultFieldFill;
    final dividerColor =
        isDark ? const Color(0xFF2E4D45) : const Color(0xFFB9C7C1);

    final focused = _effectiveFocusNode.hasFocus;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final labelColor = hasError ? error : (focused ? brand : muted);

    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: labelColor,
    );

    final effectiveHint = widget.hint ?? widget.hintText;
    final effectiveHelper = widget.helper ?? widget.helperText;

    // Suffix / Trailing control
    Widget? effectiveTrailing = widget.trailing ?? widget.suffixIcon;
    if (widget.isPassword && effectiveTrailing == null) {
      effectiveTrailing = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility : Icons.visibility_off,
          color: muted,
          size: 22,
        ),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        splashRadius: 24,
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    } else if (effectiveTrailing == null && widget.isValid && !hasError) {
      effectiveTrailing = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          Icons.check_circle_rounded,
          color: brandBright,
          size: 22,
        ),
      );
    }

    return Semantics(
      label: widget.label,
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        maxLength: widget.maxLength,
        maxLines: (widget.isPassword || _obscured) ? 1 : widget.maxLines,
        minLines: widget.minLines,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        onTap: widget.onTap,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted ?? widget.onFieldSubmitted,
        cursorColor: brand,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        decoration: InputDecoration(
          // Label sits ON the border; Flutter cuts the gap in the outline itself.
          labelText: widget.label,
          labelStyle: labelStyle,
          floatingLabelStyle: labelStyle,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: effectiveHint,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: hint,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          counterText: '',
          filled: true,
          fillColor: effectiveFieldFill,
          contentPadding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
          prefixIcon: widget.prefixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: hasError ? error : (focused ? brand : muted),
                    size: 20,
                  ),
                  child: widget.prefixIcon!,
                )
              : null,
          prefix: (widget.prefixText == null || widget.prefixText!.isEmpty)
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.prefixText!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 18,
                        color: dividerColor,
                      ),
                    ],
                  ),
                ),
          suffixIcon: effectiveTrailing,
          helperText: effectiveHelper,
          helperMaxLines: 2,
          helperStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 1.35,
            color: muted,
          ),
          error: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.35,
                            color: error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          border: _border(rest, 1.5),
          enabledBorder: _border(rest, 1.5),
          focusedBorder: _border(brand, 2.0),
          errorBorder: _border(error, 1.5),
          focusedErrorBorder: _border(error, 2.0),
          disabledBorder: _border(dividerColor, 1.5),
        ),
      ),
    );
  }
}
