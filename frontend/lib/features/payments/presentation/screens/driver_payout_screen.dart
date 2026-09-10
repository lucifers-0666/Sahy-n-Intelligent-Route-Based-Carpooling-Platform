import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';

class DriverPayoutScreen extends StatelessWidget {
  const DriverPayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleSettlements = [
      {
        'id': 'payout-1',
        'corridor': 'Ahmedabad → Vadodara',
        'date': 'Yesterday, 06:45 PM',
        'passengers': 2,
        'amount': 500.0,
        'status': 'Settled via UPI',
      },
      {
        'id': 'payout-2',
        'corridor': 'Gandhinagar → GIFT City',
        'date': '05 Sep 2026',
        'passengers': 3,
        'amount': 450.0,
        'status': 'Settled via Cash',
      },
      {
        'id': 'payout-3',
        'corridor': 'Ahmedabad → Mehsana',
        'date': '01 Sep 2026',
        'passengers': 1,
        'amount': 300.0,
        'status': 'Settled via UPI',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Driver Earnings & Payout',
        subtitle: 'Carpool cost sharing and settlements',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_balance_outlined,
              color: AppColors.primaryForest,
              size: 22,
            ),
            tooltip: 'Payout Account',
            onPressed: () => context.push('/driver/payout-account'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Summary Hero Card
              SahyanCard(
                backgroundColor: AppColors.primaryForest,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL FUEL CONTRIBUTIONS RECEIVED',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '₹4,250',
                      style: AppTypography.displayHero.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Month',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '₹1,850',
                                style: AppTypography.cardTitle.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared Rides Hosted',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '14 Trips',
                                style: AppTypography.cardTitle.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Registered Payout Account Card
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
                        Icons.account_balance_outlined,
                        color: AppColors.primaryForest,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settlement UPI / Bank',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'karan.driver@oksbi (Active)',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/driver/payout-account'),
                      child: Text(
                        'Change',
                        style: AppTypography.button.copyWith(
                          color: AppColors.primaryForest,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'SETTLEMENT HISTORY',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sampleSettlements.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = sampleSettlements[index];
                  return SahyanCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['corridor'] as String,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['date']} • ${item['passengers']} Passengers',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['status'] as String,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+₹${(item['amount'] as double).toStringAsFixed(0)}',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
