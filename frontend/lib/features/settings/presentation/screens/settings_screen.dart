import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/localization/sahyan_language_selector.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/design_system.dart';
import '../../../../shared/widgets/feedback/sahyan_legal_sheet.dart';
import '../../../../shared/widgets/feedback/sahyan_logout_bottom_sheet.dart';
import '../../../auth/presentation/auth_provider.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _rideAlerts = true;
  bool _marketingEmails = false;
  bool _locationSharing = true;
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAppLock();
  }

  Future<void> _loadAppLock() async {
    final biometric = ref.read(biometricServiceProvider);
    final enabled = await biometric.hasBiometricOptIn();
    if (mounted) setState(() => _appLockEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(title: l10n.settingsTitle, showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader(l10n.accountSectionHeader),
              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        user?.name ?? l10n.carpoolMember,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        user?.email ?? l10n.memberAccount,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/personal-details'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.editProfileAndPrefs,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.editProfileSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/edit-profile'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.savedPlaces,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.savedPlacesSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/saved-places'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.contact_phone_outlined,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.emergencyContacts,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.emergencyContactsSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/emergency-contacts'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        user?.isDriverEligible == true
                            ? l10n.driverStatusAndVehicles
                            : l10n.driverOnboardingTitle,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        user?.isDriverEligible == true
                            ? l10n.driverStatusSubtitle
                            : l10n.driverOnboardingSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push(
                        user?.isDriverEligible == true
                            ? '/vehicles'
                            : '/driver-onboarding',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Language & Localization Section
              _buildSectionHeader(l10n.languageAndRegion),
              SahyanCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(
                    Icons.language_rounded,
                    color: AppColors.primaryForest,
                  ),
                  title: Text(
                    l10n.preferredLanguage,
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.languageSubtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const SahyanLanguageSelector(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Notifications Section
              _buildSectionHeader(l10n.notifications),
              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppColors.primaryForest,
                      title: Text(
                        l10n.pushNotifications,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.pushNotificationsSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _pushNotifications,
                      onChanged: (val) {
                        setState(() => _pushNotifications = val);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SwitchListTile(
                      activeThumbColor: AppColors.primaryForest,
                      title: Text(
                        l10n.tripStatusAlerts,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.tripStatusAlertsSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _rideAlerts,
                      onChanged: (val) {
                        setState(() => _rideAlerts = val);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SwitchListTile(
                      activeThumbColor: AppColors.primaryForest,
                      title: Text(
                        l10n.carpoolCommunityUpdates,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.carpoolCommunitySubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _marketingEmails,
                      onChanged: (val) {
                        setState(() => _marketingEmails = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Privacy & Permissions
              _buildSectionHeader(l10n.privacyAndSecurity),
              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppColors.primaryForest,
                      title: Text(
                        l10n.routeLocationSharing,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.routeLocationSharingSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _locationSharing,
                      onChanged: (val) {
                        setState(() => _locationSharing = val);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SwitchListTile(
                      activeThumbColor: AppColors.primaryForest,
                      title: Text(
                        l10n.appLockFingerprint,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.appLockSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _appLockEnabled,
                      onChanged: (val) async {
                        setState(() => _appLockEnabled = val);
                        final biometric = ref.read(biometricServiceProvider);
                        await biometric.setBiometricOptIn(val);
                        await biometric.setAppLockMode(val ? 'on_open' : 'off');
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.changePassword,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/forgot-password'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.security_rounded,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.privacyPermissions,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.privacyPermissionsSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/privacy-permissions'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Legal & About
              _buildSectionHeader(l10n.aboutAndLegal),
              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        l10n.termsOfService,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => SahyanLegalSheet.show(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      title: Text(
                        l10n.privacyPolicy,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => SahyanLegalSheet.show(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      title: Text(
                        l10n.applicationVersion,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      trailing: Text(
                        '1.2.0 (Build 42)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.safetyCenterProtocols,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.safetyCenterSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/safety-center'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.helpAndSupport,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.helpAndSupportSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/help-support'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(
                        Icons.developer_mode_outlined,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        l10n.systemStatesDiagnostics,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.systemStatesSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/system-states'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Logout Action
              SahyanButton(
                text: l10n.signOut,
                icon: Icons.logout_rounded,
                variant: SahyanButtonVariant.destructive,
                isFullWidth: true,
                onPressed: () => _confirmSignOut(context),
              ),
              const SizedBox(height: AppSpacing.sm),

              // DPDP Account Deletion & Right to Erasure
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    l10n.deleteAccountDpdp,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: () => _showDeleteAccountDialog(context),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Brand Mark Signature
              const Center(
                child: SahyanLogo(
                  variant: SahyanLogoVariant.stacked,
                  size: 44,
                  showTagline: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    SahyanLogoutBottomSheet.show(context);
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAccountDpdp, style: AppTypography.cardTitle),
        content: Text(
          'In compliance with the Digital Personal Data Protection (DPDP) Act, this action permanently anonymizes your personal information, contact records, vehicle registrations, and account credentials. This action cannot be reversed.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
