import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
export 'auth_screen.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/localization/sahyan_language_selector.dart';
import '../../../../core/localization/sahyan_localizations.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../firebase_options.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/feedback/sahyan_legal_sheet.dart';
import '../../../../shared/widgets/sahyan_logo.dart';
import '../../../../shared/widgets/sahyan_route_background.dart';
import '../auth_provider.dart';

enum _LoginMode { phoneOtp, password }

/// Redesigned 2026 Production Sign-In Screen for Sahyān.
///
/// Features:
/// - Strict Indian mobile validation: ^[6-9]\d{9}$
/// - Green checkmark and active button appear ONLY on valid number
/// - Inline validation error on blur
/// - Single container for phone field (+91 | 98765 43210 with thin divider, no nested boxes)
/// - Sticky primary button above keyboard
/// - Terms as one clean caption line
/// - Clear secondary text actions
/// - Brand at 40% opacity with white text for disabled button state
/// - Subtle route-line background pattern
/// - Language selector in AppBar (English / ગુજરાતી / हिन्दी)
/// - Safe-area and keyboard-aware layout
class LoginScreen extends ConsumerStatefulWidget {
  final String? initialMethod;

  const LoginScreen({super.key, this.initialMethod});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  _LoginMode _mode = _LoginMode.phoneOtp;
  bool _isRequestingOtp = false;
  bool _isSigningIn = false;
  bool _isSigningInWithGoogle = false;
  bool _isPasswordVisible = false;
  bool _hasPhoneBlurred = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMethod == 'password' || widget.initialMethod == 'email') {
      _mode = _LoginMode.password;
    } else {
      _mode = _LoginMode.phoneOtp;
    }

    _phoneController.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        setState(() => _hasPhoneBlurred = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMethod != oldWidget.initialMethod) {
      setState(() {
        if (widget.initialMethod == 'password' ||
            widget.initialMethod == 'email') {
          _mode = _LoginMode.password;
        } else {
          _mode = _LoginMode.phoneOtp;
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String get _cleanPhoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  /// Strict Indian mobile check: starts with 6-9 and exactly 10 digits
  bool get _isPhoneValid => RegExp(r'^[6-9]\d{9}$').hasMatch(_cleanPhoneDigits);

  bool get _showPhoneInlineError => _hasPhoneBlurred && !_isPhoneValid;

  Future<void> _handleGetOtp() async {
    if (_isRequestingOtp) return;
    if (!_isPhoneValid) {
      setState(() => _hasPhoneBlurred = true);
      return;
    }

    final cleanPhone = _cleanPhoneDigits;
    setState(() => _isRequestingOtp = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .sendFirebasePhoneOtp(cleanPhone);

      if (!mounted) return;
      setState(() => _isRequestingOtp = false);

      if (success) {
        HapticFeedback.mediumImpact();
        context.push('/otp');
      } else {
        final errorMsg = ref.read(authProvider).errorMessage;
        FeedbackService.error(
          context,
          errorMsg ?? 'Failed to send verification code. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingOtp = false);
        FeedbackService.error(context, e.toString());
      }
    }
  }

  Future<void> _handlePasswordLogin() async {
    if (_isSigningIn) return;
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    final rawIdentifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final String cleanIdentifier;
    if (!rawIdentifier.contains('@') &&
        RegExp(r'^\+?\d+$').hasMatch(rawIdentifier)) {
      final digits = rawIdentifier.replaceAll(RegExp(r'\D'), '');
      cleanIdentifier = digits.length == 12 && digits.startsWith('91')
          ? digits.substring(2)
          : digits;
    } else {
      cleanIdentifier = rawIdentifier;
    }

    setState(() => _isSigningIn = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(identifier: cleanIdentifier, password: password);

      if (!mounted) return;
      setState(() => _isSigningIn = false);

      if (success) {
        HapticFeedback.mediumImpact();
        FeedbackService.success(context, 'Signed in successfully');
        final pendingIntent = ref.read(userModeProvider).pendingProtectedIntent;
        ref.read(userModeProvider.notifier).setAuthenticatedMode();
        ref.read(userModeProvider.notifier).clearPendingIntent();
        context.go(
          pendingIntent != null && pendingIntent.isNotEmpty
              ? pendingIntent
              : '/home',
        );
      } else {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.suspended) {
          context.go(
            '/account-suspended',
            extra: {
              'reason':
                  authState.suspensionReason ??
                  'Account suspended by administration.',
              'suspendedAt': authState.suspendedAt,
            },
          );
          return;
        }
        FeedbackService.error(
          context,
          authState.errorMessage ?? 'Incorrect credentials',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        FeedbackService.error(context, e.toString());
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningInWithGoogle) return;
    setState(() => _isSigningInWithGoogle = true);

    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();

      if (!mounted) return;
      setState(() => _isSigningInWithGoogle = false);

      if (success) {
        HapticFeedback.mediumImpact();
        FeedbackService.success(context, 'Signed in with Google');
        ref.read(userModeProvider.notifier).clearGuestMode();
        final destination =
            ref.read(userModeProvider).pendingProtectedIntent ?? '/home';
        ref.read(userModeProvider.notifier).clearPendingIntent();
        context.go(destination);
      } else {
        final errorMsg = ref.read(authProvider).errorMessage;
        if (errorMsg != null && errorMsg.isNotEmpty) {
          FeedbackService.error(context, errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningInWithGoogle = false);
        FeedbackService.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = SahyanLocalizations.of(context);

    // Only show Google button if configured on platform
    final isGoogleConfigured = DefaultFirebaseOptions.isConfigured;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 22,
            color: textColor,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SahyanLanguageSelector(),
          ),
        ],
      ),
      body: SahyanRouteBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // 1. Scrollable Upper Body (Inputs & Links)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Mark Header (Master Logo)
                          const SahyanLogo.mark(size: 34),
                          const SizedBox(height: 20),

                          // Headline & Subline
                          Text(
                            _mode == _LoginMode.phoneOtp
                                ? l10n.whatsYourNumber
                                : "Welcome back",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mode == _LoginMode.phoneOtp
                                ? l10n.enterNumberPrompt
                                : "Enter your email or phone and password to sign in.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Form Input Section ──
                          if (_mode == _LoginMode.phoneOtp) ...[
                            _buildSingleContainerPhoneInput(
                              isDark,
                              textColor,
                              mutedColor,
                              l10n,
                            ),
                          ] else ...[
                            _buildPasswordInputSection(
                              isDark,
                              textColor,
                              mutedColor,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Secondary Link: Mode Switcher
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _mode = _mode == _LoginMode.phoneOtp
                                      ? _LoginMode.password
                                      : _LoginMode.phoneOtp;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.brandBright,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                _mode == _LoginMode.phoneOtp
                                    ? l10n.signInWithPasswordInstead
                                    : 'Sign in with phone OTP instead',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Secondary Link: Register Text Button
                          Center(
                            child: TextButton(
                              onPressed: () => context.push('/register'),
                              style: TextButton.styleFrom(
                                foregroundColor: mutedColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                l10n.registerPrompt,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Optional Google Sign-In
                          if (isGoogleConfigured) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: AppColors.border),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: mutedColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: AppColors.border),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildGoogleButton(isDark, textColor),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 2. Sticky Bottom Section Above Keyboard
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      8.0,
                      24.0,
                      math.max(bottomPadding, 12.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary Action Button (Sticky)
                        SahyanButton(
                          text: _mode == _LoginMode.phoneOtp
                              ? l10n.getOtp
                              : 'Sign In',
                          variant: SahyanButtonVariant.primary,
                          size: SahyanButtonSize.large,
                          isLoading: _mode == _LoginMode.phoneOtp
                              ? _isRequestingOtp
                              : _isSigningIn,
                          isInvalid:
                              _mode == _LoginMode.phoneOtp && !_isPhoneValid,
                          onPressed: _mode == _LoginMode.phoneOtp
                              ? _handleGetOtp
                              : _handlePasswordLogin,
                        ),
                        const SizedBox(height: 12),

                        // Single-line Terms Caption
                        Center(
                          child: GestureDetector(
                            onTap: () => SahyanLegalSheet.show(context),
                            child: Text.rich(
                              TextSpan(
                                text: l10n.termsConsentPrefix,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.termsAndPrivacy,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandBright,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ONE Unified Container for Phone Input (+91 | 98765 43210 with thin divider)
  Widget _buildSingleContainerPhoneInput(
    bool isDark,
    Color textColor,
    Color mutedColor,
    SahyanLocalizations l10n,
  ) {
    final borderColor = _showPhoneInlineError
        ? AppColors.error
        : (_isPhoneValid
              ? AppColors.brand
              : (_phoneFocusNode.hasFocus
                    ? AppColors.brand
                    : (isDark ? AppColors.darkSurfaceHigh : AppColors.border)));

    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single outer container
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: borderColor,
                width: _phoneFocusNode.hasFocus ? 2 : 1.5,
              ),
              boxShadow: _phoneFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.brandBright.withValues(alpha: 0.14),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // +91 prefix and divider form one phone field.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+91',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Thin Vertical Divider (1px)
                Container(
                  width: 1.0,
                  height: 24,
                  color: isDark ? AppColors.darkSurfaceHigh : AppColors.border,
                ),

                // Phone Input with auto-space formatting
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      _IndianPhoneAutoSpaceFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: '98765 43210',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: mutedColor.withValues(alpha: 0.55),
                        letterSpacing: 1.2,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
                if (_isPhoneValid)
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Inline Error Message on blur
          if (_showPhoneInlineError) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      l10n.invalidPhoneError,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Password Login Form Section
  Widget _buildPasswordInputSection(
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;

    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identifier Field
          TextFormField(
            controller: _identifierController,
            focusNode: _identifierFocusNode,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email or mobile number';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email or Mobile Number',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: mutedColor,
              ),
              hintText: 'name@example.com or 9876543210',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: mutedColor.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: !_isPasswordVisible,
            autofillHints: const [AutofillHints.password],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: mutedColor,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.6,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 20,
                  color: mutedColor,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                FeedbackService.info(
                  context,
                  'Please sign in with Phone OTP to reset your password.',
                );
                setState(() => _mode = _LoginMode.phoneOtp);
              },
              child: Text(
                'Forgot password?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandBright,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Google Sign-In Outlined Button
  Widget _buildGoogleButton(bool isDark, Color textColor) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isSigningInWithGoogle ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? AppColors.darkSurfaceHigh : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: _isSigningInWithGoogle
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Auto-formats 10 digits as '98765 43210'
class _IndianPhoneAutoSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length <= 5) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted = '${digits.substring(0, 5)} ${digits.substring(5)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
