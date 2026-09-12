import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';

class ProfileSafetyScreen extends ConsumerWidget {
  const ProfileSafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: AppBar(
        backgroundColor: SahyanColors.surface,
        elevation: 0,
        title: const Text(
          'Fleet & Safety Profile',
          style: TextStyle(
            color: SahyanColors.textMain,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: SahyanColors.textMuted),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/edit-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: SahyanColors.textMuted),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: SahyanColors.border, height: 0.8),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Hero Card
            _buildHeroCard(context),
            const SizedBox(height: 14),

            // Impact Metrics Bar
            _buildImpactMetricsBar(),
            const SizedBox(height: 14),

            // Safety Matrix (4-card Grid)
            _buildSafetyMatrix(context),
            const SizedBox(height: 14),

            // Fleet & Preferences Section
            _buildFleetAndPreferences(context),
            const SizedBox(height: 20),

            // Logout CTA
            _buildLogoutButton(context, ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return BentoContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SahyanColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: SahyanColors.primaryMint.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text(
                'AP',
                style: TextStyle(
                  color: SahyanColors.primaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arjun Patel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Sahyān Pioneer · Executive EV Cohort',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SahyanColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: SahyanColors.chipBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: SahyanColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: SahyanColors.goldStar,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '4.9 (14 verified rides)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: SahyanColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetricsBar() {
    return BentoContainer(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricItem(
            value: '142 kg',
            label: 'CO₂ offset',
            highlightColor: SahyanColors.primaryMint,
          ),
          Container(
            width: 0.8,
            height: 36,
            color: SahyanColors.border,
          ),
          _buildMetricItem(
            value: '28',
            label: 'Journeys',
            highlightColor: SahyanColors.primaryDark,
          ),
          Container(
            width: 0.8,
            height: 36,
            color: SahyanColors.border,
          ),
          _buildMetricItem(
            value: '₹9,840',
            label: 'Shared split',
            highlightColor: SahyanColors.textMain,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String value,
    required String label,
    required Color highlightColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: highlightColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SahyanColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyMatrix(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Safety & Highway Clearance Matrix',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SahyanColors.textMuted,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildSafetyCard(
              title: 'Phone Number',
              value: '+91 98765 43210',
              status: 'Verified',
              isSuccess: true,
              icon: Icons.phone_android_rounded,
            ),
            _buildSafetyCard(
              title: 'DL Highway Tier',
              value: 'GJ-01-2018-0941',
              status: 'Intercity Cleared',
              isSuccess: true,
              icon: Icons.card_membership_rounded,
            ),
            _buildSafetyCard(
              title: 'DigiLocker ID',
              value: 'Aadhaar Vault',
              status: 'UIDAI Crypt-Linked',
              isSuccess: true,
              icon: Icons.verified_user_rounded,
            ),
            _buildSafetyCard(
              title: 'Emergency Ring',
              value: 'Mom, Priya P.',
              status: '2 Live',
              isSuccess: true,
              icon: Icons.shield_moon_rounded,
              onTap: () => context.push('/profile/emergency-contacts'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyCard({
    required String title,
    required String value,
    required String status,
    required bool isSuccess,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SahyanColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SahyanColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: SahyanColors.textMain.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: SahyanColors.primaryDark),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? SahyanColors.primaryLight
                        : SahyanColors.chipBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSuccess
                          ? SahyanColors.primaryDark
                          : SahyanColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SahyanColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetAndPreferences(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Fleet & Travel Preferences',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SahyanColors.textMuted,
            ),
          ),
        ),

        // Active Vehicle Card
        BentoContainer(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SahyanColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SahyanColors.border, width: 0.8),
                ),
                child: const Center(
                  child: VehicleIcon(
                    type: VehicleType.sedan,
                    width: 36,
                    height: 22,
                    color: SahyanColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Honda City ZX EV',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '3 Passenger Seats Authorized · GJ 01 AB 1234',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.primaryMint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: SahyanColors.textDisabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preferences Menu Bento
        BentoContainer(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.room_service_outlined,
                title: 'Ride Hospitality Defaults',
                subtitle: 'AC, Quiet Cabin, Luggage capacity',
                onTap: () {},
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payment & Fastag Clearing',
                subtitle: 'Automated highway toll splitting',
                onTap: () => context.push('/payment-methods'),
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Passkey & App Lock',
                subtitle: 'Face ID & Fingerprint clearance',
                onTap: () {},
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                icon: Icons.cell_tower_rounded,
                title: 'Live Route Telemetry Broadcasting',
                subtitle: 'Real-time GPS mesh sharing with corridor',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: SahyanColors.chipBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: SahyanColors.primaryDark, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: SahyanColors.textMain,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: SahyanColors.textMuted,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: SahyanColors.textDisabled,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      height: 1,
      thickness: 0.8,
      color: SahyanColors.border,
      indent: 56,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text(
              'Are you sure you want to log out of Sahyān Mobility?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SahyanColors.urgentCoral,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Log Out'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        }
      },
      icon: const Icon(
        Icons.logout_rounded,
        size: 18,
        color: SahyanColors.urgentCoral,
      ),
      label: const Text(
        'Log Out of Sahyān Mobility',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: SahyanColors.urgentCoral,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: SahyanColors.urgentCoral, width: 1.0),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
