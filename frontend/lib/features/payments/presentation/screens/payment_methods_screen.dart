import 'package:flutter/material.dart';
import '../../../../core/widgets/design_system.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _savedUPIs = [
    {
      'id': 'upi-1',
      'title': 'Google Pay (UPI)',
      'handle': 'member@oksbi',
      'isDefault': true,
    },
    {
      'id': 'upi-2',
      'title': 'PhonePe (UPI)',
      'handle': 'member@ybl',
      'isDefault': false,
    },
  ];

  void _showAddUpiDialog(BuildContext context) {
    final upiController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add UPI ID for Carpool Contributions',
                style: AppTypography.screenTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Used for direct passenger-to-driver peer carpool expense sharing.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SahyanTextField(
                label: 'Virtual Payment Address (VPA)',
                hint: 'e.g. yourname@okhdfcbank',
                controller: upiController,
                prefixIcon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryForest,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SahyanButton(
                text: 'Save UPI Method',
                icon: Icons.check_rounded,
                isFullWidth: true,
                onPressed: () {
                  if (upiController.text.trim().isNotEmpty &&
                      upiController.text.contains('@')) {
                    setState(() {
                      _savedUPIs.add({
                        'id': 'upi-${DateTime.now().millisecondsSinceEpoch}',
                        'title': 'UPI Handle',
                        'handle': upiController.text.trim(),
                        'isDefault': false,
                      });
                    });
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Payment Methods',
        subtitle: 'Manage peer carpool payment options',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryForest,
              size: 24,
            ),
            tooltip: 'Add Method',
            onPressed: () => _showAddUpiDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community Carpool Sharing Notice
              SahyanCard(
                backgroundColor: AppColors.softForest.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shared Route Contributions',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sahyān is a non-commercial carpooling platform. Fuel and toll expenses are shared directly between co-travelers via UPI or Cash.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.deepForest,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'SAVED UPI HANDLES',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (_savedUPIs.isEmpty)
                SahyanEmptyState(
                  title: 'No payment methods saved',
                  description:
                      'Add your preferred UPI ID for quick cost contributions.',
                  icon: Icons.credit_card_off_outlined,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedUPIs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = _savedUPIs[index];
                    final isDefault = item['isDefault'] as bool;

                    return SahyanCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDefault
                                  ? AppColors.primaryForest
                                  : AppColors.softForest,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: isDefault
                                  ? Colors.white
                                  : AppColors.primaryForest,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: AppTypography.cardTitle.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.softForest,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.sm,
                                          ),
                                        ),
                                        child: Text(
                                          'PRIMARY',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.primaryForest,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['handle'] as String,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _savedUPIs.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'CASH ON ARRIVAL',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.primaryForest,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Direct Cash Exchange',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hand cash to driver upon completing the shared trip.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
