import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../domain/messaging_model.dart';
import '../providers/messaging_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagingProvider);
    final notifier = ref.read(messagingProvider.notifier);
    final conversations = state.filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Messages',
        subtitle: state.totalUnread > 0
            ? '${state.totalUnread} unread message${state.totalUnread > 1 ? 's' : ''}'
            : 'Direct ride communication',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SahyanTextField(
                hint: 'Search chats or routes...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onChanged: (val) => notifier.setSearchQuery(val),
              ),
            ),

            // Conversations List or Empty State
            Expanded(
              child: conversations.isEmpty
                  ? Center(
                      child: SahyanEmptyState(
                        title: 'No conversations yet',
                        description:
                            'Messages between you and your drivers or co-passengers will appear here.',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return _buildConversationTile(
                          context,
                          conv,
                          onTap: () {
                            notifier.markAsRead(conv.id);
                            context.push('/messages/${conv.id}', extra: conv);
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

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conv, {
    required VoidCallback onTap,
  }) {
    final isDriver = conv.participantRole == 'Driver';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SahyanCard(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SahyanAvatar(name: conv.participantName, radius: 23),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conv.participantName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? AppColors.softForest
                                    : const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                              child: Text(
                                conv.participantRole,
                                style: AppTypography.caption.copyWith(
                                  color: isDriver
                                      ? AppColors.primaryForest
                                      : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(conv.lastMessageTime),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conv.routeSummary,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryForest,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          style: AppTypography.bodySmall.copyWith(
                            color: conv.unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryForest,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conv.unreadCount.toString(),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
