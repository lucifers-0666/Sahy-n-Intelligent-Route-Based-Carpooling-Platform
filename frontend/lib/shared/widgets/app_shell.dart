import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/user_mode_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/sahyan_bottom_navigation.dart';
import '../../features/auth/presentation/auth_provider.dart';
import 'auth_gate_dialog.dart';

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

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        body: navigationShell,
        bottomNavigationBar: FloatingBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _handleNavigation(context, ref, index),
        ),
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
