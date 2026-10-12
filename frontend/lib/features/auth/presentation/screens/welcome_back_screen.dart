import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Welcome Back / Returning User Screen.
///
/// Features:
/// - Personalized time-based greeting ("Good morning / afternoon / evening, {name}")
/// - Verified user avatar with initials and account status
/// - Remembered recent route corridor badge
/// - Prominent hardware biometric unlock (displayed ONLY when valid session exists)
/// - Safe fallback to Phone OTP / password sign-in
/// - "Use another account" safe session reset
class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  UserModel? _savedUser;
  bool _hasBiometrics = false;
  bool _isLoading = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final storage = ref.read(secureStorageServiceProvider);
    final biometric = ref.read(biometricServiceProvider);

    final user = await storage.getUser();
    final token = await storage.getToken();
    final canBio = await biometric.canAuthenticate();

    if (!mounted) return;

    if (user == null || token == null || token.isEmpty) {
      // No saved session found; redirect to standard welcome
      context.go('/welcome');
      return;
    }

    setState(() {
      _savedUser = user;
      _hasBiometrics = canBio;
      _isChecking = false;
    });

    // Automatically prompt biometric if available and enrolled
    if (canBio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleBiometricUnlock();
      });
    }
  }

  String get _timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _handleBiometricUnlock() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final biometric = ref.read(biometricServiceProvider);
      final didAuth = await biometric.authenticate(
        localizedReason:
            'Scan fingerprint or face to unlock your Sahyān account',
      );

      if (!mounted) return;

      if (didAuth) {
        final success = await ref
            .read(authProvider.notifier)
            .loginWithBiometrics();
        if (!mounted) return;

        if (success) {
          FeedbackService.success(
            context,
            'Welcome back, ${_savedUser?.name ?? 'Traveller'}!',
          );
          ref.read(userModeProvider.notifier).setAuthenticatedMode();
          final pending = ref.read(userModeProvider).pendingProtectedIntent;
          ref.read(userModeProvider.notifier).clearPendingIntent();
          context.go(pending != null && pending.isNotEmpty ? pending : '/home');
          return;
        }
      }

      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUseAnotherAccount() async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.clearSession();
    ref.read(userModeProvider.notifier).resetOnLogout();
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.canvasLight,
        body: Center(child: SizedBox.shrink()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _savedUser;
    final userName = user?.name ?? 'Traveller';
    final userCity = user?.city ?? 'Ahmedabad';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';

    final cardBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(height: 32),

                  // Returning User Card with Frosted Glass
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.06,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar with Initials & Verified Ring
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.brand,
                                        AppColors.brandBright,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brand.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      userInitial,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Personalized Greeting
                            Text(
                              '$_timeBasedGreeting,',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Recent Route Corridor Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceHigh
                                    : AppColors.canvasLight,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.place_rounded,
                                    size: 14,
                                    color: AppColors.mint,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$userCity · Corridor Member',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Prominent Biometric Action (if hardware enrolled)
                            if (_hasBiometrics) ...[
                              SahyanButton(
                                text: 'Unlock with Biometrics',
                                icon: Icons.fingerprint_rounded,
                                variant: SahyanButtonVariant.primary,
                                isLoading: _isLoading,
                                onPressed: _handleBiometricUnlock,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Fallback to Phone OTP or Password
                            SahyanButton(
                              text: 'Sign in with phone OTP',
                              icon: Icons.phone_android_rounded,
                              variant: _hasBiometrics
                                  ? SahyanButtonVariant.secondary
                                  : SahyanButtonVariant.primary,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.push('/login');
                              },
                            ),
                            const SizedBox(height: 18),

                            // "Use another account" reset option
                            TextButton(
                              onPressed: _handleUseAnotherAccount,
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.mutedLight,
                              ),
                              child: Text(
                                'Use another account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
