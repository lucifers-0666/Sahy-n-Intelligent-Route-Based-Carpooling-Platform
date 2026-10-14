import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/localization/sahyan_language_selector.dart';
import '../../../../core/localization/sahyan_localizations.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/sahyan_logo.dart';
import '../../../../shared/widgets/sahyan_route_background.dart';
import '../auth_provider.dart';
import '../widgets/enable_biometric_bottom_sheet.dart';

/// Redesigned 2026 Production OTP Verification Screen for Sahyān.
///
/// Features:
/// - Open canvas (removed redundant nested glass card)
/// - Master brand lockup matching Sign In and Register
/// - Formatted number (+91 98765 43210) with Edit action
/// - 6 larger digit boxes (50 x 58 dp) with tabular figures
/// - Auto-submit on 6th digit
/// - ONE single success moment: check morph animation (zero duplicate toast or pills)
/// - "Resend in 0:29" timer morphing to "Resend code" text button
/// - Android SMS auto-read via AutofillGroup & oneTimeCode
/// - Error shake micro-animation (reduced motion aware)
/// - Biometric opt-in prompt after first successful phone verification
class OtpScreen extends ConsumerStatefulWidget {
  final bool isRegistration;

  const OtpScreen({super.key, this.isRegistration = false});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;

  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 29;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isVerifiedSuccess = false;
  bool _hasError = false;
  bool _hasAttemptedVerify = false;
  String? _inlineErrorMessage;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -10.0),
            weight: 20,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -10.0, end: 10.0),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 10.0, end: -8.0),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -8.0, end: 0.0),
            weight: 15,
          ),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 29;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _secondsRemaining = 0;
            _canResend = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String get _currentOtp => _otpController.text.trim();

  String _formatPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '+91 98765 43210';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
    if (ten.length == 10) {
      return '+91 ${ten.substring(0, 5)} ${ten.substring(5)}';
    }
    return '+91 $raw';
  }

  Future<void> _handleVerify() async {
    if (_isVerifying || _isVerifiedSuccess) return;
    final otp = _currentOtp;
    if (otp.length != _otpLength) {
      setState(() => _hasAttemptedVerify = true);
      _triggerInvalidShake();
      return;
    }

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    try {
      final authState = ref.read(authProvider);
      final bool success;
      if (authState.firebaseVerificationId != null) {
        success = await ref
            .read(authProvider.notifier)
            .verifyFirebasePhoneOtp(otp);
      } else {
        success = await ref.read(authProvider.notifier).verifyOtp(otp);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isVerifying = false;
          _isVerifiedSuccess = true;
        });

        HapticFeedback.mediumImpact();
        ref.read(userModeProvider.notifier).clearGuestMode();
        final pendingDestination = ref
            .read(userModeProvider)
            .pendingProtectedIntent;
        ref.read(userModeProvider.notifier).clearPendingIntent();

        // Check if biometric is supported to prompt opt-in
        final biometric = ref.read(biometricServiceProvider);
        final canBio = await biometric.canAuthenticate();

        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        if (canBio) {
          await EnableBiometricBottomSheet.show(context);
        }

        if (mounted) {
          if (widget.isRegistration) {
            context.go('/auth-success');
          } else {
            context.go(
              pendingDestination != null && pendingDestination.isNotEmpty
                  ? pendingDestination
                  : '/home',
            );
          }
        }
      } else {
        final errorMsg = ref.read(authProvider).errorMessage;
        setState(() {
          _isVerifying = false;
          _hasError = true;
          _inlineErrorMessage =
              errorMsg ?? 'Incorrect code. Please check and try again.';
        });
        _triggerInvalidShake();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _hasError = true;
          _inlineErrorMessage = e.toString();
        });
        _triggerInvalidShake();
      }
    }
  }

  void _triggerInvalidShake() {
    HapticFeedback.vibrate();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _shakeController.forward(from: 0.0);
    }
    _otpController.clear();
    _otpFocusNode.requestFocus();
  }

  Future<void> _handleResendCode() async {
    if (!_canResend) return;
    final phone = ref.read(authProvider).otpSentToPhone;
    if (phone == null || phone.isEmpty) return;

    _startTimer();
    HapticFeedback.lightImpact();

    await ref.read(authProvider.notifier).sendFirebasePhoneOtp(phone);
    if (mounted) {
      FeedbackService.info(context, 'New verification code sent');
    }
  }

  void _onOtpChanged(String value) {
    setState(() {
      _hasError = false;
      _hasAttemptedVerify = false;
      _inlineErrorMessage = null;
    });
    if (value.length == _otpLength) {
      _otpFocusNode.unfocus();
      _handleVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final phoneFormatted = _formatPhone(authState.otpSentToPhone);
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);
    final l10n = SahyanLocalizations.of(context);

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
          onPressed: () => context.pop(),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master Brand Mark (Consistent across all screens)
                      const SahyanLogo.mark(size: 34),
                      const SizedBox(height: 20),

                      // Headline
                      Text(
                        l10n.verifyYourPhone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Formatted Phone Number with Edit action
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.sentCodeTo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                            ),
                          ),
                          Text(
                            phoneFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.mint : AppColors.brand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              l10n.edit,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandBright,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // ONE Success Moment: morphing check or OTP row
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: _isVerifiedSuccess
                            ? _buildSingleSuccessMoment(isDark, l10n)
                            : _buildOtpInputRow(isDark, textColor, l10n),
                      ),
                      if (!_isVerifiedSuccess &&
                          (_hasError || _hasAttemptedVerify)) ...[
                        const SizedBox(height: 12),
                        Text(
                          _hasAttemptedVerify && !_hasError
                              ? l10n.otpIncompleteError
                              : _inlineErrorMessage ??
                                    authState.errorMessage ??
                                    'Incorrect code. Please check and try again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // Resend in 0:29 countdown or Resend Text Button
                      Center(
                        child: _canResend
                            ? TextButton.icon(
                                onPressed: _handleResendCode,
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 16,
                                ),
                                label: Text(l10n.resendCode),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brandBright,
                                  textStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 15,
                                    color: mutedColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${l10n.resendIn}0:${_secondsRemaining.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: mutedColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 32),

                      // Primary Button (Manual fallback if not auto-submitted)
                      if (!_isVerifiedSuccess)
                        SahyanButton(
                          text: 'Verify & Proceed',
                          variant: SahyanButtonVariant.primary,
                          size: SahyanButtonSize.large,
                          isLoading: _isVerifying,
                          isInvalid: _currentOtp.length != _otpLength,
                          onPressed: _handleVerify,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One accessible, paste-friendly field with six responsive visual cells.
  Widget _buildOtpInputRow(
    bool isDark,
    Color textColor,
    SahyanLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final boxWidth =
            ((constraints.maxWidth - gap * (_otpLength - 1)) / _otpLength)
                .clamp(32.0, 56.0);
        final entered = _currentOtp.length;
        final activeIndex = entered.clamp(0, _otpLength - 1);

        return Semantics(
          label:
              '${l10n.verifyYourPhone}, $entered of $_otpLength digits entered',
          textField: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _otpFocusNode.requestFocus,
            child: SizedBox(
              height: 64,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      final isFocused =
                          _otpFocusNode.hasFocus && index == activeIndex;
                      final isFilled = index < entered;
                      final borderColor = _hasError
                          ? AppColors.error
                          : (isFocused || isFilled
                                ? AppColors.brand
                                : (isDark
                                      ? AppColors.darkSurfaceHigh
                                      : AppColors.border));

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        width: boxWidth,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? AppColors.brand.withValues(alpha: 0.06)
                              : (isDark ? AppColors.darkSurface : Colors.white),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: borderColor,
                            width: isFocused ? 2 : 1.2,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.mint.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            index < entered ? _currentOtp[index] : '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.02,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        enableSuggestions: false,
                        autocorrect: false,
                        showCursor: false,
                        maxLength: _otpLength,
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 1,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_otpLength),
                        ],
                        onChanged: _onOtpChanged,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ONE Single Success Moment: Expanding Check Morph (No duplicate toast or pill)
  Widget _buildSingleSuccessMoment(bool isDark, SahyanLocalizations l10n) {
    return Center(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(
            color: AppColors.brandBright.withValues(alpha: 0.6),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBright.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandBright,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              l10n.phoneVerifiedSuccess,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
