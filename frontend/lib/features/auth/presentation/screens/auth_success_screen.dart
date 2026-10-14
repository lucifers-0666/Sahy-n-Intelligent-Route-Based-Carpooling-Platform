import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Production Auth Success Screen for Sahyān.
class AuthSuccessScreen extends ConsumerWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.sahyanTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final phone =
        authState.otpSentToPhone ?? user?.phone ?? 'Member Phone Verified';

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Brand Hero Shield with Mint Ambient Halo
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: tokens.mint.withValues(
                              alpha: isDark ? 0.15 : 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: tokens.brand.withValues(
                              alpha: isDark ? 0.3 : 0.12,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.mint.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.verified_user,
                            color: tokens.brand,
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Verified Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: tokens.border, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.ink.withValues(
                            alpha: isDark ? 0.25 : 0.05,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Step Monogram Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.brand.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: tokens.brand.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: tokens.mint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Identity Verification',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.brand,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "You're all set",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                            letterSpacing: -0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Your Sahyān account is confirmed. You can now discover, request and share trusted highway journeys.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: tokens.muted,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Verification Pillars
                        _buildTrustPillar(
                          tokens,
                          Icons.phone_android,
                          'Phone Authenticated ($phone)',
                        ),
                        const SizedBox(height: 8),
                        _buildTrustPillar(
                          tokens,
                          Icons.chat_bubble_outline,
                          'Zero-Spam Direct Messaging Active',
                        ),
                        const SizedBox(height: 8),
                        _buildTrustPillar(
                          tokens,
                          Icons.security,
                          'SafePass Trust Protocol Enabled',
                        ),

                        const SizedBox(height: 16),

                        // India-wide route network banner
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [tokens.surfaceHigh, tokens.card]
                                  : [tokens.brand, tokens.brandBright],
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.input),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.alt_route,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'India-wide carpooling network',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Real-time corridor matching active',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: tokens.mint,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Actions
                        SahyanButton(
                          text: 'Complete Your Profile',
                          icon: Icons.arrow_forward,
                          isFullWidth: true,
                          onPressed: () => context.push('/personal-details'),
                        ),
                        const SizedBox(height: 10),
                        SahyanButton(
                          text: 'Explore Routes First',
                          variant: SahyanButtonVariant.outline,
                          isFullWidth: true,
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Security Footnote
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Icon(
                        Icons.security,
                        size: 14,
                        color: tokens.muted,
                      ),
                      Text(
                        '256-bit Encrypted Member Identity',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustPillar(
    SahyanThemeTokens tokens,
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.canvas,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: tokens.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: tokens.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tokens.brand, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
