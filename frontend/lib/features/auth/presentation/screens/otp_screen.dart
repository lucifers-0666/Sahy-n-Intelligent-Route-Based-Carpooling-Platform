import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 6;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit verification code'),
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyOtp(otp);
    if (success && mounted) {
      ref.read(userModeProvider.notifier).clearGuestMode();
      final destination =
          ref.read(userModeProvider).pendingProtectedIntent ?? '/auth-success';
      ref.read(userModeProvider.notifier).clearPendingIntent();
      context.go(destination);
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg ?? 'Invalid verification code')),
      );
    }
  }

  void _handleResend() async {
    if (!_canResend) return;
    final phone = ref.read(authProvider).otpSentToPhone;
    if (phone != null && phone.isNotEmpty) {
      final success = await ref.read(authProvider.notifier).sendOtp(phone);
      if (success) {
        _startTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new verification code has been sent'),
            ),
          );
        }
      } else if (mounted) {
        final errorMsg = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'Failed to resend code')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final phoneDisplay = authState.otpSentToPhone ?? '+91 98765 43210';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify your phone',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppColors.deepForest,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'We sent a 6-digit code to ',
                        style: AppTypography.secondary,
                      ),
                      Text(
                        phoneDisplay,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryForest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Edit',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Responsive 6-digit OTP Box System
                  _buildResponsiveOtpBoxes(),

                  const SizedBox(height: 20),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _canResend
                                ? 'Code expired'
                                : 'Resend in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _canResend ? _handleResend : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Resend Code',
                          style: AppTypography.caption.copyWith(
                            color: _canResend
                                ? AppColors.primaryForest
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: 'Verify & Proceed',
                    isLoading: authState.isLoading,
                    onPressed: _handleVerify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveOtpBoxes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final double spacing = isNarrow ? 6.0 : 10.0;
        final double totalSpacing = spacing * (_otpLength - 1);
        final double calculatedBoxWidth =
            ((constraints.maxWidth - totalSpacing) / _otpLength).clamp(
              36.0,
              56.0,
            );
        final double boxHeight = (calculatedBoxWidth * 1.2).clamp(46.0, 64.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Visual Digits Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_otpLength, (index) {
                final otpText = _otpController.text;
                final hasChar = otpText.length > index;
                final isCurrent = otpText.length == index;

                return Container(
                  width: calculatedBoxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primaryForest
                          : (hasChar
                                ? AppColors.primaryForest
                                : AppColors.border),
                      width: isCurrent ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryForest.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasChar ? otpText[index] : '',
                    style: AppTypography.otpDigit.copyWith(
                      color: AppColors.primaryForest,
                      fontSize: isNarrow ? 20 : 24,
                    ),
                  ),
                );
              }),
            ),

            // Invisible TextField overlaid across the whole box area for seamless touch entry
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _otpController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: _otpLength,
                  cursorColor: Colors.transparent,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {});
                    if (val.length == _otpLength) {
                      _handleVerify();
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
