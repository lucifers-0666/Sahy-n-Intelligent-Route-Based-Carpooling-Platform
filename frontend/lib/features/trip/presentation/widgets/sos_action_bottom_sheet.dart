import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../profile/presentation/profile_provider.dart';

class SosActionBottomSheet extends ConsumerWidget {
  final BookingModel? booking;

  const SosActionBottomSheet({super.key, this.booking});

  static Future<void> show(
    BuildContext context, {
    BookingModel? booking,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SosActionBottomSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final emergencyContacts = profileState.emergencyContacts;
    final primaryContact = emergencyContacts.isNotEmpty ? emergencyContacts.first : null;

    final bookingId = booking?.id ?? 'active-corridor-trip';
    final liveShareUrl = 'https://sahyan.app/live-tracking/track-live?bookingId=$bookingId';

    return Container(
      decoration: const BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: SahyanColors.border, width: 0.8),
          left: BorderSide(color: SahyanColors.border, width: 0.8),
          right: BorderSide(color: SahyanColors.border, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: SahyanColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Urgent Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SahyanColors.urgentCoral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: SahyanColors.urgentCoral,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency SOS & Safety',
                      style: AppTypography.cardTitle.copyWith(
                        color: SahyanColors.urgentCoral,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Immediate response command for your journey',
                      style: AppTypography.caption.copyWith(
                        color: SahyanColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action 1: Call 112 (National Emergency)
          _buildActionTile(
            context: context,
            icon: Icons.local_police_outlined,
            title: 'Call National Emergency (112)',
            subtitle: 'Direct connection to emergency police & medical assistance',
            iconColor: SahyanColors.urgentCoral,
            bgColor: SahyanColors.urgentCoral.withValues(alpha: 0.08),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dialing 112 National Emergency Police...'),
                  backgroundColor: SahyanColors.urgentCoral,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Action 2: 24/7 Sahyān Safety Helpline
          _buildActionTile(
            context: context,
            icon: Icons.support_agent_rounded,
            title: 'Sahyān Safety Command (1800-SAHYAN)',
            subtitle: 'Dedicated round-the-clock carpool trust & safety team',
            iconColor: SahyanColors.primaryDark,
            bgColor: SahyanColors.canvas,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting to Sahyān 24/7 Safety Command...'),
                  backgroundColor: SahyanColors.primaryDark,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Action 3: Primary Emergency Contact
          if (primaryContact != null)
            _buildActionTile(
              context: context,
              icon: Icons.contact_phone_outlined,
              title: 'Call ${primaryContact.name} (${primaryContact.relationship})',
              subtitle: primaryContact.phone,
              iconColor: SahyanColors.primaryMint,
              bgColor: SahyanColors.canvas,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling emergency contact ${primaryContact.name} (${primaryContact.phone})...'),
                    backgroundColor: SahyanColors.primaryDark,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            )
          else
            _buildActionTile(
              context: context,
              icon: Icons.person_add_alt_outlined,
              title: 'Add Emergency Contacts',
              subtitle: 'Set up trusted circle for 1-tap alerts during rides',
              iconColor: SahyanColors.textMuted,
              bgColor: SahyanColors.canvas,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/emergency-contacts');
              },
            ),
          const SizedBox(height: 10),

          // Action 4: Share Live GPS Corridor
          _buildActionTile(
            context: context,
            icon: Icons.share_location_rounded,
            title: 'Share Live Trip Corridor',
            subtitle: 'Share live GPS route tracking link with friends & family',
            iconColor: SahyanColors.primaryDark,
            bgColor: SahyanColors.canvas,
            onTap: () {
              Clipboard.setData(ClipboardData(text: liveShareUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live trip tracking link copied to clipboard!'),
                  backgroundColor: SahyanColors.primaryDark,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Close button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: SahyanColors.textMain,
              side: const BorderSide(color: SahyanColors.border, width: 0.8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SahyanColors.border, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: SahyanColors.border, width: 0.8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.primaryDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: SahyanColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: SahyanColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
