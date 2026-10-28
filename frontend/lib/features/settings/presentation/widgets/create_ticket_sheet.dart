import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../support_tickets_provider.dart';

class CreateTicketSheet extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? bookingSummary;

  const CreateTicketSheet({
    super.key,
    this.bookingId,
    this.bookingSummary,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? bookingId,
    String? bookingSummary,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CreateTicketSheet(
          bookingId: bookingId,
          bookingSummary: bookingSummary,
        ),
      ),
    );
  }

  @override
  ConsumerState<CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'ride_issue';
  final String _priority = 'medium';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = context.l10n;

    final created = await ref.read(supportTicketsProvider.notifier).createTicket(
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      bookingId: widget.bookingId,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (created != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.ticketCreatedSuccess}: ${created.ticketNumber}'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ticketCreateFailed),
            backgroundColor: AppColors.mutedRust,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.createTicketSheetTitle,
                    style: AppTypography.screenTitle.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.createTicketSheetSubtitle,
                style: AppTypography.caption,
              ),

              if (widget.bookingSummary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.softForest,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 16, color: AppColors.primaryForest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.bookingSummary!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Category Selector
              Text(l10n.categoryLabel, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
                items: [
                  DropdownMenuItem(value: 'ride_issue', child: Text(l10n.categoryRideIssue)),
                  DropdownMenuItem(value: 'payment_inquiry', child: Text(l10n.categoryPaymentInquiry)),
                  DropdownMenuItem(value: 'driver_behavior', child: Text(l10n.categoryDriverBehavior)),
                  DropdownMenuItem(value: 'technical_bug', child: Text(l10n.categoryTechBug)),
                  DropdownMenuItem(value: 'account_access', child: Text(l10n.categoryAccountAccess)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.categoryOther)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Subject Input
              SahyanTextField(
                label: l10n.subjectLabel,
                hint: l10n.subjectHint,
                controller: _subjectController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l10n.subjectRequired;
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Description Input
              Text(l10n.descriptionLabel, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.descriptionHint,
                  hintStyle: AppTypography.caption,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.primaryForest, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l10n.descriptionRequired;
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              SahyanButton(
                text: l10n.submitTicketButton,
                isLoading: _isSubmitting,
                isFullWidth: true,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
