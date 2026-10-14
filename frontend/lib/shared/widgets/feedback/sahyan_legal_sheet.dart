import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';

/// Clean Material bottom sheet displaying Sahyān's Terms of Service and Privacy Policy.
/// Avoids raw unstyled dialogs and yellow text underlines.
class SahyanLegalSheet {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.mutedLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceHigh : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            size: 20,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Terms of Service & Privacy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('1. Community & Fair Cost Sharing', textColor),
                            _sectionBody(
                              'Sahyān is Gujarat\'s community-driven verified intercity carpooling platform. Rides shared on Sahyān operate strictly on a not-for-profit, fair cost-sharing basis (fuel, tolls, and maintenance contribution). Drivers do not operate as commercial taxi operators.',
                              mutedColor,
                            ),
                            const SizedBox(height: 14),

                            _sectionHeader('2. Safety & Verification Standards', textColor),
                            _sectionBody(
                              'All members must register with an authentic phone number and verified credentials. Members agree to treat co-travelers with respect and adhere to traffic safety laws across all highway corridors.',
                              mutedColor,
                            ),
                            const SizedBox(height: 14),

                            _sectionHeader('3. Privacy & Data Handling', textColor),
                            _sectionBody(
                              'Your location is shared with co-travelers exclusively during active ride matching and trip progress. Account data and contact credentials are transmitted over encrypted HTTPS transport. (Draft terms subject to formal legal review).',
                              mutedColor,
                            ),
                            const SizedBox(height: 14),

                            _sectionHeader('4. Cancellation & Route Commitments', textColor),
                            _sectionBody(
                              'To maintain community trust, cancellations must be made promptly. Consistent last-minute cancellations may result in temporary account cooldown.',
                              mutedColor,
                            ),
                            const SizedBox(height: 14),

                            _sectionHeader('5. Regulatory Notice', textColor),
                            _sectionBody(
                              'These operational guidelines are prepared for academic and testing evaluation. Full regulatory disclosures and policies will be finalized with legal counsel before general public availability.',
                              mutedColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Accept Button
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      child: Text(
                        'Understood & Accept',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  static Widget _sectionBody(String body, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        body,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: color,
          height: 1.45,
        ),
      ),
    );
  }
}
