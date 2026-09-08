import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_card.dart';

/// Tactile Route Corridor Card representing popular intercity carpooling routes.
class RouteCorridorCard extends StatelessWidget {
  final String origin;
  final String destination;
  final String price;
  final String subtitle;
  final VoidCallback onTap;

  const RouteCorridorCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.price,
    this.subtitle = 'High demand route · Daily carpools',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SahyanCard(
      onTap: onTap,
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        origin,
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + 2,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.mutedSage,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        destination,
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softForest,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  price,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryForest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primaryForest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
