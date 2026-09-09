import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers/user_mode_provider.dart';
import '../../app/theme/app_colors.dart';
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final viewPaddingBottom = mediaQuery.viewPadding.bottom;
    final paddingBottom = mediaQuery.padding.bottom;
    final safeBottom = math.max(viewPaddingBottom, paddingBottom);
    final bottomMargin = safeBottom > 0 ? safeBottom + 6.0 : 12.0;

    // Responsive horizontal margins: centered 480dp width on tablets, tight margin on small screens
    const maxBarWidth = 480.0;
    final double horizontalMargin;
    if (screenWidth > maxBarWidth + 32) {
      horizontalMargin = (screenWidth - maxBarWidth) / 2;
    } else if (screenWidth <= 360) {
      horizontalMargin = 8.0;
    } else {
      horizontalMargin = 16.0;
    }

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: bottomMargin,
      ),
      child: SizedBox(
        height: 72.0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Floating white rounded surface
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 58.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Home',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                    ),
                    _buildNavItem(
                      index: 1,
                      label: 'Rides',
                      icon: Icons.directions_car_outlined,
                      activeIcon: Icons.directions_car_rounded,
                    ),
                    // Proportional placeholder for center elevated button
                    const Expanded(child: SizedBox()),
                    _buildNavItem(
                      index: 3,
                      label: 'Bookings',
                      icon: Icons.confirmation_number_outlined,
                      activeIcon: Icons.confirmation_number_rounded,
                    ),
                    _buildNavItem(
                      index: 4,
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                    ),
                  ],
                ),
              ),
            ),
            // Center elevated Offer Ride action
            Positioned(top: 0, bottom: 0, child: _buildCenterAction()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.primaryForest : AppColors.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isActive ? activeIcon : icon, size: 22, color: color),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: color,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAction() {
    final isActive = currentIndex == 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(2),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryForest,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryForest.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Offer Ride',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.primaryForest,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
