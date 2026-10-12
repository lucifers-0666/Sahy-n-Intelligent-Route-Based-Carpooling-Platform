import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../auth_provider.dart';

/// Redesigned 2026 OTP Verification Screen for Sahyān.
///
/// Features:
/// - Six clearly separated OTP digit positions with tabular numerals
/// - Numeric keyboard, automatic focus traversal, and clipboard paste support
/// - Resend countdown with active action
/// - Shake micro-animation on invalid code (respecting reduced motion)
/// - Checkmark morph animation upon server confirmation
/// - Real backend verification via AuthNotifier.verifyOtp
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;

  final List<TextEditingController> _digitControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _digitFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isVerifiedSuccess = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -10.0),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -10.0, end: 10.0),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 10.0, end: 0.0),
            weight: 25,
          ),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _digitFocusNodes.isNotEmpty) {
        _digitFocusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
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
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _digitControllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerify() async {
    final otp = _currentOtp;
    if (otp.length != _otpLength) {
      _triggerInvalidShake();
      FeedbackService.warning(
        context,
        'Please enter the full 6-digit verification code',
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final success = await ref.read(authProvider.notifier).verifyOtp(otp);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isVerifying = false;
          _isVerifiedSuccess = true;
        });

        HapticFeedback.mediumImpact();
        FeedbackService.success(context, 'Phone verified successfully');

        ref.read(userModeProvider.notifier).clearGuestMode();
        final destination =
            ref.read(userModeProvider).pendingProtectedIntent ?? '/home';
        ref.read(userModeProvider.notifier).clearPendingIntent();

        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          context.go(destination);
        }
      } else {
        setState(() => _isVerifying = false);
        _triggerInvalidShake();
        final errorMsg = ref.read(authProvider).errorMessage;
        FeedbackService.error(
          context,
          errorMsg ?? 'Invalid or expired verification code',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        _triggerInvalidShake();
        FeedbackService.error(context, e.toString());
      }
    }
  }

  void _triggerInvalidShake() {
    HapticFeedback.heavyImpact();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _shakeController.forward(from: 0.0);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final phone = ref.read(authProvider).otpSentToPhone;
    if (phone == null || phone.isEmpty) {
      FeedbackService.error(context, 'No registered phone number found');
      return;
    }

    HapticFeedback.lightImpact();
    for (final c in _digitControllers) {
      c.clear();
    }
    _digitFocusNodes[0].requestFocus();

    final success = await ref.read(authProvider.notifier).sendOtp(phone);
    if (mounted) {
      if (success) {
        _startTimer();
        FeedbackService.success(
          context,
          'A new verification code has been sent',
        );
      } else {
        final errorMsg = ref.read(authProvider).errorMessage;
        FeedbackService.error(context, errorMsg ?? 'Failed to resend code');
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    // Handle paste across all boxes
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _digitControllers[i].text = digits[i];
      }
      final nextIndex = (digits.length < _otpLength)
          ? digits.length
          : _otpLength - 1;
      _digitFocusNodes[nextIndex].requestFocus();
      if (digits.length >= _otpLength) {
        _handleVerify();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
        if (_currentOtp.length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final phoneDisplay = authState.otpSentToPhone != null
        ? '+91 ${authState.otpSentToPhone}'
        : 'your mobile number';

    final cardBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkText : AppColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header Lockup
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SahyanRouteConvergenceMark(size: 28, isDark: isDark),
                        const SizedBox(width: 8),
                        Text(
                          'Sahyān',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.brand,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title: "Verify your phone"
                  Text(
                    'Verify your phone',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone Info with Edit Action
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'We sent a 6-digit code to ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: mutedColor,
                        ),
                      ),
                      Text(
                        phoneDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.mint : AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.mint : AppColors.brand,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Main OTP Verification Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(22.0),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.05,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 6 Clearly Separated OTP Digit Positions with Shake Animation
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: child,
                                );
                              },
                              child: _isVerifiedSuccess
                                  ? _buildSuccessMorphBadge()
                                  : _buildOtpInputRow(isDark),
                            ),
                            const SizedBox(height: 24),

                            // Resend Timer & Resend Action
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: mutedColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _canResend
                                            ? 'Code expired'
                                            : 'Expires in ${_secondsRemaining.toString().padLeft(2, '0')}s',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                TextButton(
                                  onPressed: _canResend ? _handleResend : null,
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? AppColors.mint
                                        : AppColors.brand,
                                    disabledForegroundColor: isDark
                                        ? AppColors.darkMuted.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppColors.textDisabled,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(48, 48),
                                  ),
                                  child: Text(
                                    'Resend Code',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Primary Action: Verify & Proceed
                            SahyanButton(
                              text: 'Verify & Proceed',
                              icon: Icons.check_circle_outline_rounded,
                              variant: SahyanButtonVariant.primary,
                              size: SahyanButtonSize.regular,
                              isLoading: _isVerifying,
                              onPressed: _isVerifiedSuccess
                                  ? null
                                  : _handleVerify,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputRow(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final hPadding = totalWidth < 300 ? 2.0 : 4.0;
        final boxHeight = (totalWidth / _otpLength * 1.15).clamp(44.0, 56.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_otpLength, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: SizedBox(
                  height: boxHeight,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace &&
                          _digitControllers[index].text.isEmpty &&
                          index > 0) {
                        _digitFocusNodes[index - 1].requestFocus();
                      }
                    },
                    child: TextFormField(
                      controller: _digitControllers[index],
                      focusNode: _digitFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: totalWidth < 300 ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceHigh
                            : AppColors.canvasLight,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkSurfaceHigh
                                : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkSurfaceHigh
                                : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.mint : AppColors.brand,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (val) => _onDigitChanged(index, val),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSuccessMorphBadge() {
    return Center(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.mint.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.mint, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.mint,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              'Code Verified',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
