import 'package:flutter/material.dart';
import 'package:sahyan/app/router/app_router.dart';
import 'package:sahyan/app/theme/app_theme.dart';

class SahyanApp extends StatelessWidget {
  const SahyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sahyān',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

/// Backwards compatibility alias
typedef App = SahyanApp;
