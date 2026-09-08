import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_elevation.dart';
import '../../app/theme/app_radii.dart';

/// Standardized Sahyān Floating Bottom Navigation bar.
/// Houses the 5 core destinations with an elevated center Offer Ride action.
class SahyanBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SahyanBottomNavigation({
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

    // Responsive horizontal margins: centered on tablet, compact on small mobile
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
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  boxShadow: AppElevation.floating,
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
          borderRadius: BorderRadius.circular(AppRadii.lg),
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
                            ? FontWeight.w700
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
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w700,
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
