import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';

class PrivacyPermissionsScreen extends ConsumerStatefulWidget {
  const PrivacyPermissionsScreen({super.key});

  @override
  ConsumerState<PrivacyPermissionsScreen> createState() =>
      _PrivacyPermissionsScreenState();
}

class _PrivacyPermissionsScreenState
    extends ConsumerState<PrivacyPermissionsScreen> {
  bool _locationGranted = true;
  bool _biometricsGranted = true;
  bool _emergencyTelephonyGranted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: AppBar(
        backgroundColor: SahyanColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: SahyanColors.textMain, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Privacy & Permissions Hub',
          style: TextStyle(
            color: SahyanColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: SahyanColors.border, height: 0.8),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Enterprise Privacy Shield Banner
            _buildPrivacyShieldBanner(),
            const SizedBox(height: 16),

            // Section Header
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Essential System Permissions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SahyanColors.textMuted,
                ),
              ),
            ),

            // 1. Precise Location (GPS)
            _buildPermissionCard(
              icon: Icons.my_location_rounded,
              title: 'Precise Location (GPS)',
              tag: 'Active Journeys Only',
              tagColor: SahyanColors.primaryDark,
              whyExplanation:
                  'To show nearby drivers along your corridor and enable turn-by-turn pickup navigation.',
              policyExplanation:
                  'GPS is only streamed while an active journey is in progress and immediately terminated upon trip completion.',
              isGranted: _locationGranted,
              onToggle: (val) {
                setState(() => _locationGranted = val);
              },
              onExplain: () => _showPermissionExplanationSheet(
                context: context,
                title: 'Precise Location & Corridor Telematics',
                icon: Icons.location_on_rounded,
                why:
                    'To show nearby drivers along your corridor and enable turn-by-turn pickup navigation.',
                policy:
                    'GPS is only streamed while an active journey is in progress and immediately terminated upon trip completion.',
                enclavePoints: [
                  'Location is bounded strictly within your selected highway corridor.',
                  'No background tracking occurs when you are not on an active trip.',
                  'Telematics streams directly over secure TLS/WSS with fail-closed tokens.',
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Biometric Sensors (Face ID / Fingerprint)
            _buildPermissionCard(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Authentication',
              tag: 'Hardware Enclave',
              tagColor: SahyanColors.primaryMint,
              whyExplanation:
                  'To decrypt your local login token securely on your device.',
              policyExplanation:
                  'Biometric mathematical hashes never leave your device hardware enclave.',
              isGranted: _biometricsGranted,
              onToggle: (val) {
                setState(() => _biometricsGranted = val);
              },
              onExplain: () => _showPermissionExplanationSheet(
                context: context,
                title: 'Biometric Secure Enclave Storage',
                icon: Icons.fingerprint_rounded,
                why:
                    'To decrypt your local login token securely on your device.',
                policy:
                    'Biometric mathematical hashes never leave your device hardware enclave.',
                enclavePoints: [
                  'Your Face ID / Fingerprint templates are stored exclusively inside the OS hardware Secure Enclave.',
                  'Sahyān servers never receive or store biometric mathematical templates.',
                  'Tokens are sealed with device-bound AES-256 cryptographic keys.',
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Emergency Contacts / Telephony
            _buildPermissionCard(
              icon: Icons.contact_phone_rounded,
              title: 'Emergency Contacts & Ring',
              tag: 'Safety Protocol',
              tagColor: SahyanColors.urgentCoral,
              whyExplanation:
                  'To broadcast live corridor status and auto-dial your safety ring in emergency situations.',
              policyExplanation:
                  'Emergency telephony is only activated when an SOS alert is confirmed or you initiate safety ring dispatch.',
              isGranted: _emergencyTelephonyGranted,
              onToggle: (val) {
                setState(() => _emergencyTelephonyGranted = val);
              },
              onExplain: () => _showPermissionExplanationSheet(
                context: context,
                title: 'Emergency Ring & Safety Dispatch',
                icon: Icons.shield_rounded,
                why:
                    'To broadcast live corridor status and auto-dial your safety ring in emergency situations.',
                policy:
                    'Contacts are strictly accessed to ping safety rings during active rides or SOS triggers and never shared with third parties.',
                enclavePoints: [
                  'Contacts are only broadcasted when an emergency SOS trigger is initiated.',
                  'Live corridor links expire automatically after trip arrival.',
                  'Direct integration with National Emergency Services (112).',
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DPDP Compliance Assurance Bento
            _buildComplianceAssuranceBento(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyShieldBanner() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SahyanColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.privacy_tip_outlined,
              color: SahyanColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Shield & Data Minimization',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: SahyanColors.textMain,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sahyān operates on strict data minimization principles. We only collect the bare minimum telematics required to ensure commuter safety and route navigation.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: SahyanColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String tag,
    required Color tagColor,
    required String whyExplanation,
    required String policyExplanation,
    required bool isGranted,
    required ValueChanged<bool> onToggle,
    required VoidCallback onExplain,
  }) {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SahyanColors.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SahyanColors.border, width: 0.8),
                ),
                child: Icon(icon, color: SahyanColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isGranted,
                activeTrackColor: SahyanColors.primaryDark,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        whyExplanation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SahyanColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Policy: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.primaryDark,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        policyExplanation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SahyanColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onExplain,
              icon: const Icon(Icons.info_outline_rounded,
                  size: 15, color: SahyanColors.primaryDark),
              label: const Text(
                'View Enclave Security Specs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SahyanColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceAssuranceBento() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: SahyanColors.primaryMint, size: 18),
              SizedBox(width: 8),
              Text(
                'Regulatory & DPDP Compliance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SahyanColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All personal data is stored within certified Indian sovereign cloud regions (Mumbai/Pune). Under the Digital Personal Data Protection Act (DPDP), you retain full rights to inspect, export, and delete your profile at any time.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: SahyanColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              context.pop();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: SahyanColors.border, width: 0.8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'Return to Profile Safety Center',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SahyanColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionExplanationSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String why,
    required String policy,
    required List<String> enclavePoints,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: SahyanColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: SahyanColors.border, width: 0.8),
            left: BorderSide(color: SahyanColors.border, width: 0.8),
            right: BorderSide(color: SahyanColors.border, width: 0.8),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SahyanColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: SahyanColors.primaryDark, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SahyanColors.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SahyanColors.border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Purpose of Access',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.primaryDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    why,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SahyanColors.textMain,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Data Retention & Enclave Policy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SahyanColors.primaryDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    policy,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SahyanColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Security Architecture Guarantees',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SahyanColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            ...enclavePoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: SahyanColors.primaryMint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SahyanColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: SahyanColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Acknowledge & Save Preference',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
