import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/user_mode_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/sahyan_bottom_navigation.dart';
import '../../features/auth/presentation/auth_provider.dart';
import 'auth_gate_dialog.dart';
import 'offline_banner.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _handleNavigation(BuildContext context, WidgetRef ref, int index) {
    final authState = ref.read(authProvider);
    final isGuest =
        ref.read(userModeProvider).isGuest && !authState.isAuthenticated;

    // Gated actions for unauthenticated guests
    if (isGuest && index != 0 && index != 1) {
      String title = 'Sign In Required';
      String msg =
          'Please create an account or sign in to access this feature.';
      String route = '/home';

      if (index == 2) {
        title = 'Sign In to Offer Rides';
        msg =
            'Sharing your vehicle seats and publishing routes requires driver identity verification.';
        route = '/offer-ride';
      } else if (index == 3) {
        title = 'Sign In to View Bookings';
        msg =
            'Sign in or register to manage your confirmed and pending shared ride bookings.';
        route = '/my-bookings';
      } else if (index == 4) {
        title = 'Sign In to View Profile';
        msg =
            'Manage your account settings, emergency contacts, and vehicle registration.';
        route = '/profile';
      }

      AuthGateDialog.show(
        context,
        title: title,
        message: msg,
        intendedRoute: route,
      );
      return;
    }

    if (index == 2) {
      final user = authState.user;
      final modeState = ref.read(userModeProvider);
      final isDriver = user?.isDriverEligible ?? false;

      // Show Mobility Action Sheet if in passenger mode or not yet driver-verified
      if (!isDriver || modeState.isRiderMode) {
        _showMobilityActionSheet(context, ref);
        return;
      }
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showMobilityActionSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final modeState = ref.read(userModeProvider);
    final isDriverEligible = user?.isDriverEligible ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.deepEmerald,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Journey Mode',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryForest,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Take a ride as commuter or offer seats as verified host',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Take a Ride (Passenger Mode)
              InkWell(
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  ref
                      .read(userModeProvider.notifier)
                      .setOperationalMode(OperationalMode.rider);
                  navigationShell.goBranch(0);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: modeState.isRiderMode
                        ? AppColors.primaryLight.withValues(alpha: 0.5)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: modeState.isRiderMode
                          ? AppColors.softMint
                          : AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.softMint.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_search_rounded,
                          color: AppColors.deepEmerald,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Take a Ride (Passenger)',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                if (modeState.isRiderMode) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Search Gujarat corridors, join verified drivers, and travel affordably.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Offer a Ride (Driver / Host Mode)
              InkWell(
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  if (isDriverEligible) {
                    ref
                        .read(userModeProvider.notifier)
                        .setOperationalMode(OperationalMode.driver);
                    navigationShell.goBranch(2);
                  } else {
                    context.push('/driver-onboarding');
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: modeState.isDriverMode
                        ? AppColors.primaryLight.withValues(alpha: 0.5)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: modeState.isDriverMode
                          ? AppColors.softMint
                          : AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: AppColors.primaryForest,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Offer a Ride (Driver)',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDriverEligible
                                        ? AppColors.softMint.withValues(
                                            alpha: 0.25,
                                          )
                                        : Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isDriverEligible
                                        ? 'VERIFIED'
                                        : 'KYC NEEDED',
                                    style: TextStyle(
                                      color: isDriverEligible
                                          ? AppColors.deepEmerald
                                          : Colors.amber.shade900,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDriverEligible
                                  ? 'Share vehicle seats on highway routes and recover fuel contribution.'
                                  : 'Complete quick driver onboarding and vehicle verification to start publishing.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;
    // Hide bottom navigation bar in Offer Ride wizard or when keyboard is open
    // to prevent covering form inputs or the Continue CTA button.
    final isOfferRide = navigationShell.currentIndex == 2;
    final showBottomNav = !isKeyboardOpen && !isOfferRide;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.warmBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.warmBackground,
        body: Column(
          children: [
            const SahyanOfflineBanner(isOffline: false),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: showBottomNav
            ? FloatingBottomNavBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => _handleNavigation(context, ref, index),
              )
            : null,
      ),
    );
  }
}

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SahyanBottomNavigation(currentIndex: currentIndex, onTap: onTap);
  }
}
