import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/verification_badge.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        title: Text('Account Profile', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: authState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryForest,
                ),
              )
            : user == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.softForest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_circle_outlined,
                          size: 40,
                          color: AppColors.primaryForest,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to Load Profile',
                        style: AppTypography.screenTitle.copyWith(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access your profile, manage registered vehicles, track emergency contacts, and offer rides.',
                        style: AppTypography.secondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Sign In / Register',
                        onPressed: () => context.push('/auth-entry'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).checkAuthStatus();
                        },
                        child: Text(
                          'Retry Loading',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Header Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      color: AppColors.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppColors.softForest,
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: AppTypography.screenTitle.copyWith(
                                      fontSize: 32,
                                      color: AppColors.primaryForest,
                                    ),
                                  ),
                                ),
                                if (user.isVerified)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryForest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  user.name,
                                  style: AppTypography.screenTitle.copyWith(
                                    fontSize: 20,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (user.isVerified)
                                  const VerificationBadge(
                                    isVerified: true,
                                    label: 'Phone Verified',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  user.phone,
                                  style: AppTypography.secondary,
                                ),
                                if (user.email.isNotEmpty) ...[
                                  Text('•', style: AppTypography.secondary),
                                  Text(
                                    user.email,
                                    style: AppTypography.secondary,
                                  ),
                                ],
                              ],
                            ),
                            if (user.bio.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                user.bio,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  RatingDisplay(
                                    rating: user.rating,
                                    reviewCount: user.totalRides,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: AppColors.primaryForest,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.city.isNotEmpty
                                            ? user.city
                                            : 'Not specified',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Trust & Verification Foundation Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      color: AppColors.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: AppColors.primaryForest,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Trust & Safety Status',
                                    style: AppTypography.cardTitle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildVerificationItem(
                              icon: Icons.phone_android_rounded,
                              title: 'Phone Number',
                              subtitle: user.phone,
                              isCompleted: user.isVerified,
                              statusText: user.isVerified
                                  ? 'Verified'
                                  : 'Pending',
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            _buildVerificationItem(
                              icon: Icons.email_outlined,
                              title: 'Email Address',
                              subtitle: user.email.isNotEmpty
                                  ? user.email
                                  : 'Pending registration',
                              isCompleted: user.email.isNotEmpty,
                              statusText: user.email.isNotEmpty
                                  ? 'Registered'
                                  : 'Pending',
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            _buildVerificationItem(
                              icon: Icons.directions_car_rounded,
                              title: 'Driver Eligibility',
                              subtitle: user.canDrive
                                  ? 'Eligible to offer shared rides'
                                  : 'Register a vehicle to offer rides',
                              isCompleted: user.canDrive,
                              statusText: user.canDrive
                                  ? 'Eligible Driver'
                                  : 'Rider Only',
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            _buildVerificationItem(
                              icon: Icons.badge_outlined,
                              title: 'Identity Verification',
                              subtitle: 'Official ID verification is upcoming',
                              isCompleted: false,
                              statusText: 'Upcoming',
                              isInfoOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Management List
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      color: AppColors.cardBackground,
                      child: Column(
                        children: [
                          _buildNavTile(
                            icon: Icons.directions_car_outlined,
                            title: 'My Vehicles & Fleet',
                            subtitle:
                                'Manage registered vehicles and seat capacity',
                            onTap: () {
                              context.push('/vehicles');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.alt_route_rounded,
                            title: 'My Offered Rides & Requests',
                            subtitle:
                                'Manage passenger booking requests and seats',
                            onTap: () {
                              context.push('/driver/rides');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Driver Earnings & Payout',
                            subtitle: 'Settlement ledger and payout account',
                            onTap: () {
                              context.push('/driver/payout');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.history_rounded,
                            title: 'Ride History',
                            subtitle:
                                'Past completed and cancelled carpool journeys',
                            onTap: () {
                              context.push('/ride-history');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.star_outline_rounded,
                            title: 'Reviews & Ratings',
                            subtitle:
                                'Community feedback and driver trust score',
                            onTap: () {
                              context.push('/reviews');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.location_on_outlined,
                            title: 'Saved Places',
                            subtitle:
                                'Home, Work, and frequent pickup locations',
                            onTap: () {
                              context.push('/saved-places');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.payment_rounded,
                            title: 'Payment Methods',
                            subtitle:
                                'Saved UPI handles and carpool sharing preferences',
                            onTap: () {
                              context.push('/payment-methods');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.badge_outlined,
                            title: 'Personal Details & Legal Identity',
                            subtitle: 'Legal name, verified phone badge, and bio',
                            onTap: () {
                              context.push('/personal-details');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile & Preferences',
                            subtitle: 'City, Bio, and Travel Preferences',
                            onTap: () {
                              context.push('/edit-profile');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.shield_outlined,
                            title: 'Safety Center',
                            subtitle:
                                'Trust score, verified documents, and SOS hub',
                            onTap: () {
                              context.push('/safety-center');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle:
                                'Notifications, Privacy, Security and Legal',
                            onTap: () {
                              context.push('/settings');
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle:
                                'Knowledge hub, FAQ, and priority member desk',
                            onTap: () {
                              context.push('/help-support');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.mutedRust),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.mutedRust,
                        size: 20,
                      ),
                      label: Text(
                        'Log Out',
                        style: AppTypography.button.copyWith(
                          color: AppColors.mutedRust,
                        ),
                      ),
                      onPressed: () => _confirmLogout(context, ref),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Sahyān Mobility v1.0.0',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required String statusText,
    bool isInfoOnly = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.softForest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryForest, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.secondary.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isInfoOnly
                ? AppColors.warmBackground
                : isCompleted
                ? AppColors.softForest
                : AppColors.warmBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isInfoOnly
                  ? AppColors.border
                  : isCompleted
                  ? AppColors.primaryForest.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.primaryForest,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                statusText,
                style: AppTypography.caption.copyWith(
                  color: isCompleted
                      ? AppColors.primaryForest
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.softForest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryForest, size: 22),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.secondary.copyWith(fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: AppTypography.cardTitle),
        content: Text(
          'Are you sure you want to log out of your Sahyān account?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedRust,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(
              'Log Out',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
