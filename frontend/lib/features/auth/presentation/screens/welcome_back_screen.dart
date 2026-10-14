import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/config/app_region.dart';
import '../../../../app/providers/user_mode_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/sahyan_logo.dart';
import '../../../../shared/widgets/sahyan_route_background.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Welcome Back / Returning User Screen.
///
/// Features:
/// - Shown on cold start ONLY when a valid session exists AND user opted into biometric unlock
/// - Time-based personalized greeting ("Good morning / afternoon / evening, {name}")
/// - Verified user avatar with initials
/// - Automatic biometric prompt on launch
/// - Retry button and "Use OTP instead" action
/// - Fallback to Phone OTP after 3 consecutive failures
/// - Safe session reset ("Use another account")
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
  int _failedAttempts = 0;

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
    final hasOptedIn = await biometric.hasBiometricOptIn();
    final canBio = await biometric.canAuthenticate();

    if (!mounted) return;

    if (user == null || token == null || token.isEmpty || !hasOptedIn) {
      // No opted-in biometric session found; redirect to standard welcome
      context.go('/welcome');
      return;
    }

    setState(() {
      _savedUser = user;
      _hasBiometrics = canBio;
      _isChecking = false;
    });

    // Automatically prompt biometric on cold start if available and opted in
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
            'Scan fingerprint to unlock your Sahyān account',
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

      _failedAttempts++;
      setState(() => _isLoading = false);

      if (_failedAttempts >= 3) {
        FeedbackService.warning(
          context,
          'Biometric attempts exceeded. Please sign in with Phone OTP.',
        );
        context.push('/login?method=phone');
      }
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
    final userCity = user?.city ?? AppRegion.fallbackCity;
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';

    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      body: SahyanRouteBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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
                    // Brand Mark Header (Master Logo)
                    const Center(child: SahyanLogo.mark(size: 38)),
                    const SizedBox(height: 36),

                    // Avatar with Initials & Verified Ring
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
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
                                    alpha: 0.30,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                userInitial,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 17,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Personalized Greeting
                    Text(
                      '$_timeBasedGreeting,',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Corridor Member Pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkSurface
                                  : Colors.white)
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurfaceHigh
                                : AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place,
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
                    ),
                    const SizedBox(height: 36),

                    // Unlock with Biometrics Primary Action
                    if (_hasBiometrics) ...[
                      SahyanButton(
                        text: 'Unlock with Fingerprint',
                        icon: Icons.fingerprint,
                        variant: SahyanButtonVariant.primary,
                        size: SahyanButtonSize.large,
                        isLoading: _isLoading,
                        onPressed: _handleBiometricUnlock,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Fallback to Phone OTP
                    SahyanButton(
                      text: 'Use OTP instead',
                      icon: Icons.phone_android,
                      variant: _hasBiometrics
                          ? SahyanButtonVariant.secondary
                          : SahyanButtonVariant.primary,
                      size: SahyanButtonSize.large,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/login?method=phone');
                      },
                    ),
                    const SizedBox(height: 20),

                    // "Use another account" reset option
                    Center(
                      child: TextButton(
                        onPressed: _handleUseAnotherAccount,
                        child: Text(
                          'Use another account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                            decoration: TextDecoration.underline,
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
      ),
    );
  }
}
