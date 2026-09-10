import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'booking':
        return Icons.confirmation_number_outlined;
      case 'ride':
        return Icons.directions_car_outlined;
      case 'safety':
        return Icons.shield_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'booking':
        return AppColors.primaryForest;
      case 'ride':
        return AppColors.deepForest;
      case 'safety':
        return AppColors.mutedBrass;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final items = notifState.filteredItems;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Notifications',
        subtitle: notifState.unreadCount > 0
            ? '${notifState.unreadCount} unread update${notifState.unreadCount > 1 ? 's' : ''}'
            : null,
        showBackButton: true,
        actions: [
          if (notifState.items.isNotEmpty)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text(
                'Mark read',
                style: AppTypography.button.copyWith(
                  color: AppColors.primaryForest,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter categories
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      isSelected: notifState.activeFilter == 'all',
                      onTap: () => notifier.setFilter('all'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip(
                      label: 'Bookings',
                      isSelected: notifState.activeFilter == 'booking',
                      onTap: () => notifier.setFilter('booking'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip(
                      label: 'Rides',
                      isSelected: notifState.activeFilter == 'ride',
                      onTap: () => notifier.setFilter('ride'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip(
                      label: 'Safety',
                      isSelected: notifState.activeFilter == 'safety',
                      onTap: () => notifier.setFilter('safety'),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Notification List or Empty State
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: SahyanEmptyState(
                        title: 'No notifications yet',
                        description:
                            'You are completely up to date with your carpool activity.',
                        icon: Icons.notifications_none_outlined,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildNotificationCard(
                          context,
                          item,
                          onTap: () {
                            notifier.markAsRead(item.id);
                            context.push(
                              '/notifications/${item.id}',
                              extra: item,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem item, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SahyanCard(
        backgroundColor: item.isRead ? Colors.white : const Color(0xFFF0F5F2),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: _getCategoryColor(item.category),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(item.timestamp),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryForest,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
