import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/core/widgets/design_system.dart';
import 'package:sahyan/shared/models/booking_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

void main() {
  Widget wrapWithTheme(
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(backgroundColor: AppColors.warmBackground, body: child),
      ),
    );
  }

  group('Sahyān Design Tokens & Typography', () {
    test('AppColors contains all Stitch/Figma organic palette tokens', () {
      expect(AppColors.primaryForest, const Color(0xFF285A4A));
      expect(AppColors.deepForest, const Color(0xFF193D33));
      expect(AppColors.softForest, const Color(0xFFDDE9E3));
      expect(AppColors.warmBackground, const Color(0xFFF6F7F4));
      expect(AppColors.mutedBrass, const Color(0xFFB99558));
      expect(AppColors.softBrass, const Color(0xFFEFE4CD));
      expect(AppColors.mutedRust, const Color(0xFFA65B4B));
      expect(AppColors.softRust, const Color(0xFFFCEAE8));
      expect(AppColors.textPrimary, const Color(0xFF18211D));
      expect(AppColors.textSecondary, const Color(0xFF68736C));
    });

    test('AppSpacing adheres to mathematical 4dp/8dp grid scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.base, 16.0);
      expect(AppSpacing.lg, 20.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
      expect(AppSpacing.containerMargin, 20.0);
    });

    test('AppRadii adheres to soft geometric curvature scale', () {
      expect(AppRadii.xs, 4.0);
      expect(AppRadii.sm, 8.0);
      expect(AppRadii.md, 12.0);
      expect(AppRadii.lg, 16.0);
      expect(AppRadii.xl, 20.0);
      expect(AppRadii.full, 9999.0);
    });

    test('AppTypography defines Plus Jakarta Sans hierarchy', () {
      expect(AppTypography.displayHero.fontSize, 36);
      expect(AppTypography.pageTitle.fontSize, 28);
      expect(AppTypography.sectionHeader.fontSize, 20);
      expect(AppTypography.cardTitle.fontSize, 16);
      expect(AppTypography.bodyLarge.fontSize, 16);
      expect(AppTypography.bodyMedium.fontSize, 14);
      expect(AppTypography.secondary.fontSize, 13);
      expect(AppTypography.caption.fontSize, 12);
      expect(AppTypography.button.fontSize, 15);
    });
  });

  group('SahyanButton Component Tests', () {
    testWidgets('Renders primary button and triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: SahyanButton(
              text: 'Confirm Ride',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Ride'), findsOneWidget);
      await tester.tap(find.text('Confirm Ride'));
      expect(tapped, isTrue);
    });

    testWidgets('Renders all button variants without crash', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: [
              SahyanButton(
                text: 'Primary',
                variant: SahyanButtonVariant.primary,
                onPressed: () {},
              ),
              SahyanButton(
                text: 'Secondary',
                variant: SahyanButtonVariant.secondary,
                onPressed: () {},
              ),
              SahyanButton(
                text: 'Outline',
                variant: SahyanButtonVariant.outline,
                onPressed: () {},
              ),
              SahyanButton(
                text: 'Ghost',
                variant: SahyanButtonVariant.ghost,
                onPressed: () {},
              ),
              SahyanButton(
                text: 'Destructive',
                variant: SahyanButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Destructive'), findsOneWidget);
    });

    testWidgets('Handles loading state and prevents taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: SahyanButton(
              text: 'Submitting',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(SahyanButton));
      expect(tapped, isFalse);
    });

    testWidgets('Handles disabled state and prevents taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: SahyanButton(
              text: 'Unavailable',
              isDisabled: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unavailable'));
      expect(tapped, isFalse);
    });
  });

  group('SahyanTextField Component Tests', () {
    testWidgets('Renders label, hint, and handles input changes', (
      tester,
    ) async {
      String changedValue = '';
      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: SahyanTextField(
              label: 'Destination',
              hint: 'Enter arrival hub',
              onChanged: (val) => changedValue = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Enter arrival hub'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Pune Station');
      expect(changedValue, 'Pune Station');
    });

    testWidgets('Toggles password visibility on icon press', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Center(
            child: SahyanTextField(hint: 'Password', isPassword: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('SahyanCard Component Tests', () {
    testWidgets('Renders content inside styled card surface', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          SahyanCard(
            onTap: () => tapped = true,
            child: const Text('Route Summary Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Route Summary Card'), findsOneWidget);
      await tester.tap(find.text('Route Summary Card'));
      expect(tapped, isTrue);
    });
  });

  group('SahyanChip & SahyanStatusBadge Tests', () {
    testWidgets('SahyanChip renders selected and unselected states', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          Row(
            children: [
              SahyanChip(
                label: 'Air Conditioned',
                isSelected: true,
                onTap: () => tapped = true,
              ),
              const SahyanChip(label: 'Luggage Allowed', isSelected: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Air Conditioned'), findsOneWidget);
      expect(find.text('Luggage Allowed'), findsOneWidget);

      await tester.tap(find.text('Air Conditioned'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'SahyanStatusBadge renders correct label and icons for statuses',
      (tester) async {
        await tester.pumpWidget(
          wrapWithTheme(
            Column(
              children: [
                SahyanStatusBadge.fromRideStatus(RideStatus.scheduled),
                SahyanStatusBadge.fromRideStatus(RideStatus.boarding),
                SahyanStatusBadge.fromRideStatus(RideStatus.active),
                SahyanStatusBadge.fromRideStatus(RideStatus.completed),
                SahyanStatusBadge.fromRideStatus(RideStatus.cancelled),
                SahyanStatusBadge.fromBookingStatus(BookingStatus.accepted),
                SahyanStatusBadge.fromBookingStatus(BookingStatus.pending),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scheduled'), findsOneWidget);
        expect(find.text('Boarding'), findsOneWidget);
        expect(find.text('Trip in Progress'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Cancelled'), findsOneWidget);
        expect(find.text('Confirmed'), findsOneWidget);
        expect(find.text('Pending Approval'), findsOneWidget);
      },
    );
  });

  group('Sahyan Empty, Loading, and Error States', () {
    testWidgets(
      'SahyanEmptyState renders icon, title, description, and action',
      (tester) async {
        bool actionTriggered = false;
        await tester.pumpWidget(
          wrapWithTheme(
            SahyanEmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No Rides Available',
              description:
                  'Try adjusting your departure date or search filters.',
              actionText: 'Search Again',
              onAction: () => actionTriggered = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Rides Available'), findsOneWidget);
        expect(
          find.text('Try adjusting your departure date or search filters.'),
          findsOneWidget,
        );
        expect(find.text('Search Again'), findsOneWidget);

        await tester.tap(find.text('Search Again'));
        expect(actionTriggered, isTrue);
      },
    );

    testWidgets('SahyanLoadingState renders spinner and message', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanLoadingState(message: 'Calculating route match...'),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Calculating route match...'), findsOneWidget);
    });

    testWidgets('SahyanErrorState renders error info and triggers retry', (
      tester,
    ) async {
      bool retryTriggered = false;
      await tester.pumpWidget(
        wrapWithTheme(
          SahyanErrorState(
            title: 'Connection Lost',
            message: 'Unable to reach the server. Please check your network.',
            onRetry: () => retryTriggered = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(
        find.text('Unable to reach the server. Please check your network.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryTriggered, isTrue);
    });
  });

  group('SahyanAvatar & Header Components', () {
    testWidgets('SahyanAvatar renders initials and verified badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Row(
            children: [
              SahyanAvatar(name: 'Aditya Sharma', isVerified: true),
              SahyanAvatar(name: 'Rahul', isVerified: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AS'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('SahyanSectionHeader renders title and action callback', (
      tester,
    ) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          SahyanSectionHeader(
            title: 'Featured Routes',
            actionLabel: 'See All',
            onActionTap: () => actionTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Featured Routes'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      await tester.tap(find.text('See All'));
      expect(actionTapped, isTrue);
    });
  });

  group('Responsive Layout Testing Across Viewports & 1.5x Font Scale', () {
    final viewports = [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
      const Size(600, 1024),
    ];

    for (final size in viewports) {
      testWidgets(
        'Design system components render without overflow at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            wrapWithTheme(
              SingleChildScrollView(
                padding: AppSpacing.paddingScreen,
                child: Column(
                  children: [
                    const SahyanSectionHeader(
                      title: 'Upcoming Ride',
                      subtitle: 'Mumbai to Pune Express',
                      actionLabel: 'Details',
                    ),
                    AppSpacing.vGap16,
                    SahyanCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SahyanAvatar(
                                name: 'Vikram Singh',
                                isVerified: true,
                              ),
                              AppSpacing.hGap12,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vikram Singh',
                                      style: AppTypography.cardTitle,
                                    ),
                                    Text(
                                      'Honda City - MH 12 AB 1234',
                                      style: AppTypography.secondary,
                                    ),
                                  ],
                                ),
                              ),
                              SahyanStatusBadge.fromRideStatus(
                                RideStatus.active,
                              ),
                            ],
                          ),
                          AppSpacing.vGap16,
                          const SahyanTextField(hint: 'Pickup location notes'),
                          AppSpacing.vGap16,
                          SahyanButton(text: 'Join Carpool', onPressed: () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              size: size,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Design system components render without overflow under 1.5x text scaling',
      (tester) async {
        await tester.pumpWidget(
          wrapWithTheme(
            SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Column(
                children: [
                  const SahyanSectionHeader(
                    title: 'Upcoming Ride',
                    subtitle: 'Mumbai to Pune Express',
                    actionLabel: 'Details',
                  ),
                  AppSpacing.vGap16,
                  SahyanCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SahyanAvatar(
                              name: 'Vikram Singh',
                              isVerified: true,
                            ),
                            AppSpacing.hGap12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vikram Singh',
                                    style: AppTypography.cardTitle,
                                  ),
                                  Text(
                                    'Honda City',
                                    style: AppTypography.secondary,
                                  ),
                                ],
                              ),
                            ),
                            SahyanStatusBadge.fromRideStatus(RideStatus.active),
                          ],
                        ),
                        AppSpacing.vGap16,
                        SahyanButton(text: 'Join Carpool', onPressed: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            size: const Size(360, 640),
            textScale: 1.5,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
