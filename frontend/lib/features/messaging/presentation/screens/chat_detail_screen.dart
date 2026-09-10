import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design_system.dart';
import '../../domain/messaging_model.dart';
import '../providers/messaging_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Conversation? initialConversation;
  final String? conversationId;

  const ChatDetailScreen({
    super.key,
    this.initialConversation,
    this.conversationId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);
    final notifier = ref.read(messagingProvider.notifier);

    // Resolve conversation
    Conversation? conv = widget.initialConversation;
    if (conv == null && widget.conversationId != null) {
      final matches = state.conversations
          .where((c) => c.id == widget.conversationId)
          .toList();
      if (matches.isNotEmpty) {
        conv = matches.first;
      }
    }

    if (conv == null) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: const SahyanAppBar(title: 'Chat', showBackButton: true),
        body: Center(
          child: SahyanEmptyState(
            title: 'Conversation Not Found',
            description:
                'This conversation does not exist or has been removed.',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
      );
    }

    final messages = state.messages[conv.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: conv.participantName,
        subtitle: '${conv.participantRole} • ${conv.routeSummary}',
        showBackButton: true,
        actions: [
          if (conv.phone != null)
            IconButton(
              icon: const Icon(
                Icons.phone_outlined,
                color: AppColors.primaryForest,
                size: 20,
              ),
              tooltip: 'Call',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contact: ${conv!.phone}'),
                    backgroundColor: AppColors.deepForest,
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              color: AppColors.softForest.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 16,
                    color: AppColors.primaryForest,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Trip Corridor: ${conv.routeSummary}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Message Stream
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: SahyanEmptyState(
                        title: 'No messages yet',
                        description:
                            'Send a message to coordinate your carpool.',
                        icon: Icons.chat_bubble_outline,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTypography.bodyMedium,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          borderSide: const BorderSide(
                            color: AppColors.primaryForest,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          notifier.sendMessage(conv!.id, val);
                          _messageController.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryForest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      tooltip: 'Send',
                      onPressed: () {
                        final text = _messageController.text;
                        if (text.trim().isNotEmpty) {
                          notifier.sendMessage(conv!.id, text);
                          _messageController.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: msg.isMe ? AppColors.primaryForest : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.md),
            topRight: const Radius.circular(AppRadii.md),
            bottomLeft: Radius.circular(msg.isMe ? AppRadii.md : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : AppRadii.md),
          ),
          border: msg.isMe
              ? null
              : Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: AppTypography.bodyMedium.copyWith(
                color: msg.isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.timestamp),
                  style: AppTypography.caption.copyWith(
                    color: msg.isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'read'
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
