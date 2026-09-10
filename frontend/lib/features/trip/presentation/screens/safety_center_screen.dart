import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  void _handleSos(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: AppColors.mutedRust),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Emergency SOS',
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.mutedRust,
              ),
            ),
          ],
        ),
        content: Text(
          'This will trigger an immediate emergency alert. Your live corridor coordinates will be dispatched to local highway police command and your registered emergency contacts.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedRust,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'SOS Alert Dispatched to Emergency Services & Contacts.',
                  ),
                  backgroundColor: AppColors.mutedRust,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Dispatch SOS Now'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Text(
          'Report a Safety Concern',
          style: AppTypography.sectionHeader,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please describe the incident, vehicle behavior, or issue encountered along your route.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reportController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter incident details here...',
                hintStyle: AppTypography.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your safety report has been filed with the trust & safety desk.',
                  ),
                  backgroundColor: AppColors.primaryForest,
                ),
              );
            },
            child: const Text('Submit Report', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Safety Center',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trust & Verification Bento Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softForest,
                              borderRadius: BorderRadius.circular(AppRadii.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppColors.primaryForest,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Level 3 Trust Score',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryForest,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primaryForest,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Your account is protected',
                      style: AppTypography.screenTitle.copyWith(fontSize: 20),
                    ),
                    Text(
                      '100% Verified Sahyan Community Member',
                      style: AppTypography.secondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildVerifiedItem(
                      icon: Icons.badge_outlined,
                      title: 'Government ID Verification',
                      subtitle: 'DigiLocker Authenticated',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildVerifiedItem(
                      icon: Icons.contact_phone_outlined,
                      title: 'Phone & Work Email',
                      subtitle: '+91 Verified & Tokenized',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildVerifiedItem(
                      icon: Icons.directions_car_outlined,
                      title: 'Vehicle Documentation',
                      subtitle: 'RC & Intercity Insurance Valid',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Emergency Assistance Section
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'EMERGENCY ASSISTANCE',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.primaryForest,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Immediate dedicated safety command active throughout your corridor journey.',
                      style: AppTypography.secondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildAssistanceFeature(
                      '24x7 Sahyan Safety Response Command',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildAssistanceFeature(
                      'Live GPS Coordinate Broadcast to Highway Authorities',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SahyanButton(
                      text: 'Emergency SOS',
                      variant: SahyanButtonVariant.destructive,
                      icon: Icons.emergency_rounded,
                      isFullWidth: true,
                      onPressed: () => _handleSos(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Active Trip Safety Tools
              Text(
                'Active Trip Safety Tools',
                style: AppTypography.sectionHeader.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Tool 1: Emergency Contacts
              SahyanCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.softForest,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.contact_phone_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Emergency Contacts',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Family and guardians alerted during incidents',
                    style: AppTypography.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => context.push('/emergency-contacts'),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Tool 2: Trip Safety Link
              SahyanCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.softForest,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.share_location_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Live Corridor Location Sharing',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Share encrypted web link with family',
                    style: AppTypography.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => context.push('/trip-safety'),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Tool 3: Report Issue
              SahyanCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.warmBackground,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: AppColors.mutedRust,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Report a Safety Concern',
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Confidential review by Sahyan trust & safety team',
                    style: AppTypography.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showReportDialog(context),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Zero-Tolerance Community Standards Note
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero-Tolerance Community Standards',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sahyan enforces strict zero-tolerance policies regarding reckless driving, vehicle overloading, passenger harassment, and unauthorized route deviations.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBackground,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryForest, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primaryForest,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceFeature(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryForest,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.deepForest,
            ),
          ),
        ),
      ],
    );
  }
}
