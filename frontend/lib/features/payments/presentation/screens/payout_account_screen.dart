import 'package:flutter/material.dart';
import '../../../../core/widgets/design_system.dart';

class PayoutAccountScreen extends StatefulWidget {
  const PayoutAccountScreen({super.key});

  @override
  State<PayoutAccountScreen> createState() => _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends State<PayoutAccountScreen> {
  int _payoutType = 0; // 0: UPI VPA, 1: Bank Transfer
  final _upiController = TextEditingController(text: 'karan.driver@oksbi');
  final _accountHolderController = TextEditingController(text: 'Karan Patel');
  final _accountNumberController = TextEditingController(
    text: '9182374619283746',
  );
  final _ifscController = TextEditingController(text: 'SBIN0001234');

  @override
  void dispose() {
    _upiController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Payout Account',
        subtitle: 'Configure expense reimbursement destination',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              SahyanCard(
                backgroundColor: AppColors.softForest.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your settlement information is encrypted and only used to credit peer fuel reimbursements from confirmed passengers.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.deepForest,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'SETTLEMENT METHOD',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _buildTypeSelector(
                      title: 'UPI Handle',
                      subtitle: 'Instant Transfer',
                      isSelected: _payoutType == 0,
                      onTap: () => setState(() => _payoutType = 0),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTypeSelector(
                      title: 'Bank Account',
                      subtitle: 'IMPS / NEFT',
                      isSelected: _payoutType == 1,
                      onTap: () => setState(() => _payoutType = 1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              if (_payoutType == 0) ...[
                SahyanCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SahyanTextField(
                        label: 'UPI ID (VPA)',
                        hint: 'e.g. mobile@upi or name@okaxis',
                        controller: _upiController,
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SahyanCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      SahyanTextField(
                        label: 'Account Holder Name',
                        hint: 'As per bank records',
                        controller: _accountHolderController,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SahyanTextField(
                        label: 'Bank Account Number',
                        hint: 'Enter 11-16 digit account number',
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SahyanTextField(
                        label: 'IFSC Code',
                        hint: 'e.g. SBIN0001234',
                        controller: _ifscController,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              SahyanButton(
                text: 'Save Payout Details',
                icon: Icons.check_circle_outline_rounded,
                isFullWidth: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payout account updated successfully.'),
                      backgroundColor: AppColors.primaryForest,
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softForest : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 14,
                color: isSelected
                    ? AppColors.primaryForest
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: isSelected
                    ? AppColors.primaryForest
                    : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
