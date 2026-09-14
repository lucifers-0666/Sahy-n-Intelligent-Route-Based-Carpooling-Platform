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

  static const List<String> _quickResponses = [
    'I have reached the pickup point',
    'Running 5 mins late',
    'Where are you waiting?',
    'On my way!',
    'Vehicle verified & ready',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final targetId = widget.initialConversation?.id ?? widget.conversationId;
      if (targetId != null) {
        ref.read(messagingProvider.notifier).loadMessages(targetId);
        ref.read(messagingProvider.notifier).markAsRead(targetId);
      }
    });
  }

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

  void _handleSend(String convId, String text) {
    if (text.trim().isEmpty) return;
    ref.read(messagingProvider.notifier).sendMessage(convId, text.trim());
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);

    // Resolve conversation
    Conversation? conv = widget.initialConversation;
    if (conv == null && widget.conversationId != null) {
      final matches = state.conversations
          .where((c) => c.id == widget.conversationId || c.bookingId == widget.conversationId)
          .toList();
      if (matches.isNotEmpty) {
        conv = matches.first;
      }
    }

    if (conv == null) {
      // Create ad-hoc conversation context if opened with a specific conversation/booking ID
      final adHocId = widget.conversationId ?? 'active-booking';
      conv = Conversation(
        id: adHocId,
        bookingId: adHocId,
        participantName: 'Carpool Partner',
        participantRole: 'Trip Contact',
        routeSummary: 'Active Corridor Journey',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
    }

    final messages = state.messages[conv.id] ?? state.messages[conv.bookingId ?? ''] ?? [];

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: conv.participantName,
        subtitle: '${conv.participantRole} • ${conv.routeSummary}',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.phone_outlined,
              color: AppColors.primaryForest,
              size: 20,
            ),
            tooltip: 'Call',
            onPressed: () {
              final phoneToCall = conv!.phone ?? '+91 98765 43210';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${conv.participantName} ($phoneToCall)...'),
                  backgroundColor: AppColors.deepForest,
                  duration: const Duration(seconds: 2),
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
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.softForest.withValues(alpha: 0.4),
                border: const Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation_outlined,
                      size: 14,
                      color: AppColors.primaryForest,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Trip Corridor: ${conv.routeSummary}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 11, color: SahyanColors.primaryMint),
                        const SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryForest,
                          ),
                        ),
                      ],
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
                            'Coordinate pickup location, time, or luggage with ${conv.participantName}.',
                        icon: Icons.chat_bubble_outline,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // Quick Preset Response Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: _quickResponses.map((text) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _handleSend(conv!.id, text),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.softForest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.flash_on_rounded,
                                size: 12,
                                color: SahyanColors.primaryMint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                text,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.8),
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
                        filled: true,
                        fillColor: AppColors.warmBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.primaryForest,
                            width: 1.2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (val) => _handleSend(conv!.id, val),
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
                      onPressed: () => _handleSend(conv!.id, _messageController.text),
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
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: msg.isMe ? AppColors.primaryForest : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          border: msg.isMe
              ? null
              : Border.all(color: AppColors.border, width: 0.8),
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
