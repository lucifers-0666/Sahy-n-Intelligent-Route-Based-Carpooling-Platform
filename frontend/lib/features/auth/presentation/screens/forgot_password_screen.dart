import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/sahyan_route_convergence_logo.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Production Forgot Password Screen for Sahyān.
/// Features brand tokens, responsive card styling, and custom feedback alerts.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleForgot() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final success = await ref.read(authProvider.notifier).forgotPassword(email);

    if (success && mounted) {
      setState(() => _sent = true);
      FeedbackService.success(
        context,
        'Reset link dispatched. Please check your inbox.',
      );
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      FeedbackService.error(
        context,
        errorMsg ?? 'Failed to process password recovery',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.sahyanTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Navigation
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tokens.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: tokens.border,
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tokens.ink.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SahyanRouteConvergenceMark(size: 30, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: tokens.card,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: tokens.border, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: tokens.ink.withValues(
                              alpha: isDark ? 0.25 : 0.05,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: tokens.brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tokens.brand.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: tokens.brand,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your registered email address and we will dispatch secure password recovery instructions.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: tokens.muted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_sent) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: tokens.brand.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.input,
                                ),
                                border: Border.all(
                                  color: tokens.mint.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: tokens.brand,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Instructions Dispatched',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'If an account exists for this address, a reset token has been sent to your email.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          SahyanTextField(
                            label: 'Email Address',
                            hint: 'arjun@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              color: tokens.brand,
                              size: 20,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email address';
                              }
                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          SahyanButton(
                            text: _sent
                                ? 'Resend Instructions'
                                : 'Send Instructions',
                            isLoading: authState.isLoading,
                            isFullWidth: true,
                            onPressed: _handleForgot,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: tokens.brand,
                        ),
                        label: Text(
                          'Back to Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.brand,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
