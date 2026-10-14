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
import '../../../../shared/widgets/sahyan_route_background.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Production Reset Password Screen for Sahyān.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      FeedbackService.error(context, 'Passwords do not match');
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .resetPassword(
          token: _tokenController.text.trim(),
          newPassword: _passwordController.text.trim(),
        );

    if (success && mounted) {
      FeedbackService.success(
        context,
        'Password updated successfully. Please sign in.',
      );
      context.go('/login');
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage;
      FeedbackService.error(
        context,
        errorMsg ?? 'Failed to reset password. Please verify your token.',
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
      body: SahyanRouteBackground(
        isDark: isDark,
        child: SafeArea(
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
                                Icons.arrow_back,
                                size: 18,
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
                                Icons.vpn_key,
                                color: tokens.brand,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Reset Password',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: tokens.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your reset token and select a new secure password.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: tokens.muted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),

                            SahyanTextField(
                              label: 'Reset Token',
                              hint: 'Paste the reset token from your email',
                              controller: _tokenController,
                              prefixIcon: Icon(
                                Icons.vpn_key,
                                color: tokens.brand,
                                size: 20,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Reset token is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            SahyanTextField(
                              label: 'New Password',
                              hint: 'Min. 8 characters',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: tokens.brand,
                                size: 20,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'New password is required';
                                }
                                if (v.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            SahyanTextField(
                              label: 'Confirm New Password',
                              hint: 'Re-enter your new password',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              prefixIcon: Icon(
                                Icons.lock_reset,
                                color: tokens.brand,
                                size: 20,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            SahyanButton(
                              text: 'Update Password',
                              isLoading: authState.isLoading,
                              isFullWidth: true,
                              onPressed: _handleReset,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
