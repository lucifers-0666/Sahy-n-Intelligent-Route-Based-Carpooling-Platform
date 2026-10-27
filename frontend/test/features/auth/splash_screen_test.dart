import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/auth/presentation/screens/splash_screen.dart';
import 'package:sahyan/l10n/generated/app_localizations.dart';
import 'package:sahyan/shared/widgets/sahyan_brand_mark.dart';
import 'package:sahyan/shared/widgets/sahyan_logo.dart';
import 'package:sahyan/shared/widgets/sahyan_route_convergence_logo.dart';

Widget _buildSplashApp({
  required Widget child,
  double width = 390,
  double height = 844,
  bool disableAnimations = false,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: disableAnimations,
        ),
        child: child,
      ),
    ),
  );
}

Widget _buildSplashRouterApp({
  GoRouter? router,
  double width = 390,
  double height = 844,
  bool disableAnimations = false,
  List<Override> overrides = const [],
}) {
  final testRouter =
      router ??
      GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/welcome',
            builder: (context, state) =>
                const Scaffold(body: Text('Welcome Screen')),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('Home Screen')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) =>
                const Scaffold(body: Text('Onboarding Screen')),
          ),
        ],
      );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: testRouter,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: disableAnimations,
        ),
        child: child ?? const SizedBox(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SahyanBrandMark & Painter Tests', () {
    testWidgets('Renders cleanly with and without vehicles', (tester) async {
      await tester.pumpWidget(
        _buildSplashApp(
          child: const Scaffold(
            body: Center(
              child: SahyanBrandMark(
                size: 80,
                showVehicles: true,
                isDark: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SahyanBrandMark), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'CustomPainter paints correctly across different progress steps',
      (tester) async {
        final painterFull = const SahyanBrandMarkPainter(
          originProgress: 1.0,
          drawProgress: 1.0,
          vehicleProgress: 1.0,
          hubPulseProgress: 0.5,
          showVehicles: true,
          isDark: true,
        );

        final painterHalf = const SahyanBrandMarkPainter(
          originProgress: 0.5,
          drawProgress: 0.5,
          vehicleProgress: 0.4,
          hubPulseProgress: 0.0,
          showVehicles: true,
          isDark: false,
        );

        expect(painterFull.shouldRepaint(painterHalf), isTrue);
        expect(painterFull.shouldRepaint(painterFull), isFalse);
      },
    );
  });

  group('SahyanAnimatedRouteLogo Tests', () {
    testWidgets('Renders wordmark characters and new tagline on first frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSplashApp(
          child: const Scaffold(
            body: Center(
              child: SahyanAnimatedRouteLogo(
                size: 110,
                isDark: true,
                showWordmark: true,
                showTagline: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Different paths. One shared journey.'), findsOneWidget);
      for (final letter in ['S', 'a', 'h', 'y', 'ā', 'n']) {
        expect(find.text(letter), findsOneWidget);
      }
    });

    testWidgets('Fires onComplete after 3.0s animation finishes', (
      tester,
    ) async {
      bool completed = false;
      await tester.pumpWidget(
        _buildSplashApp(
          child: Scaffold(
            body: Center(
              child: SahyanAnimatedRouteLogo(
                size: 110,
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      // Advance through the calibrated 3.0s animation sequence
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets(
      'Respects system reduced-motion (disableAnimations) immediately',
      (tester) async {
        bool completed = false;
        await tester.pumpWidget(
          _buildSplashApp(
            disableAnimations: true,
            child: Scaffold(
              body: Center(
                child: SahyanAnimatedRouteLogo(
                  size: 110,
                  onComplete: () => completed = true,
                ),
              ),
            ),
          ),
        );

        // PostFrameCallback triggers on first frame
        await tester.pump();
        expect(completed, isTrue);
        expect(
          find.text('Different paths. One shared journey.'),
          findsOneWidget,
        );
      },
    );
  });

  group('SplashScreen Screen-Size Responsiveness Tests', () {
    final screenWidths = [320.0, 360.0, 390.0, 412.0, 600.0];

    for (final width in screenWidths) {
      testWidgets('SplashScreen renders without overflow on width ${width}dp', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildSplashRouterApp(width: width, height: 800),
        );
        await tester.pump();

        expect(find.byType(SplashScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance 1s and check no overflow
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'SplashScreen handles safety timeout (4200ms) and navigates cleanly',
      (tester) async {
        await tester.pumpWidget(_buildSplashRouterApp());
        await tester.pump();

        expect(find.byType(SplashScreen), findsOneWidget);

        // Advance through 3000ms animation
        await tester.pump(const Duration(milliseconds: 3000));
        expect(tester.takeException(), isNull);

        // Advance past 4200ms safety timeout
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Welcome Screen'), findsOneWidget);
      },
    );
  });

  group('SahyanLogo Variant Tests', () {
    testWidgets('All SahyanLogo variants render with new brand configuration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSplashApp(
          child: const Scaffold(
            body: Column(
              children: [
                SahyanLogo.mark(size: 32),
                SahyanLogo.horizontal(size: 32, showTagline: true),
                SahyanLogo.stacked(size: 40, showTagline: true),
                SahyanLogo.mono(size: 32),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SahyanLogo), findsNWidgets(4));
      expect(find.text('Different paths. One shared journey.'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
