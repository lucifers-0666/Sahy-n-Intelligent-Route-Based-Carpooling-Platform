import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/sahyan_button.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

class ReportDisputeBottomSheet extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isDriver;
  final VoidCallback? onDisputeSubmitted;

  const ReportDisputeBottomSheet({
    super.key,
    required this.bookingId,
    required this.isDriver,
    this.onDisputeSubmitted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required bool isDriver,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ReportDisputeBottomSheet(
          bookingId: bookingId,
          isDriver: isDriver,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReportDisputeBottomSheet> createState() =>
      _ReportDisputeBottomSheetState();
}

class _ReportDisputeBottomSheetState
    extends ConsumerState<ReportDisputeBottomSheet> {
  final _reasonController = TextEditingController();
  late String _selectedType;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Map<String, String>> get _options => widget.isDriver
      ? [
          {
            'type': 'unpaid_cash',
            'label': 'Passenger did not pay cash fuel split',
            'desc': 'Passenger boarded and arrived but refused or omitted cash contribution',
          },
          {
            'type': 'no_show',
            'label': 'Passenger was a no-show',
            'desc': 'Passenger did not arrive at pickup point and did not respond',
          },
          {
            'type': 'route_dispute',
            'label': 'Drop-off / route disagreement',
            'desc': 'Dispute regarding corridor stops or detours',
          },
          {
            'type': 'conduct_issue',
            'label': 'Misconduct or vehicle issue',
            'desc': 'Violation of community safety and carpooling etiquette',
          },
        ]
      : [
          {
            'type': 'fare_discrepancy',
            'label': 'Driver demanded extra cash contribution',
            'desc': 'Demanded payment above the agreed fuel cost share cap',
          },
          {
            'type': 'route_deviation',
            'label': 'Driver took unauthorized detour or drop',
            'desc': 'Did not drop at agreed corridor destination or skipped stops',
          },
          {
            'type': 'vehicle_mismatch',
            'label': 'Vehicle did not match registration',
            'desc': 'Different vehicle make, model, or license plate arrived',
          },
          {
            'type': 'service_issue',
            'label': 'Safety or conduct concern',
            'desc': 'Reckless driving, verbal harassment, or safety violations',
          },
        ];

  @override
  void initState() {
    super.initState();
    _selectedType = _options.first['type']!;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    final text = _reasonController.text.trim();
    if (text.length < 5) {
      setState(() {
        _errorMessage = 'Please provide an explanation of at least 5 characters.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);

      if (widget.isDriver && _selectedType == 'unpaid_cash') {
        await client.post(
          '/bookings/${widget.bookingId}/report-unpaid',
          body: {'notes': text},
        );
      } else {
        await client.post(
          '/bookings/${widget.bookingId}/dispute',
          body: {
            'reason': text,
            'disputeType': _selectedType,
            'claimType': widget.isDriver ? 'payment_claim' : 'refund_request',
          },
        );
      }

      if (mounted) {
        widget.onDisputeSubmitted?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mutedRust.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: AppColors.mutedRust,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.isDriver
                        ? 'Report Dispute or Non-Payment'
                        : 'File Booking or Fare Dispute',
                    style: AppTypography.headingSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Disputes are routed directly to the Sahyān Safety & Reconciliation team for verification.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'REASON CATEGORY',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ..._options.map((opt) {
              final isSelected = _selectedType == opt['type'];
              return InkWell(
                onTap: () => setState(() => _selectedType = opt['type']!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softForest.withValues(alpha: 0.5)
                        : AppColors.warmBackground,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryForest
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? AppColors.primaryForest
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['label']!,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primaryForest
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              opt['desc']!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'DETAILS & STATEMENT',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText:
                    'Describe the incident, payment reference, or route disagreement...',
                hintStyle: AppTypography.caption,
                filled: true,
                fillColor: AppColors.warmBackground,
                contentPadding: const EdgeInsets.all(AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedRust,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SahyanButton(
              text: 'Submit Formal Dispute',
              isLoading: _isSubmitting,
              isFullWidth: true,
              onPressed: _submitDispute,
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
