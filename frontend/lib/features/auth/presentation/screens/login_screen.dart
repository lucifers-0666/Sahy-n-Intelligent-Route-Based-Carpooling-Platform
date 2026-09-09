import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
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

    // Normalize phone numbers if numeric
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
        SnackBar(content: Text(errorMsg ?? 'Invalid credentials')),
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
          content: Text(errorMsg ?? 'Failed to send OTP. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.softForest,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryForest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sahyān',
                              style: AppTypography.screenTitle.copyWith(
                                color: AppColors.deepForest,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Find people going\nyour way.',
                          style: AppTypography.screenTitle.copyWith(
                            color: AppColors.deepForest,
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share your journey with verified people travelling along the same route.',
                          style: AppTypography.secondary.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Body
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign In',
                          style: AppTypography.screenTitle.copyWith(
                            color: AppColors.deepForest,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Segmented Authentication Method Selector
                        _buildMethodSelector(),

                        const SizedBox(height: 20),

                        // Animated / Switchable Form Content
                        if (_selectedMethod == _LoginMethod.password)
                          _buildPasswordForm(authState.isLoading)
                        else
                          _buildOtpForm(authState.isLoading),

                        const SizedBox(height: 16),

                        // Register Navigation
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: AppTypography.secondary,
                              ),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                child: Text(
                                  'Register Now',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primaryForest,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 12),

                        // Restrained Trust Badges
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              _buildTrustBadge(
                                Icons.check_circle_outline_rounded,
                                'Verified community',
                              ),
                              _buildTrustBadge(
                                Icons.shield_outlined,
                                'Safe shared rides',
                              ),
                              _buildTrustBadge(
                                Icons.currency_rupee_rounded,
                                'Fair contribution',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
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

  Widget _buildMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorTab(
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
            child: _buildSelectorTab(
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

  Widget _buildSelectorTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
              size: 16,
              color: isSelected
                  ? AppColors.primaryForest
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.deepForest
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              color: AppColors.primaryForest,
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
              color: AppColors.primaryForest,
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
              child: Text(
                'Forgot Password?',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryForest,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          PrimaryButton(
            text: 'Sign In',
            isLoading: isLoading,
            onPressed: _handlePasswordLogin,
          ),
        ],
      ),
    );
  }

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
              child: Text(
                '+91',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
          const SizedBox(height: 10),
          Text(
            'We will send a 6-digit verification code to your phone.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          PrimaryButton(
            text: 'Send OTP',
            isLoading: isLoading,
            onPressed: _handleOtpSend,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedSage),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
