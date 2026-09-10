import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';

class TripSafetyScreen extends StatelessWidget {
  const TripSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Trip Safety Center',
        subtitle: 'Community safety and emergency protocols',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero banner
              SahyanCard(
                backgroundColor: AppColors.deepForest,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: AppColors.primaryForest,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Safety Standards',
                                style: AppTypography.cardTitle.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'All drivers and vehicles undergo verification.',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white70,
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

              const SizedBox(height: AppSpacing.lg),

              Text(
                'SAFETY ACTIONS',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Emergency Contacts Tile
              _buildActionTile(
                context,
                icon: Icons.contact_phone_outlined,
                title: 'Trusted Emergency Contacts',
                subtitle:
                    'Manage phone numbers notified in case of journey alerts',
                onTap: () => context.push('/emergency-contacts'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Share Trip Details Tile
              _buildActionTile(
                context,
                icon: Icons.share_outlined,
                title: 'Share Live Trip Information',
                subtitle:
                    'Send route, driver name, and vehicle details to family',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Trip details copied to clipboard. You can share via SMS or WhatsApp.',
                      ),
                      backgroundColor: AppColors.deepForest,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // Report Safety Issue Tile
              _buildActionTile(
                context,
                icon: Icons.report_problem_outlined,
                title: 'Report a Concern or Incident',
                subtitle:
                    'Submit feedback regarding vehicle or co-passenger behavior',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Support team notified. We will review this journey promptly.',
                      ),
                      backgroundColor: AppColors.deepForest,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'BEFORE YOU BOARD',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _buildGuidelineRow(
                      icon: Icons.badge_outlined,
                      title: 'Verify Vehicle Plate',
                      desc:
                          'Check that the number plate matches the app registration before entering the car.',
                    ),
                    const Divider(color: AppColors.border),
                    _buildGuidelineRow(
                      icon: Icons.pin_outlined,
                      title: 'Confirm Boarding PIN',
                      desc:
                          'Share your 4-digit code only with the designated Sahyān driver.',
                    ),
                    const Divider(color: AppColors.border),
                    _buildGuidelineRow(
                      icon: Icons.airline_seat_recline_normal_outlined,
                      title: 'Wear Seatbelts',
                      desc:
                          'Seatbelts are mandatory for all passengers traveling on highway corridors.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SahyanCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softForest,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: AppColors.primaryForest, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryForest, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                ),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
