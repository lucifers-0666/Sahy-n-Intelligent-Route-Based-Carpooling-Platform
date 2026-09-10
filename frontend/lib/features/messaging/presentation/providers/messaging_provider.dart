import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/messaging_model.dart';

class MessagingState {
  final List<Conversation> conversations;
  final Map<String, List<ChatMessage>> messages;
  final String searchQuery;
  final bool isLoading;

  const MessagingState({
    required this.conversations,
    required this.messages,
    this.searchQuery = '',
    this.isLoading = false,
  });

  List<Conversation> get filteredConversations {
    if (searchQuery.trim().isEmpty) return conversations;
    final q = searchQuery.toLowerCase();
    return conversations
        .where(
          (c) =>
              c.participantName.toLowerCase().contains(q) ||
              c.routeSummary.toLowerCase().contains(q) ||
              c.lastMessage.toLowerCase().contains(q),
        )
        .toList();
  }

  int get totalUnread => conversations.fold(0, (sum, c) => sum + c.unreadCount);

  MessagingState copyWith({
    List<Conversation>? conversations,
    Map<String, List<ChatMessage>>? messages,
    String? searchQuery,
    bool? isLoading,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  MessagingNotifier()
    : super(
        MessagingState(
          conversations: [
            Conversation(
              id: 'conv-1',
              participantName: 'Karan Patel',
              participantRole: 'Driver',
              routeSummary: 'Ahmedabad to Vadodara',
              lastMessage:
                  'I have arrived near Iscon Cross Roads service lane. Blue Creta.',
              lastMessageTime: DateTime.now().subtract(
                const Duration(minutes: 5),
              ),
              unreadCount: 1,
              phone: '+91 98765 43210',
            ),
            Conversation(
              id: 'conv-2',
              participantName: 'Priya Shah',
              participantRole: 'Passenger',
              routeSummary: 'Gandhinagar to GIFT City',
              lastMessage:
                  'Thanks for the ride today! Will book again tomorrow.',
              lastMessageTime: DateTime.now().subtract(
                const Duration(hours: 3),
              ),
              unreadCount: 0,
              phone: '+91 98123 45678',
            ),
          ],
          messages: {
            'conv-1': [
              ChatMessage(
                id: 'm-101',
                conversationId: 'conv-1',
                senderId: 'driver',
                text:
                    'Hello, please confirm if you will be at the pickup point by 08:30 AM.',
                timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
                isMe: false,
                status: 'read',
              ),
              ChatMessage(
                id: 'm-102',
                conversationId: 'conv-1',
                senderId: 'me',
                text:
                    'Yes Karan, I am 2 minutes away, walking towards the bus shelter.',
                timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
                isMe: true,
                status: 'delivered',
              ),
              ChatMessage(
                id: 'm-103',
                conversationId: 'conv-1',
                senderId: 'driver',
                text:
                    'I have arrived near Iscon Cross Roads service lane. Blue Creta.',
                timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
                isMe: false,
                status: 'delivered',
              ),
            ],
            'conv-2': [
              ChatMessage(
                id: 'm-201',
                conversationId: 'conv-2',
                senderId: 'passenger',
                text: 'Thanks for the ride today! Will book again tomorrow.',
                timestamp: DateTime.now().subtract(const Duration(hours: 3)),
                isMe: false,
                status: 'read',
              ),
            ],
          },
        ),
      );

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void markAsRead(String conversationId) {
    final updatedConvs = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: updatedConvs);
  }

  void sendMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'me',
      text: text.trim(),
      timestamp: DateTime.now(),
      isMe: true,
      status: 'sent',
    );

    final currentMessages = List<ChatMessage>.from(
      state.messages[conversationId] ?? [],
    );
    currentMessages.add(newMessage);

    final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
    updatedMessages[conversationId] = currentMessages;

    final updatedConvs = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(
          lastMessage: text.trim(),
          lastMessageTime: DateTime.now(),
        );
      }
      return c;
    }).toList();

    state = state.copyWith(
      conversations: updatedConvs,
      messages: updatedMessages,
    );
  }
}

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
      return MessagingNotifier();
    });
