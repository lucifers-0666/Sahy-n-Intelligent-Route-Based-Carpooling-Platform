import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
export 'auth_screen.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/feedback/sahyan_dialog.dart';
import '../../../../shared/widgets/feedback/sahyan_loader.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../auth_provider.dart';

enum _LoginTab { phoneOtp, password }

/// Redesigned 2026 Production Sign-In Screen for Sahyān.
///
/// Features:
/// - Phone OTP as the primary passwordless experience
/// - Indian mobile number input with +91 country prefix chip
/// - Clean secondary password/email flow
/// - Enrolled-session biometric gating (hides biometric when no valid session exists)
/// - Integrated with real AuthNotifier and AuthRepository
/// - Full light/dark mode support with 2026 design tokens
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _phoneController =
      TextEditingController(); // Empty initial state; no sample prefill
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  _LoginTab _activeTab = _LoginTab.phoneOtp;
  bool _isRequestingOtp = false;
  bool _isSigningIn = false;
  bool _isSigningInWithGoogle = false;

  UserModel? _savedUser;
  bool _hasSavedEnrolledBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkSavedSessionForBiometrics();
  }

  Future<void> _checkSavedSessionForBiometrics() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final biometric = ref.read(biometricServiceProvider);

      final user = await storage.getUser();
      final token = await storage.getToken();
      final canBio = await biometric.canAuthenticate();

      if (mounted &&
          user != null &&
          token != null &&
          token.isNotEmpty &&
          canBio) {
        setState(() {
          _savedUser = user;
          _hasSavedEnrolledBiometrics = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    final rawPhone = _phoneController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;

    if (cleanPhone.length != 10) {
      FeedbackService.error(
        context,
        'Please enter a valid 10-digit Indian mobile number',
      );
      return;
    }

    setState(() => _isRequestingOtp = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .sendFirebasePhoneOtp(cleanPhone);

      if (!mounted) return;
      setState(() => _isRequestingOtp = false);

      if (success) {
        FeedbackService.success(
          context,
          'Verification code sent to +91 $cleanPhone',
        );
        context.push('/otp');
      } else {
        final errorMsg = ref.read(authProvider).errorMessage;
        FeedbackService.error(
          context,
          errorMsg ??
              'Failed to send verification code. Please check your network.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingOtp = false);
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
        FeedbackService.success(context, 'Signed in with Google successfully');
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

  Future<void> _handlePasswordLogin() async {
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
          authState.errorMessage ?? 'Invalid phone/email or password',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        FeedbackService.error(context, e.toString());
      }
    }
  }

  Future<void> _handleExpressBiometrics() async {
    final biometric = ref.read(biometricServiceProvider);
    final didAuth = await biometric.authenticate(
      localizedReason: 'Scan fingerprint or face to authenticate instantly',
    );

    if (!mounted || !didAuth) return;

    final success = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (!mounted) return;

    if (success) {
      FeedbackService.success(
        context,
        'Welcome back, ${_savedUser?.name ?? 'User'}!',
      );
      final pendingIntent = ref.read(userModeProvider).pendingProtectedIntent;
      ref.read(userModeProvider.notifier).setAuthenticatedMode();
      ref.read(userModeProvider.notifier).clearPendingIntent();
      context.go(
        pendingIntent != null && pendingIntent.isNotEmpty
            ? pendingIntent
            : '/home',
      );
    } else {
      FeedbackService.error(
        context,
        'Biometric authentication could not resolve session. Please sign in with OTP or password.',
      );
    }
  }

  void _showTermsDialog() {
    SahyanDialog.show(
      context: context,
      title: 'Terms & Privacy',
      message:
          'Sahyān is Gujarat\'s community-driven verified intercity carpooling network. By signing in, you agree to our fair cost-sharing policies, community safety standards, and verified identity requirements.',
      primaryActionText: 'Understood',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            constraints: const BoxConstraints(maxWidth: 460),
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

                  // Title: "Sign In"
                  Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeTab == _LoginTab.phoneOtp
                        ? 'Enter your mobile number to receive a secure one-time passcode.'
                        : 'Access your account with your phone or email credentials.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: mutedColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Enrolled Biometric Express Pass (ONLY rendered if session is verified)
                  if (_hasSavedEnrolledBiometrics && _savedUser != null) ...[
                    _buildEnrolledBiometricBar(isDark),
                    const SizedBox(height: 16),
                  ],

                  // Method Segmented Tab Switcher (Phone OTP vs Password)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceHigh.withValues(alpha: 0.6)
                          : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            title: 'Phone OTP',
                            icon: Icons.phone_android_rounded,
                            isSelected: _activeTab == _LoginTab.phoneOtp,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _activeTab = _LoginTab.phoneOtp);
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            title: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isSelected: _activeTab == _LoginTab.password,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _activeTab = _LoginTab.password);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Card Form Container
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
                        child: _activeTab == _LoginTab.phoneOtp
                            ? _buildPhoneOtpForm(isDark)
                            : _buildPasswordForm(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Alternative Auth Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: borderColor, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR CONTINUE WITH',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: mutedColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: borderColor, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bespoke Google Sign-In Button
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSigningInWithGoogle
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _handleGoogleSignIn();
                              },
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: Center(
                          child: _isSigningInWithGoogle
                              ? const SahyanLoader(size: 20)
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'G',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF4285F4),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          'Continue with Google',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.darkText
                                                : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Don't have an account? Sign up
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push('/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.mint
                              : AppColors.brand,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(
                          'Register',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Terms & Privacy Note
                  Center(
                    child: GestureDetector(
                      onTap: _showTermsDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Terms of Service & Privacy Policy',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: mutedColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? AppColors.brandBright : Colors.white;
    final activeText = isDark ? Colors.white : AppColors.ink;
    final inactiveText = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.brand)
                  : inactiveText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeText : inactiveText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledBiometricBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceHigh
            : AppColors.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark
              ? AppColors.mint.withValues(alpha: 0.3)
              : AppColors.brand.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: _handleExpressBiometrics,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.mint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_savedUser?.name ?? 'Traveller'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.ink,
                      ),
                    ),
                    Text(
                      'Tap for one-touch biometric unlock',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppColors.darkMuted : AppColors.mutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneOtpForm(bool isDark) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mobile Number Input with +91 Prefix
          AppTextField(
            label: 'Mobile Number',
            hint: '98765 43210',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AppColors.darkSurfaceHigh
                        : AppColors.border,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: AppColors.mint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+91',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your mobile number';
              }
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.length != 10) {
                return 'Enter a valid 10-digit Indian mobile number';
              }
              if (!RegExp(r'^[6-9]').hasMatch(digits)) {
                return 'Indian mobile numbers start with 6, 7, 8, or 9';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Primary Action: Get Verification Code
          SahyanButton(
            text: 'Get Verification Code',
            icon: Icons.send_rounded,
            variant: SahyanButtonVariant.primary,
            size: SahyanButtonSize.regular,
            isLoading: _isRequestingOtp,
            onPressed: _handleGetOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm(bool isDark) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identifier: Email or Phone
          AppTextField(
            label: 'Email or Mobile Number',
            hint: 'name@example.com or 9876543210',
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: AppColors.mint,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email or phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.mint,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/forgot-password');
              },
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.mint : AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Action: Sign In
          SahyanButton(
            text: 'Sign In',
            icon: Icons.login_rounded,
            variant: SahyanButtonVariant.primary,
            size: SahyanButtonSize.regular,
            isLoading: _isSigningIn,
            onPressed: _handlePasswordLogin,
          ),
        ],
      ),
    );
  }
}
