import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/router/app_router.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/localization/app_locale_provider.dart';
import 'package:sahyan/core/localization/sahyan_localizations.dart';
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
      supportedLocales: SahyanLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        SahyanLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

/// Backwards compatibility alias
typedef App = SahyanApp;
