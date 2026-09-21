import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/shared/widgets/app_shell.dart';
import 'package:sahyan/shared/widgets/auth_gate_dialog.dart';

void main() {
  Widget buildTestNavBar({
    int currentIndex = 0,
    ValueChanged<int>? onTap,
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(bottom: 24),
          viewPadding: const EdgeInsets.only(bottom: 24),
        ),
        child: Scaffold(
          body: const Center(child: Text('Screen Content')),
          bottomNavigationBar: FloatingBottomNavBar(
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('FloatingBottomNavBar Component Tests', () {
    testWidgets(
      'Renders all 5 navigation positions with correct labels and icons',
      (tester) async {
        await tester.pumpWidget(buildTestNavBar(currentIndex: 0));
        await tester.pumpAndSettle();

        // Verify labels exist
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Rides'), findsOneWidget);
        expect(find.text('Offer Ride'), findsOneWidget);
        expect(find.text('Bookings'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Verify icons
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
        expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
        expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
        expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      },
    );

    testWidgets('Tapping each navigation destination triggers onTap callback', (
      tester,
    ) async {
      int tappedIndex = -1;
      await tester.pumpWidget(
        buildTestNavBar(currentIndex: 0, onTap: (index) => tappedIndex = index),
      );
      await tester.pumpAndSettle();

      // Tap Rides
      await tester.tap(find.text('Rides'));
      await tester.pump();
      expect(tappedIndex, 1);

      // Tap Center Offer Ride button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(tappedIndex, 2);

      // Tap Bookings
      await tester.tap(find.text('Bookings'));
      await tester.pump();
      expect(tappedIndex, 3);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(tappedIndex, 4);

      // Tap Home
      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(tappedIndex, 0);
    });

    testWidgets(
      'Updates active state visual representation when index changes',
      (tester) async {
        // Index 1 (Rides active)
        await tester.pumpWidget(buildTestNavBar(currentIndex: 1));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);

        // Index 3 (Bookings active)
        await tester.pumpWidget(buildTestNavBar(currentIndex: 3));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.confirmation_number_rounded), findsOneWidget);
        expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

        // Index 4 (Profile active)
        await tester.pumpWidget(buildTestNavBar(currentIndex: 4));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Center Offer Ride button is elevated with primary forest green styling',
      (tester) async {
        await tester.pumpWidget(buildTestNavBar(currentIndex: 0));
        await tester.pumpAndSettle();

        final addIcon = tester.widget<Icon>(find.byIcon(Icons.add_rounded));
        expect(addIcon.color, AppColors.white);
        expect(addIcon.size, 28);

        final elevatedCircleFinder = find.ancestor(
          of: find.byIcon(Icons.add_rounded),
          matching: find.byType(Container),
        );
        expect(elevatedCircleFinder, findsWidgets);

        final circleContainer = tester.widget<Container>(
          elevatedCircleFinder.first,
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, AppColors.primaryForest);
        expect(decoration.shape, BoxShape.circle);
      },
    );
  });

  group('Responsive Layout & Zero Overflow Tests', () {
    final viewports = [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
      const Size(600, 1024),
      const Size(800, 1280),
    ];

    for (final size in viewports) {
      testWidgets('Renders without overflow at ${size.width}x${size.height}', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestNavBar(size: size));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Rides'), findsOneWidget);
        expect(find.text('Offer Ride'), findsOneWidget);
        expect(find.text('Bookings'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      });
    }

    testWidgets(
      'Renders without overflow under 1.5x font scale on 320dp width',
      (tester) async {
        await tester.pumpWidget(
          buildTestNavBar(size: const Size(320, 568), textScale: 1.5),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Rides'), findsOneWidget);
        expect(find.text('Offer Ride'), findsOneWidget);
        expect(find.text('Bookings'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );
  });

  group('Guest Authentication Gate Tests', () {
    Widget buildGatedTestApp({required bool isGuest}) {
      return ProviderScope(
        overrides: [
          userModeProvider.overrideWith((ref) {
            final notifier = UserModeNotifier();
            if (isGuest) {
              notifier.setGuestMode();
            }
            return notifier;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Consumer(
            builder: (context, ref, child) {
              final isGuestUser = ref.watch(userModeProvider).isGuest;
              return Scaffold(
                bottomNavigationBar: FloatingBottomNavBar(
                  currentIndex: 0,
                  onTap: (index) {
                    if (isGuestUser && index != 0 && index != 1) {
                      String title = 'Sign In Required';
                      String msg = 'Please sign in.';
                      String route = '/home';

                      if (index == 2) {
                        title = 'Sign In to Offer Rides';
                        msg =
                            'Sharing your vehicle seats requires verification.';
                        route = '/offer-ride';
                      } else if (index == 3) {
                        title = 'Sign In to View Bookings';
                        msg = 'Sign in to manage bookings.';
                        route = '/my-bookings';
                      } else if (index == 4) {
                        title = 'Sign In to View Profile';
                        msg = 'Manage your account settings.';
                        route = '/profile';
                      }

                      AuthGateDialog.show(
                        context,
                        title: title,
                        message: msg,
                        intendedRoute: route,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets(
      'Guest can tap Home and Rides without trigger of AuthGateDialog',
      (tester) async {
        await tester.pumpWidget(buildGatedTestApp(isGuest: true));
        await tester.pumpAndSettle();

        // Tap Home
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.byType(AuthGateDialog), findsNothing);

        // Tap Rides
        await tester.tap(find.text('Rides'));
        await tester.pumpAndSettle();
        expect(find.byType(AuthGateDialog), findsNothing);
      },
    );

    testWidgets(
      'Guest tapping Offer Ride triggers AuthGateDialog for Offer Rides',
      (tester) async {
        await tester.pumpWidget(buildGatedTestApp(isGuest: true));
        await tester.pumpAndSettle();

        // Tap center elevated Offer Ride button
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AuthGateDialog), findsOneWidget);
        expect(find.text('Sign In to Offer Rides'), findsOneWidget);
      },
    );

    testWidgets('Guest tapping Bookings triggers AuthGateDialog for Bookings', (
      tester,
    ) async {
      await tester.pumpWidget(buildGatedTestApp(isGuest: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthGateDialog), findsOneWidget);
      expect(find.text('Sign In to View Bookings'), findsOneWidget);
    });

    testWidgets('Guest tapping Profile triggers AuthGateDialog for Profile', (
      tester,
    ) async {
      await tester.pumpWidget(buildGatedTestApp(isGuest: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthGateDialog), findsOneWidget);
      expect(find.text('Sign In to View Profile'), findsOneWidget);
    });
  });
}
