import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_card.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How does Sahyan route-based carpooling work?',
      'answer':
          'Sahyan matches commuters travelling along similar highway corridors. The platform calculates route overlap and ensures detours remain minimal.',
    },
    {
      'question': 'What is the cancellation and refund policy?',
      'answer':
          'Passengers can cancel confirmed bookings before departure with a 100% refund. Driver cancellations trigger instant escrow refunds back to your original payment method.',
    },
    {
      'question': 'How do Boarding PINs protect passengers and drivers?',
      'answer':
          'When a booking is confirmed, a confidential 4-digit PIN is generated. The passenger shows this PIN to the driver at the pickup point to authenticate boarding before the trip begins.',
    },
    {
      'question': 'How are fuel contributions calculated?',
      'answer':
          'Contributions are strictly limited to fair-share fuel and highway toll splits. Sahyan is a non-commercial carpooling community.',
    },
    {
      'question': 'What should I do if a driver or passenger is delayed?',
      'answer':
          'Use the in-app chat or phone contact to coordinate. We recommend a 10-minute departure buffer for highway pickup points.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _searchQuery.isEmpty
        ? _faqItems
        : _faqItems
              .where(
                (f) =>
                    f['question']!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    f['answer']!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Help & Support',
        subtitle: 'Priority Member Desk',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search help articles, topics, or issues...',
                  hintStyle: AppTypography.secondary,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(
                      color: AppColors.primaryForest,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Recent Journey Context Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'RECENT JOURNEY',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(
                            'Active',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ahmedabad to Rajkot Express Corridor',
                      style: AppTypography.cardTitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      'Scheduled Journey · Seat A2 Reserved',
                      style: AppTypography.caption,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Opening support ticket for recent trip',
                            ),
                            backgroundColor: AppColors.primaryForest,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.contact_support_outlined,
                            size: 18,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Need help with this trip?',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryForest,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.primaryForest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Knowledge Hub Bento Grid
              Text(
                'Knowledge Hub',
                style: AppTypography.sectionHeader.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 450;
                  return GridView.count(
                    crossAxisCount: isCompact ? 1 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: isCompact ? 3.8 : 3.0,
                    children: [
                      _buildHubTile(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Bookings & Seats',
                        subtitle: 'Seat adjustments & luggage rules',
                      ),
                      _buildHubTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payments & Payouts',
                        subtitle: 'Escrow timing & UPI refunds',
                      ),
                      _buildHubTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Safety & Trust',
                        subtitle: 'Govt ID verification & PIN',
                      ),
                      _buildHubTile(
                        icon: Icons.directions_car_outlined,
                        title: 'Driver Guidelines',
                        subtitle: 'Offering rides & corridor rules',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: AppTypography.sectionHeader.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),

              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: filteredFaqs.map((faq) {
                    return ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        faq['question']!,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.md,
                            right: AppSpacing.md,
                            bottom: AppSpacing.md,
                          ),
                          child: Text(
                            faq['answer']!,
                            style: AppTypography.secondary.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Priority Support Desk
              Text(
                'Contact Support',
                style: AppTypography.sectionHeader.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),

              SahyanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        'Start Direct In-App Chat',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Priority response from community desk',
                        style: AppTypography.caption,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/messages'),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.primaryForest,
                      ),
                      title: Text(
                        'Email Support',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        'support@sahyan.in',
                        style: AppTypography.caption,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Support email: support@sahyan.in',
                            ),
                            backgroundColor: AppColors.primaryForest,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SahyanCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.softForest,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: AppColors.primaryForest, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
