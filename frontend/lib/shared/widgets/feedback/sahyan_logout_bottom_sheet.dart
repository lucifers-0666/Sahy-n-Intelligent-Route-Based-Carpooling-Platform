import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers/user_mode_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/localization/sahyan_localizations.dart';
import '../../../core/widgets/sahyan_button.dart';
import '../../../features/auth/presentation/auth_provider.dart';

/// Calm, elegant bottom sheet for confirming account logout.
/// Replaces standard harsh red dialogs with an outlined destructive action.
class SahyanLogoutBottomSheet extends ConsumerWidget {
  const SahyanLogoutBottomSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => const SahyanLogoutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);
    final l10n = SahyanLocalizations.of(context);

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
              // Drag Handle
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

              // Soft Logout Icon (Calm neutral with subtle tint)
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurfaceHigh
                            : const Color(0xFFF3F4F6)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.logout,
                      size: 24,
                      color: isDark ? AppColors.darkText : AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                l10n.logoutPromptTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Body
              Text(
                l10n.logoutPromptMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: mutedColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Calm Outlined Destructive Action (Log Out)
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(true);
                    await ref.read(authProvider.notifier).logout();
                    ref.read(userModeProvider.notifier).resetOnLogout();
                    if (context.mounted) {
                      context.go('/welcome');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    foregroundColor: AppColors.error,
                  ),
                  child: Text(
                    l10n.logOutAction,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Primary Action: Keep Logged In
              SahyanButton(
                text: l10n.keepLoggedIn,
                variant: SahyanButtonVariant.primary,
                size: SahyanButtonSize.regular,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
