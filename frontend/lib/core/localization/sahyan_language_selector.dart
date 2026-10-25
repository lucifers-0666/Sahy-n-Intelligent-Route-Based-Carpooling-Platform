import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_locale_provider.dart';

/// Compact, premium language selector pill (English / ગુજરાતી / हिन्दी)
class SahyanLanguageSelector extends ConsumerWidget {
  final bool isDark;

  const SahyanLanguageSelector({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);
    final isThemeDark =
        isDark || Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isThemeDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isThemeDark
              ? AppColors.darkSurfaceHigh
              : AppColors.border.withValues(alpha: 0.9),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SahyanLanguage.values.map((lang) {
          final isSelected = lang.code == currentLocale.languageCode;
          return GestureDetector(
            onTap: () async {
              if (isSelected) return;
              HapticFeedback.selectionClick();
              await ref.read(appLocaleProvider.notifier).setLocale(lang.locale);
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                final newL10n = lookupAppLocalizations(lang.locale);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newL10n.languageChangedSuccess,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.brand,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isThemeDark ? AppColors.brandBright : AppColors.brand)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                lang == SahyanLanguage.english
                    ? 'EN'
                    : (lang == SahyanLanguage.gujarati ? 'ગુ' : 'हि'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isThemeDark
                          ? AppColors.darkMuted
                          : AppColors.mutedLight),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
