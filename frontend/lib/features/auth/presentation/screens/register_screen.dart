import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Live password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  bool _isConfirmTouched = false;
  bool _doPasswordsMatch = false;
  bool _agreedToTerms = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  void _onPasswordChanged() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasSpecialChar = RegExp(r'[\W_]').hasMatch(password);

      if (_isConfirmTouched) {
        _doPasswordsMatch =
            password.isNotEmpty && password == _confirmPasswordController.text;
      }
    });
  }

  void _onConfirmPasswordChanged() {
    final confirm = _confirmPasswordController.text;
    setState(() {
      _isConfirmTouched = confirm.isNotEmpty;
      _doPasswordsMatch =
          confirm.isNotEmpty && confirm == _passwordController.text;
    });
  }

  bool get _isPasswordFullyValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  int get _passwordStrengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase && _hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  String get _passwordStrengthLabel {
    final score = _passwordStrengthScore;
    if (score == 0) return 'Too Weak';
    if (score == 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  Color get _passwordStrengthColor {
    final score = _passwordStrengthScore;
    if (score <= 1) return SahyanColors.urgentCoral;
    if (score == 2) return SahyanColors.goldStar;
    if (score == 3) return SahyanColors.primaryDark;
    return SahyanColors.primaryMint;
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPasswordFullyValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.textMain,
          content: const Text(
            'Please satisfy all password security requirements',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.urgentCoral,
          content: const Text(
            'Passwords do not match',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SahyanColors.urgentCoral,
          content: const Text(
            'Please agree to the Terms of Service to continue',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final localPhone = cleanDigits.length == 12 && cleanDigits.startsWith('91')
        ? cleanDigits.substring(2)
        : cleanDigits;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          phone: localPhone,
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.push('/otp');
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      if (errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: SahyanColors.urgentCoral,
            content: Text(
              errorMsg,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Navigation Header: Circle Back Button + Step Badge + Animated Progress Line
                    _buildTopNav()
                        .animate()
                        .fadeIn(duration: 350.ms, curve: Curves.easeOut),

                    const SizedBox(height: 16),

                    // Header Gateway
                    _buildHeaderBanner()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 50.ms, curve: Curves.easeOut)
                        .slideY(begin: -0.05, end: 0),

                    const SizedBox(height: 16),

                    // Bento Form Container
                    _buildFormBentoCard(authState.isLoading)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 100.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 18),

                    // Bottom Navigation Dock
                    _buildBottomDock()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 150.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Navigation Bar: Circle Back Button + Step Pill with Progress Line
  Widget _buildTopNav() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SahyanColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: SahyanColors.border, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0614241C),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: SahyanColors.textMain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SahyanColors.primaryMint.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin_circle_rounded,
                      size: 14,
                      color: SahyanColors.primaryDark,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Step 1 of 2: Profile Essentials',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 2-Step Animated Progress Bar (50% progress for Step 1)
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: SahyanColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: SahyanColors.primaryMint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Header Banner
  Widget _buildHeaderBanner() {
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
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join Sahyān',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: SahyanColors.textMain,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Connect with verified professionals travelling along your daily route.',
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

  /// Main Form Bento Card
  Widget _buildFormBentoCard(bool isLoading) {
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
          // 0: Full Name
          AppTextField(
            label: 'Full Name',
            hint: 'e.g. Arjun Patel',
            controller: _nameController,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: SahyanColors.primaryDark,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Full name is required';
              }
              if (v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              if (v.trim().length > 50) {
                return 'Name cannot exceed 50 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // 1: Email Address
          AppTextField(
            label: 'Email Address',
            hint: 'arjun@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(
              Icons.alternate_email_rounded,
              color: SahyanColors.primaryDark,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email is required';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // 2: Mobile Number
          AppTextField(
            label: 'Mobile Number',
            hint: '9876543210',
            controller: _phoneController,
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
                return 'Mobile number is required';
              }
              final clean = v.trim().replaceAll(RegExp(r'\D'), '');
              final local =
                  clean.length == 12 && clean.startsWith('91')
                      ? clean.substring(2)
                      : clean;
              if (local.length != 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(local)) {
                return 'Enter a valid Indian mobile number starting with 6-9';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // 3: Password
          AppTextField(
            label: 'Password',
            hint: 'Min. 8 characters with special character',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: SahyanColors.primaryDark,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Password is required';
              }
              if (!_isPasswordFullyValid) {
                return 'Password must satisfy all security rules below';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Interactive Dynamic Strength Meter + Inline Requirements
          _buildPasswordStrengthCard(),
          const SizedBox(height: 14),

          // 4: Confirm Password
          AppTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_reset_rounded,
              color: SahyanColors.primaryDark,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please confirm your password';
              }
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          // Real-time Confirm Password Match Feedback
          if (_isConfirmTouched) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _doPasswordsMatch
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
                  size: 15,
                  color: _doPasswordsMatch
                      ? SahyanColors.primaryMint
                      : SahyanColors.urgentCoral,
                ),
                const SizedBox(width: 6),
                Text(
                  _doPasswordsMatch
                      ? 'Passwords match'
                      : 'Passwords do not match',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: _doPasswordsMatch
                        ? SahyanColors.primaryDark
                        : SahyanColors.urgentCoral,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Terms & Privacy Agreement
          _buildTermsCheckbox(),

          const SizedBox(height: 20),

          // Primary CTA Button: Height 50-52dp, Rounded 16px, Pine #1B4D3E
          PrimaryButton(
            text: 'Register & Verify OTP',
            isLoading: isLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  /// Dynamic Strength Meter & Policy Checklist
  Widget _buildPasswordStrengthCard() {
    final score = _passwordStrengthScore;
    final color = _passwordStrengthColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SahyanColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Security Level:',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SahyanColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _passwordStrengthLabel,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                _isPasswordFullyValid
                    ? Icons.verified_rounded
                    : Icons.shield_outlined,
                size: 14,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4-Segment Dynamic Color Bar
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? color
                        : SahyanColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Inline Requirements Checklist
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildPolicyChip('8+ characters', _hasMinLength),
              _buildPolicyChip('Uppercase (A-Z)', _hasUppercase),
              _buildPolicyChip('Lowercase (a-z)', _hasLowercase),
              _buildPolicyChip('Number (0-9)', _hasNumber),
              _buildPolicyChip('Special character', _hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyChip(String label, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isMet
              ? SahyanColors.primaryMint
              : SahyanColors.textDisabled,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            color: isMet ? SahyanColors.textMain : SahyanColors.textMuted,
            fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Terms & Privacy Agreement Row
  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _agreedToTerms = !_agreedToTerms;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: _agreedToTerms
                    ? SahyanColors.primaryDark
                    : SahyanColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _agreedToTerms
                      ? SahyanColors.primaryDark
                      : SahyanColors.border,
                  width: 1.2,
                ),
              ),
              child: _agreedToTerms
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: SahyanColors.textMuted,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'By continuing, you agree to Sahyān\'s '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: SahyanColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Community Safety Guidelines',
                      style: TextStyle(
                        color: SahyanColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Alternate Link & Trust Dock
  Widget _buildBottomDock() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Already part of the community?',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: SahyanColors.textMuted,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              child: const Text(
                'Sign In',
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
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildTrustBadge(Icons.verified_user_rounded, '100% ID Verified'),
            _buildTrustBadge(Icons.shield_outlined, 'Safe Travel Ring'),
            _buildTrustBadge(Icons.currency_rupee_rounded, 'Fair Cost Split'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: SahyanColors.primaryMint),
        const SizedBox(width: 4),
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
    );
  }
}
