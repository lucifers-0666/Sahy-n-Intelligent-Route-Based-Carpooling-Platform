import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Production Registration Screen for Sahyān.
/// Features Gujarat corridor identity, live security checklist, frosted card styling,
/// responsive keyboard avoidance, and custom feedback architecture.
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

  // Password rules validation state
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

  Color _passwordStrengthColor(SahyanThemeTokens tokens) {
    final score = _passwordStrengthScore;
    if (score <= 1) return tokens.error;
    if (score == 2) return tokens.marigold;
    if (score == 3) return tokens.brand;
    return tokens.mint;
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      FeedbackService.warning(
        context,
        'Please complete all required fields correctly',
      );
      return;
    }

    if (!_isPasswordFullyValid) {
      FeedbackService.warning(
        context,
        'Please meet all password security rules',
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      FeedbackService.error(context, 'Passwords do not match');
      return;
    }

    if (!_agreedToTerms) {
      FeedbackService.warning(
        context,
        'Please agree to the Terms of Service to proceed',
      );
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final localPhone = cleanDigits.length == 12 && cleanDigits.startsWith('91')
        ? cleanDigits.substring(2)
        : cleanDigits;

    final success = await ref
        .read(authProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          phone: localPhone,
          password: _passwordController.text,
        );

    if (success && mounted) {
      FeedbackService.success(
        context,
        'Account created. Verification code sent.',
      );
      context.push('/otp');
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      FeedbackService.error(
        context,
        errorMsg ?? 'Failed to create account. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sahyanTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 14.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopNav(tokens),
                    const SizedBox(height: 16),
                    _buildHeaderBanner(tokens, isDark),
                    const SizedBox(height: 16),
                    _buildFormCard(tokens, isDark, authState.isLoading),
                    const SizedBox(height: 18),
                    _buildBottomDock(tokens),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(SahyanThemeTokens tokens) {
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
                  color: tokens.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.ink.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: tokens.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tokens.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: tokens.brand.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin_circle_rounded,
                      size: 14,
                      color: tokens.brand,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Step 1 of 2: Profile Essentials',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.brand,
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
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: tokens.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.brand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner(SahyanThemeTokens tokens, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: tokens.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: tokens.ink.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SahyanRouteConvergenceMark(size: 32, isDark: isDark),
              const SizedBox(width: 10),
              Text(
                'SAHYĀN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: tokens.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Join Sahyān',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect with verified travellers along major Gujarat highway corridors.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tokens.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(SahyanThemeTokens tokens, bool isDark, bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: tokens.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: tokens.ink.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SahyanTextField(
            label: 'Full Name',
            hint: 'e.g. Arjun Patel',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: tokens.brand,
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

          SahyanTextField(
            label: 'Email Address',
            hint: 'arjun@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color: tokens.brand,
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

          SahyanTextField(
            label: 'Mobile Number',
            hint: '9876543210',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 18, color: tokens.border),
                ],
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Mobile number is required';
              }
              final clean = v.trim().replaceAll(RegExp(r'\D'), '');
              final local = clean.length == 12 && clean.startsWith('91')
                  ? clean.substring(2)
                  : clean;
              if (local.length != 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(local)) {
                return 'Enter a valid mobile starting with 6-9';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          SahyanTextField(
            label: 'Password',
            hint: 'Min. 8 characters with special symbol',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: tokens.brand,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Password is required';
              }
              if (!_isPasswordFullyValid) {
                return 'Password must satisfy all security rules';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          _buildPasswordStrengthCard(tokens),
          const SizedBox(height: 14),

          SahyanTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: Icon(
              Icons.lock_reset_rounded,
              color: tokens.brand,
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

          if (_isConfirmTouched) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _doPasswordsMatch
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
                  size: 15,
                  color: _doPasswordsMatch ? tokens.mint : tokens.error,
                ),
                const SizedBox(width: 6),
                Text(
                  _doPasswordsMatch
                      ? 'Passwords match'
                      : 'Passwords do not match',
                  style: GoogleFonts.plusJakartaSans(
                    color: _doPasswordsMatch ? tokens.brand : tokens.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _buildTermsCheckbox(tokens),
          const SizedBox(height: 20),

          SahyanButton(
            text: 'Register & Verify OTP',
            isLoading: isLoading,
            isFullWidth: true,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthCard(SahyanThemeTokens tokens) {
    final score = _passwordStrengthScore;
    final color = _passwordStrengthColor(tokens);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.canvas,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: tokens.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Security Level:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _passwordStrengthLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

          Row(
            children: List.generate(4, (index) {
              final isFilled = index < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isFilled ? color : tokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildPolicyChip(tokens, '8+ characters', _hasMinLength),
              _buildPolicyChip(tokens, 'Uppercase (A-Z)', _hasUppercase),
              _buildPolicyChip(tokens, 'Lowercase (a-z)', _hasLowercase),
              _buildPolicyChip(tokens, 'Number (0-9)', _hasNumber),
              _buildPolicyChip(tokens, 'Special character', _hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyChip(SahyanThemeTokens tokens, String label, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isMet ? tokens.mint : tokens.muted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isMet ? tokens.ink : tokens.muted,
              fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(SahyanThemeTokens tokens) {
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
                color: _agreedToTerms ? tokens.brand : tokens.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _agreedToTerms ? tokens.brand : tokens.border,
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
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: tokens.muted,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'By continuing, you agree to Sahyān\'s ',
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: tokens.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Community Safety Guidelines',
                      style: TextStyle(
                        color: tokens.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDock(SahyanThemeTokens tokens) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Already part of the community?',
              style: GoogleFonts.plusJakartaSans(
                color: tokens.muted,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.brand,
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
            _buildTrustBadge(
              tokens,
              Icons.verified_user_rounded,
              '100% ID Verified',
            ),
            _buildTrustBadge(tokens, Icons.shield_outlined, 'Safe Travel Ring'),
            _buildTrustBadge(
              tokens,
              Icons.currency_rupee_rounded,
              'Fair Cost Split',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(
    SahyanThemeTokens tokens,
    IconData icon,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tokens.mint),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: tokens.muted,
          ),
        ),
      ],
    );
  }
}
