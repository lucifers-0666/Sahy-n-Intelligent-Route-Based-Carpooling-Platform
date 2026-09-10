import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../domain/notification_model.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationItem? notification;

  const NotificationDetailsScreen({super.key, this.notification});

  @override
  Widget build(BuildContext context) {
    if (notification == null) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: const SahyanAppBar(
          title: 'Notification Details',
          showBackButton: true,
        ),
        body: Center(
          child: SahyanEmptyState(
            title: 'Notification Not Found',
            description: 'The requested notification could not be located.',
            icon: Icons.notifications_off_outlined,
          ),
        ),
      );
    }

    final item = notification!;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Notification Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} at ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.title,
                      style: AppTypography.screenTitle.copyWith(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.message,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (item.routeTarget != null)
                SahyanButton(
                  text: 'View Related Details',
                  icon: Icons.arrow_forward_rounded,
                  isFullWidth: true,
                  onPressed: () {
                    context.push(item.routeTarget!);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
