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
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../../../../firebase_options.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/feedback/sahyan_legal_sheet.dart';
import '../../../../shared/widgets/sahyan_logo.dart';
import '../../../../shared/widgets/sahyan_route_background.dart';
import '../auth_provider.dart';

enum _LoginMode { phoneOtp, password }

/// Refined Production Sign-In Screen for Sahyān.
///
/// Features:
/// - Single-border rule: exactly one border per input, eliminating nested boxes
/// - Style A filled input with internal label and realistic hint
/// - Cohesive outline icon family (phone, mail, lock with visibility control)
/// - Single mode switcher text link (eliminates redundant tab and link duplicates)
/// - Strict Indian mobile validation: ^[6-9]\d{9}$
/// - Phone formatting (98765 43210) without cursor corruption
/// - Sticky primary CTA above keyboard
/// - Zero emojis across all code and UI text
class LoginScreen extends ConsumerStatefulWidget {
  final String? initialMethod;

  const LoginScreen({super.key, this.initialMethod});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
  bool _hasPhoneBlurred = false;
  bool _hasIdentifierBlurred = false;
  bool _hasPasswordBlurred = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMethod == 'password' || widget.initialMethod == 'email') {
      _mode = _LoginMode.password;
    } else {
      _mode = _LoginMode.phoneOtp;
    }

    _phoneController.addListener(() => setState(() {}));
    _identifierController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        setState(() => _hasPhoneBlurred = true);
      }
    });

    _identifierFocusNode.addListener(() {
      if (!_identifierFocusNode.hasFocus) {
        setState(() => _hasIdentifierBlurred = true);
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() => _hasPasswordBlurred = true);
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

    final rawIdentifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (rawIdentifier.isEmpty || password.isEmpty) {
      setState(() {
        _hasIdentifierBlurred = true;
        _hasPasswordBlurred = true;
      });
      FeedbackService.error(
        context,
        'Please enter your email or phone and password.',
      );
      return;
    }

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
    final l10n = context.l10n;

    // Only show Google button if configured on platform
    final isGoogleConfigured = DefaultFirebaseOptions.isConfigured;

    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/home');
        }
      });
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.brand,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22, color: textColor),
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
                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Mark Header (Master Logo without unsupported badges)
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [SahyanLogo.mark(size: 34)],
                          ),
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
                          const SizedBox(height: 24),

                          // Form Inputs: Clean single-border filled style without redundant card wrappers
                          if (_mode == _LoginMode.phoneOtp) ...[
                            SahyanTextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              label: 'Mobile number',
                              hint: '98765 43210',
                              prefixText: '+91',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleGetOtp(),
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: const [
                                IndianPhoneInputFormatter(),
                              ],
                              errorText: _showPhoneInlineError
                                  ? l10n.invalidPhoneError
                                  : null,
                              isValid: _isPhoneValid,
                            ),
                          ] else ...[
                            SahyanTextField(
                              controller: _identifierController,
                              focusNode: _identifierFocusNode,
                              label: 'Email or Mobile Number',
                              hint: 'name@example.com or 98765 43210',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                                AutofillHints.username,
                              ],
                              errorText:
                                  _hasIdentifierBlurred &&
                                      _identifierController.text.trim().isEmpty
                                  ? 'Please enter your email or mobile number'
                                  : null,
                              isValid: _identifierController.text
                                  .trim()
                                  .isNotEmpty,
                            ),
                            const SizedBox(height: 12),
                            SahyanTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              label: 'Password',
                              hint: 'Enter secure password',
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handlePasswordLogin(),
                              autofillHints: const [AutofillHints.password],
                              errorText:
                                  _hasPasswordBlurred &&
                                      _passwordController.text.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                              isValid: _passwordController.text.isNotEmpty,
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brandBright,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Single Mode Switcher Text Link
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
                      20.0,
                      8.0,
                      20.0,
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
