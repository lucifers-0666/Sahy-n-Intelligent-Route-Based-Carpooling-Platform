import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

/// Extension providing easy, type-safe access to localized strings via [context.l10n].
/// Gracefully falls back to English when running in unit/widget tests where delegates
/// may not have been registered in MaterialApp.
extension L10nX on BuildContext {
  AppLocalizations get l10n {
    final localizations = Localizations.of<AppLocalizations>(this, AppLocalizations);
    if (localizations != null) {
      return localizations;
    }
    return lookupAppLocalizations(const Locale('en'));
  }
}
