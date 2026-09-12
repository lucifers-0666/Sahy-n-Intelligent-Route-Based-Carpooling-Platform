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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpPhoneController = TextEditingController();

  _LoginMethod _selectedMethod = _LoginMethod.password;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _otpPhoneController.dispose();
    super.dispose();
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

  void _handleOtpSend() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final rawPhone = _otpPhoneController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final localPhone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;

    final success = await ref.read(authProvider.notifier).sendOtp(localPhone);

    if (success && mounted) {
      context.push('/otp');
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.textMain,
          content: Text(
            errorMsg ?? 'Failed to send OTP. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      padding: const EdgeInsets.all(20),
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
          // Section Title
          const Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: SahyanColors.textMain,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Pill Switcher
          _buildSegmentedSwitcher(),

          const SizedBox(height: 20),

          // Animated Form Body based on selected tab
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
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

  /// Capsule Segmented Switcher [ Password ] and [ Phone OTP ]
  Widget _buildSegmentedSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: SahyanColors.chipBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSwitcherTab(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              isSelected: _selectedMethod == _LoginMethod.password,
              onTap: () {
                setState(() {
                  _selectedMethod = _LoginMethod.password;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSwitcherTab(
              label: 'Phone OTP',
              icon: Icons.phone_android_rounded,
              isSelected: _selectedMethod == _LoginMethod.otp,
              onTap: () {
                setState(() {
                  _selectedMethod = _LoginMethod.otp;
                });
              },
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? SahyanColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1014241C),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  /// Phone OTP Mode Form
  Widget _buildOtpForm(bool isLoading) {
    return Form(
      key: _otpFormKey,
      child: Column(
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
          const SizedBox(height: 14),

          // 4-Digit Security Token Preview / Active Focus Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 14,
                          color: SahyanColors.primaryMint,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Security Token',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: SahyanColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: SahyanColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Resend in 00:24s',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: SahyanColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildOtpTokenBox('5')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildOtpTokenBox('9')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildOtpTokenBox('2')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildOtpTokenBox('•', isPlaceholder: true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'We will send a 6-digit verification code to your phone.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: SahyanColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          _buildResponsiveCtaButton(
            label: 'Send OTP',
            isLoading: isLoading,
            onPressed: _handleOtpSend,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpTokenBox(String char, {bool isPlaceholder = false}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlaceholder
              ? SahyanColors.border
              : SahyanColors.primaryMint,
          width: isPlaceholder ? 0.8 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isPlaceholder
              ? SahyanColors.textDisabled
              : SahyanColors.primaryDark,
        ),
      ),
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
            : Row(
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
