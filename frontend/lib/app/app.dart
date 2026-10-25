import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/router/app_router.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/localization/app_locale_provider.dart';
import 'package:sahyan/l10n/generated/app_localizations.dart';

class SahyanApp extends ConsumerWidget {
  const SahyanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Sahyān',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
      theme: AppTheme.light(currentLocale),
      darkTheme: AppTheme.dark(currentLocale),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

/// Backwards compatibility alias
typedef App = SahyanApp;
