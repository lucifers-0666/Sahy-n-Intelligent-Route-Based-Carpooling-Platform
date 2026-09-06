import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/user_mode_provider.dart';
import '../../app/theme/app_colors.dart';
import 'auth_gate_dialog.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(userModeProvider).isGuest;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          if (isGuest && index != 0) {
            String title = 'Sign In Required';
            String msg =
                'Please create an account or sign in to access this feature.';
            String route = '/home';

            if (index == 1) {
              title = 'Sign In to Offer Rides';
              msg =
                  'Sharing your vehicle seats and publishing routes requires driver identity verification.';
              route = '/offer-ride';
            } else if (index == 2) {
              title = 'Sign In to View Bookings';
              msg =
                  'Sign in or register to manage your confirmed and pending shared ride bookings.';
              route = '/my-bookings';
            } else if (index == 3) {
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

          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedItemColor: AppColors.primaryForest,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primaryForest,
            ),
            label: 'Find Ride',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(
              Icons.add_circle_rounded,
              color: AppColors.primaryForest,
            ),
            label: 'Offer Ride',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(
              Icons.confirmation_number_rounded,
              color: AppColors.primaryForest,
            ),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(
              Icons.person_rounded,
              color: AppColors.primaryForest,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
