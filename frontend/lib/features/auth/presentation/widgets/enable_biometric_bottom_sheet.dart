import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/sahyan_button.dart';

/// "Unlock with fingerprint?" Opt-In Sheet shown after successful login.
class EnableBiometricBottomSheet extends ConsumerWidget {
  const EnableBiometricBottomSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnableBiometricBottomSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);

    return Material(
      color: bgColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.sheet),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceHigh : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sensor Icon with Mint Halo
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 34,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Unlock with fingerprint?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Benefit Text
              Text(
                'Sign in instantly next time without waiting for SMS verification codes. Your biometric credentials remain securely sealed on your hardware enclave.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: mutedColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Enable Primary Action
              SahyanButton(
                text: 'Enable Fingerprint Unlock',
                icon: Icons.fingerprint_rounded,
                variant: SahyanButtonVariant.primary,
                size: SahyanButtonSize.large,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final biometric = ref.read(biometricServiceProvider);
                  final authenticated = await biometric.authenticate(
                    localizedReason: 'Scan fingerprint to verify device ownership',
                  );

                  if (authenticated) {
                    await biometric.setBiometricOptIn(true);
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  }
                },
              ),
              const SizedBox(height: 10),

              // "Not now" Text Action
              Center(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Not now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
