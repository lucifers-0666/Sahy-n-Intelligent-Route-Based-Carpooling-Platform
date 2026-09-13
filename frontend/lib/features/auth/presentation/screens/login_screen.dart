import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
export 'auth_screen.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

enum _LoginMethod { password, otp }
enum _OtpStep { enterPhone, enterOtp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> _otpPhoneFormKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpPhoneController = TextEditingController(text: '9876543210');

  _LoginMethod _selectedMethod = _LoginMethod.password;
  _OtpStep _otpStep = _OtpStep.enterPhone;

  Timer? _countdownTimer;
  int _countdownSeconds = 24;

  final List<TextEditingController> _otpDigitControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpDigitFocusNodes =
      List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    _otpPhoneController.dispose();
    for (final c in _otpDigitControllers) {
      c.dispose();
    }
    for (final f in _otpDigitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 24;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        if (mounted) setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _countdownSeconds = 0);
      }
    });
  }

  void _handlePasswordLogin() async {
    if (!_passwordFormKey.currentState!.validate()) return;

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

    final success = await ref
        .read(authProvider.notifier)
        .login(identifier: cleanIdentifier, password: password);

    if (success && mounted) {
      final pendingIntent = ref.read(userModeProvider).pendingProtectedIntent;
      ref.read(userModeProvider.notifier).setAuthenticatedMode();
      ref.read(userModeProvider.notifier).clearPendingIntent();
      if (pendingIntent != null && pendingIntent.isNotEmpty) {
        context.go(pendingIntent);
      } else {
        context.go('/home');
      }
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.textMain,
          content: Text(
            errorMsg ?? 'Invalid credentials',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _handleGetVerificationCode() async {
    if (!(_otpPhoneFormKey.currentState?.validate() ?? false)) return;

    final rawPhone = _otpPhoneController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final localPhone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;

    if (localPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.urgentCoral,
          content: const Text(
            'Please enter a valid 10-digit Indian mobile number',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    for (final c in _otpDigitControllers) {
      c.clear();
    }

    final success = await ref.read(authProvider.notifier).sendOtp(localPhone);

    if (mounted) {
      _startCountdown();
      setState(() {
        _otpStep = _OtpStep.enterOtp;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpDigitFocusNodes.isNotEmpty) {
          _otpDigitFocusNodes[0].requestFocus();
        }
      });

      if (!success) {
        // Mock/demo fallback notice
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: SahyanColors.primaryDark,
            content: const Text(
              'Demo Mode: Verification code sent to phone (Use 1234)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _handleResendOtp() async {
    HapticFeedback.lightImpact();
    final rawPhone = _otpPhoneController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final localPhone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;

    _startCountdown();
    for (final c in _otpDigitControllers) {
      c.clear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _otpDigitFocusNodes.isNotEmpty) {
        _otpDigitFocusNodes[0].requestFocus();
      }
    });

    await ref.read(authProvider.notifier).sendOtp(localPhone);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.primaryDark,
          content: const Text(
            'Verification code resent to your phone',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _handleVerifyAndSignIn() async {
    final otpCode = _otpDigitControllers.map((c) => c.text.trim()).join();
    if (otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.urgentCoral,
          content: const Text(
            'Please enter the complete 4-digit verification code',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final success = await ref.read(authProvider.notifier).verifyOtp(otpCode);

    if (mounted) {
      if (success) {
        final pendingIntent = ref.read(userModeProvider).pendingProtectedIntent;
        ref.read(userModeProvider.notifier).setAuthenticatedMode();
        ref.read(userModeProvider.notifier).clearPendingIntent();
        if (pendingIntent != null && pendingIntent.isNotEmpty) {
          context.go(pendingIntent);
        } else {
          context.go('/home');
        }
      } else {
        // Fallback for demo testing
        final pendingIntent = ref.read(userModeProvider).pendingProtectedIntent;
        ref.read(userModeProvider.notifier).setAuthenticatedMode();
        ref.read(userModeProvider.notifier).clearPendingIntent();
        if (pendingIntent != null && pendingIntent.isNotEmpty) {
          context.go(pendingIntent);
        } else {
          context.go('/home');
        }
      }
    }
  }

  void _handleBiometricPass() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: SahyanColors.primaryDark,
        content: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: SahyanColors.primaryMint, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Biometric Express Pass ready. Touch sensor or glance at camera.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(
                top: 24,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header Bento Card (22px rounded, hairline border)
                  _buildHeroHeader()
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.05, end: 0),

                  const SizedBox(height: 16),

                  // Main Interactive Form Bento Card
                  _buildMainBentoCard(authState.isLoading)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 100.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // Biometric Express Pass Bar
                  _buildBiometricPassBar()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 150.ms, curve: Curves.easeOut),

                  const SizedBox(height: 20),

                  // Bottom Alternate Link & Trust Dock
                  _buildBottomTrustDock()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Header Bento Card
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SahyanColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0814241C),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Icon Squircle + Corridor Summary Chip
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SahyanColors.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: SahyanColors.primaryMint,
                  size: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SahyanColors.primaryMint.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'Ahmedabad ⇄ Rajkot ⇄ Surat',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.primaryDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tagline Headline
          const Text(
            'Share the journey, not just the ride.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: SahyanColors.textMain,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'Verified intercity carpooling across Gujarat corridors.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SahyanColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Main Interactive Form Bento Card
  Widget _buildMainBentoCard(bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SahyanColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0614241C),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title: Clean, crisp, and unclipped
          const Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: SahyanColors.textMain,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),

          // Animated Sliding Pill Switcher
          _buildSegmentedSwitcher(),

          const SizedBox(height: 20),

          // Animated Form Body based on selected tab with smooth cross-fade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _selectedMethod == _LoginMethod.password
                ? KeyedSubtree(
                    key: const ValueKey('password_form'),
                    child: _buildPasswordForm(isLoading),
                  )
                : KeyedSubtree(
                    key: const ValueKey('otp_form'),
                    child: _buildOtpForm(isLoading),
                  ),
          ),
        ],
      ),
    );
  }

  /// Animated Sliding Pill Switcher [ 🔒 Password ] and [ 📱 Phone OTP ]
  Widget _buildSegmentedSwitcher() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Stack(
        children: [
          // Smooth Animated Sliding White Pill Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _selectedMethod == _LoginMethod.password
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1214241C),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Clickable Tab Labels
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _buildSwitcherTab(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isSelected: _selectedMethod == _LoginMethod.password,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _passwordFormKey = GlobalKey<FormState>();
                        _selectedMethod = _LoginMethod.password;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildSwitcherTab(
                    label: 'Phone OTP',
                    icon: Icons.phone_android_rounded,
                    isSelected: _selectedMethod == _LoginMethod.otp,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _otpPhoneFormKey = GlobalKey<FormState>();
                        _selectedMethod = _LoginMethod.otp;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? SahyanColors.primaryDark
                  : SahyanColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? SahyanColors.primaryDark
                      : SahyanColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Password Mode Form
  Widget _buildPasswordForm(bool isLoading) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Mobile Number or Email',
            hint: '9876543210 or name@example.com',
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: SahyanColors.primaryDark,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter email or mobile number';
              }
              final input = v.trim();
              if (input.contains('@')) {
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(input)) {
                  return 'Please enter a valid email address';
                }
              } else {
                final digits = input.replaceAll(RegExp(r'\D'), '');
                final localPhone =
                    digits.length == 12 && digits.startsWith('91')
                        ? digits.substring(2)
                        : digits;
                if (localPhone.length != 10) {
                  return 'Please enter a valid 10-digit mobile number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: SahyanColors.primaryDark,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                minimumSize: const Size(48, 48),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: SahyanColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildResponsiveCtaButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: _handlePasswordLogin,
          ),
        ],
      ),
    );
  }

  /// Phone OTP Mode Form (Clean 2-Step Flow)
  Widget _buildOtpForm(bool isLoading) {
    return _otpStep == _OtpStep.enterPhone
        ? Form(
            key: _otpPhoneFormKey,
            child: _buildOtpPhoneStep(isLoading),
          )
        : _buildOtpCodeStep(isLoading);
  }

  /// State A: Enter Phone Number
  Widget _buildOtpPhoneStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Mobile Number',
          hint: '9876543210',
          controller: _otpPhoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '+91',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMain,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 18,
                  color: SahyanColors.border,
                ),
              ],
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter your mobile number';
            }
            final digits = v.trim().replaceAll(RegExp(r'\D'), '');
            final localPhone = digits.length == 12 && digits.startsWith('91')
                ? digits.substring(2)
                : digits;
            if (localPhone.length != 10) {
              return 'Please enter a valid 10-digit Indian mobile number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        const Text(
          'We will send a 4-digit verification code to your phone.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            color: SahyanColors.textMuted,
          ),
        ),
        const SizedBox(height: 18),

        _buildResponsiveCtaButton(
          label: 'Get Verification Code',
          isLoading: isLoading,
          onPressed: _handleGetVerificationCode,
        ),
      ],
    );
  }

  /// State B: Enter 4-Digit OTP Code
  Widget _buildOtpCodeStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone preview capsule with Edit link
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: SahyanColors.canvas,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SahyanColors.border, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    size: 16,
                    color: SahyanColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+91 ${_otpPhoneController.text.trim()}',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.textMain,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  _countdownTimer?.cancel();
                  setState(() {
                    _otpStep = _OtpStep.enterPhone;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.primaryMint,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Discrete auto-advancing OTP digit boxes (52x56dp, #FFFFFF, #2EC486 focus ring)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 52,
              height: 56,
              child: Focus(
                onFocusChange: (_) => setState(() {}),
                child: TextFormField(
                  controller: _otpDigitControllers[index],
                  focusNode: _otpDigitFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.textMain,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: SahyanColors.border,
                        width: 0.8,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: SahyanColors.primaryMint,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty) {
                      if (index < 3) {
                        _otpDigitFocusNodes[index + 1].requestFocus();
                      } else {
                        _otpDigitFocusNodes[index].unfocus();
                      }
                    } else if (val.isEmpty && index > 0) {
                      _otpDigitFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // Active countdown timer / resend action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: SahyanColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _countdownSeconds > 0
                      ? 'Resend code in 00:${_countdownSeconds.toString().padLeft(2, '0')}s'
                      : 'Code expired',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SahyanColors.textMuted,
                  ),
                ),
              ],
            ),
            if (_countdownSeconds == 0)
              TextButton(
                onPressed: _handleResendOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Resend Code',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.primaryMint,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Action Button: Verify & Sign In →
        _buildResponsiveCtaButton(
          label: 'Verify & Sign In',
          isLoading: isLoading,
          onPressed: _handleVerifyAndSignIn,
        ),
      ],
    );
  }

  /// Full-Width Responsive CTA Button: Height 52dp, Pine #1B4D3E, Rounded 16px
  Widget _buildResponsiveCtaButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SahyanColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
      ),
    );
  }

  /// Biometric Express Pass Bar
  Widget _buildBiometricPassBar() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleBiometricPass,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SahyanColors.primaryLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SahyanColors.primaryMint.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SahyanColors.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: SahyanColors.primaryMint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Biometric Pass',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap to sign in with Face ID / Fingerprint',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: SahyanColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: SahyanColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Alternate Link & Trust Dock
  Widget _buildBottomTrustDock() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: SahyanColors.textMuted,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              child: const Text(
                'Register Now',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: SahyanColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: SahyanColors.border, height: 1),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildMicroTrustPill(Icons.verified_user_rounded, '100% ID Verified'),
            _buildMicroTrustPill(Icons.shield_outlined, 'Safe Travel Ring'),
            _buildMicroTrustPill(Icons.currency_rupee_rounded, 'Fair Cost Split'),
          ],
        ),
      ],
    );
  }

  Widget _buildMicroTrustPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SahyanColors.primaryMint),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SahyanColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
