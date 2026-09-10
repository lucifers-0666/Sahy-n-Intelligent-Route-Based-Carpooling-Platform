import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design_system.dart';
import '../../../auth/presentation/auth_provider.dart';

class ReviewsRatingsScreen extends ConsumerStatefulWidget {
  const ReviewsRatingsScreen({super.key});

  @override
  ConsumerState<ReviewsRatingsScreen> createState() =>
      _ReviewsRatingsScreenState();
}

class _ReviewsRatingsScreenState extends ConsumerState<ReviewsRatingsScreen> {
  int _selectedTab = 0; // 0: All Reviews, 1: As Passenger, 2: As Driver

  final List<Map<String, dynamic>> _sampleReviews = [
    {
      'name': 'Priya Shah',
      'role': 'Co-passenger',
      'rating': 5,
      'date': '2 days ago',
      'corridor': 'Ahmedabad → Vadodara',
      'comment':
          'Very punctual and courteous. The car was spotless and the ride was extremely smooth.',
    },
    {
      'name': 'Rahul Dave',
      'role': 'Driver',
      'rating': 5,
      'date': '1 week ago',
      'corridor': 'Gandhinagar → GIFT City',
      'comment':
          'Great passenger! Was ready at the pickup point right on time. Highly recommended.',
    },
    {
      'name': 'Ananya Desai',
      'role': 'Co-passenger',
      'rating': 4,
      'date': '2 weeks ago',
      'corridor': 'Ahmedabad → Rajkot',
      'comment':
          'Pleasant conversation and calm driving. Would definitely travel together again.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final rating = user?.rating ?? 4.9;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Reviews & Ratings',
        subtitle: 'Community trust and journey feedback',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating Overview Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTypography.displayHero.copyWith(
                            fontSize: 44,
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.mutedBrass,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overall Rating',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        children: [
                          _buildRatingBar(5, 0.85),
                          _buildRatingBar(4, 0.12),
                          _buildRatingBar(3, 0.03),
                          _buildRatingBar(2, 0.0),
                          _buildRatingBar(1, 0.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Segmented Tabs
              Row(
                children: [
                  _buildTab('All Reviews (3)', 0),
                  const SizedBox(width: AppSpacing.sm),
                  _buildTab('Passenger (2)', 1),
                  const SizedBox(width: AppSpacing.sm),
                  _buildTab('Driver (1)', 2),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Reviews List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sampleReviews.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final review = _sampleReviews[index];
                  return SahyanCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SahyanAvatar(
                              name: review['name'] as String,
                              radius: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        review['name'] as String,
                                        style: AppTypography.cardTitle.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        review['date'] as String,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${review['role']} • ${review['corridor']}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryForest,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: List.generate(
                            review['rating'] as int,
                            (i) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.mutedBrass,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review['comment'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
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

  Widget _buildRatingBar(int stars, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: AppColors.mutedBrass),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.full),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryForest,
                ),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryForest : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
