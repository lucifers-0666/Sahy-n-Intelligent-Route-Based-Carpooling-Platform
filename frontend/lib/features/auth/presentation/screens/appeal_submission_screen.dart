import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/sahyan_button.dart';
import 'package:sahyan/core/widgets/sahyan_card.dart';
import 'package:sahyan/core/widgets/sahyan_text_field.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

class AppealSubmissionScreen extends ConsumerStatefulWidget {
  final String? initialReason;
  final String? initialEmail;

  const AppealSubmissionScreen({
    super.key,
    this.initialReason,
    this.initialEmail,
  });

  @override
  ConsumerState<AppealSubmissionScreen> createState() =>
      _AppealSubmissionScreenState();
}

class _AppealSubmissionScreenState
    extends ConsumerState<AppealSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    _emailController = TextEditingController(
      text: widget.initialEmail ?? authState.user?.email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/auth/appeal',
        body: {
          'reason': _reasonController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
        },
      );

      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: const SahyanAppBar(
          title: 'Appeal Submitted',
          showBackButton: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primaryForest,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Appeal Queued for Safety Review',
                  style: AppTypography.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your formal appeal statement has been registered in the immutable administrative ledger. A safety officer will review your compliance record and provide a resolution.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                SahyanButton(
                  text: 'Return to Status Notice',
                  isFullWidth: true,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/account-suspended');
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Account Reinstatement Appeal',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.initialReason != null &&
                    widget.initialReason!.isNotEmpty) ...[
                  SahyanCard(
                    backgroundColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECORDED SUSPENSION REASON',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedRust,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.initialReason!,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SahyanCard(
                  backgroundColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appeal Guidelines',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Please provide an honest and detailed statement. If your restriction was due to an unpaid fuel split, payment app outage, or miscommunication, explain how the matter was resolved.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SahyanTextField(
                  label: 'Registered Email or Identifier',
                  hint: 'name@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter registered account email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Detailed Justification Statement',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 5,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText:
                        'Explain why your account should be reinstated. Minimum 10 characters...',
                    hintStyle: AppTypography.caption,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryForest,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 10) {
                      return 'Appeal reason must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.mutedRust.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.mutedRust),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedRust,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SahyanButton(
                  text: 'Submit Reinstatement Appeal',
                  isLoading: _isSubmitting,
                  isFullWidth: true,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
