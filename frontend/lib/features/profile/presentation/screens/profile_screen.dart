import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
export 'profile_safety_screen.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/verification_badge.dart';
import 'package:sahyan/core/widgets/rating_display.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/shared/widgets/feedback/sahyan_logout_bottom_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userModeState = ref.watch(userModeProvider);

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
                                  backgroundImage: (user.profilePhoto != null &&
                                          user.profilePhoto!.isNotEmpty)
                                      ? NetworkImage(user.profilePhoto!)
                                      : null,
                                  child: (user.profilePhoto != null &&
                                          user.profilePhoto!.isNotEmpty)
                                      ? null
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 38,
                                          color: AppColors.primaryForest,
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

                    // Operational Mode Switcher (For Approved Drivers)
                    if (user.isDriverEligible)
                      _buildModeSwitcherCard(context, ref, userModeState),

                    // Driver Verification & Onboarding Card (Adaptive)
                    _buildDriverStatusBanner(context, user),

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
                              subtitle: user.isDriverEligible
                                  ? 'Eligible to offer shared rides'
                                  : user.isDriverSubmitted
                                  ? 'Application pending review'
                                  : user.isDriverRejected
                                  ? 'Action required on documents'
                                  : 'Register driving licence to offer rides',
                              isCompleted: user.isDriverEligible,
                              statusText: user.isDriverEligible
                                  ? 'Eligible Driver'
                                  : user.isDriverSubmitted
                                  ? 'In Review'
                                  : user.isDriverRejected
                                  ? 'Action Needed'
                                  : 'Rider Only',
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            _buildVerificationItem(
                              icon: Icons.badge_outlined,
                              title: 'Identity Verification',
                              subtitle: user.isDriverEligible
                                  ? 'Government driving licence verified'
                                  : 'Official ID verification via driver onboarding',
                              isCompleted: user.isDriverEligible,
                              statusText: user.isDriverEligible
                                  ? 'Verified'
                                  : 'Pending',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Driver Management Section (ONLY shown if Approved Driver)
                    if (user.isDriverEligible) ...[
                      _buildSectionTitle('Driver Fleet & Publishing'),
                      const SizedBox(height: 8),
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
                              onTap: () => context.push('/vehicles'),
                            ),
                            const Divider(color: AppColors.border, height: 1),
                            _buildNavTile(
                              icon: Icons.alt_route_rounded,
                              title: 'My Offered Rides & Requests',
                              subtitle:
                                  'Manage passenger booking requests and seats',
                              onTap: () => context.push('/driver/rides'),
                            ),
                            const Divider(color: AppColors.border, height: 1),
                            _buildNavTile(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Driver Earnings & Payout',
                              subtitle: 'Settlement ledger and payout account',
                              onTap: () => context.push('/driver/payout'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Passenger Journeys & Activity Section
                    _buildSectionTitle('Travel & Activity'),
                    const SizedBox(height: 8),
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
                            icon: Icons.confirmation_number_outlined,
                            title: 'My Carpool Bookings',
                            subtitle:
                                'View active tickets and confirmed boarding passes',
                            onTap: () => context.push('/passenger/bookings'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.history_rounded,
                            title: 'Ride History',
                            subtitle:
                                'Past completed and cancelled carpool journeys',
                            onTap: () => context.push('/ride-history'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.star_outline_rounded,
                            title: 'Reviews & Ratings',
                            subtitle:
                                'Community feedback and driver trust score',
                            onTap: () => context.push('/reviews'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.location_on_outlined,
                            title: 'Saved Places',
                            subtitle:
                                'Home, Work, and frequent pickup locations',
                            onTap: () => context.push('/saved-places'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.payment_rounded,
                            title: 'Payment Methods',
                            subtitle:
                                'Saved UPI handles and carpool sharing preferences',
                            onTap: () => context.push('/payment-methods'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Safety & Personal Information Section
                    _buildSectionTitle('Safety & Personal Details'),
                    const SizedBox(height: 8),
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
                            icon: Icons.badge_outlined,
                            title: 'Personal Details & Legal Identity',
                            subtitle:
                                'Legal name, verified phone badge, and bio',
                            onTap: () => context.push('/personal-details'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile & Preferences',
                            subtitle: 'City, Bio, and Travel Preferences',
                            onTap: () => context.push('/edit-profile'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.shield_outlined,
                            title: 'Safety Center & SOS Contacts',
                            subtitle:
                                'Trust score, verified documents, and SOS hub',
                            onTap: () => context.push('/safety-center'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.contact_phone_outlined,
                            title: 'Emergency Contacts',
                            subtitle:
                                'Trusted contacts notified during SOS alerts',
                            onTap: () => context.push('/emergency-contacts'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Privacy & System Permissions',
                            subtitle: 'Location, DPDP rights, and diagnostics',
                            onTap: () => context.push('/privacy-permissions'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Preferences & App Security Section
                    _buildSectionTitle('Preferences & System'),
                    const SizedBox(height: 8),
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
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle:
                                'Notifications, Privacy, Security and Legal',
                            onTap: () => context.push('/settings'),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          _buildNavTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle:
                                'Safety guidelines and assistance information',
                            onTap: () => _showHelpDialog(context),
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

                    // DPDP Account Deletion & Right to Erasure
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        'Delete Account & Erase Personal Data (DPDP Act)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () => _showDeleteAccountDialog(context, ref),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModeSwitcherCard(
    BuildContext context,
    WidgetRef ref,
    UserModeState modeState,
  ) {
    final isDriver = modeState.isDriverMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDriver ? AppColors.softForest : AppColors.warmBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDriver
                      ? Icons.directions_car_rounded
                      : Icons.person_outline_rounded,
                  color:
                      isDriver
                          ? AppColors.primaryForest
                          : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDriver ? 'Active Driver Mode' : 'Passenger Mode',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isDriver
                        ? 'Publishing and managing rides'
                        : 'Searching and booking seats',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isDriver,
            activeThumbColor: AppColors.primaryForest,
            onChanged: (val) {
              ref
                  .read(userModeProvider.notifier)
                  .setOperationalMode(
                    val ? OperationalMode.driver : OperationalMode.rider,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatusBanner(BuildContext context, UserModel user) {
    if (user.isDriverEligible) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.softForest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryForest.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primaryForest,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approved Driver Account',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.licenseNumber.isNotEmpty
                        ? 'Licence: ${user.licenseNumber}'
                        : 'Authorised to publish shared routes',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryForest,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/driver-onboarding'),
              child: const Text('Details'),
            ),
          ],
        ),
      );
    }

    if (user.isDriverSubmitted) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFC2410C),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Application In Review',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Documents submitted (24-48 hrs)',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/driver-onboarding'),
              child: const Text('Status'),
            ),
          ],
        ),
      );
    }

    if (user.isDriverRejected) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action Required on Driver Profile',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.rejectionReason.isNotEmpty
                        ? user.rejectionReason
                        : 'Document criteria not met',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFDC2626),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/driver-onboarding'),
              child: const Text('Fix'),
            ),
          ],
        ),
      );
    }

    // not_started or in_progress (Pure Passenger)
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.softForest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: AppColors.primaryForest,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earn by Sharing Empty Seats',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Become a verified Sahyān driver',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => context.push('/driver-onboarding'),
            child: const Text('Apply'),
          ),
        ],
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
            color: isCompleted
                ? AppColors.softForest
                : isInfoOnly
                ? AppColors.warmBackground
                : AppColors.warmBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isCompleted
                ? AppColors.primaryForest
                : isInfoOnly
                ? AppColors.textSecondary
                : AppColors.textSecondary,
          ),
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Help & Support', style: AppTypography.cardTitle),
        content: Text(
          'For assistance during your journey, use the Emergency Contacts section to notify your trusted safety circle. Additional customer support channels and route assistance guides will be available in upcoming releases.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: AppTypography.button.copyWith(
                color: AppColors.primaryForest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    SahyanLogoutBottomSheet.show(context);
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account & Erase Data', style: AppTypography.cardTitle),
        content: Text(
          'In compliance with the Digital Personal Data Protection (DPDP) Act, this action permanently anonymizes your personal information, contact records, vehicle registrations, and account credentials. This action cannot be reversed.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedRust,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(profileProvider.notifier)
                  .anonymizeAccount();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Account personal data successfully erased and anonymized.',
                      ),
                      backgroundColor: AppColors.primaryForest,
                    ),
                  );
                  context.go('/auth-entry');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete account. Try again later.'),
                      backgroundColor: AppColors.mutedRust,
                    ),
                  );
                }
              }
            },
            child: const Text('Erase & Delete'),
          ),
        ],
      ),
    );
  }
}
