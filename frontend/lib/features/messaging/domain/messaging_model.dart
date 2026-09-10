class Conversation {
  final String id;
  final String participantName;
  final String participantRole; // 'Driver' or 'Passenger'
  final String? participantAvatar;
  final String routeSummary;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? phone;

  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantRole,
    this.participantAvatar,
    required this.routeSummary,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.phone,
  });

  Conversation copyWith({
    String? id,
    String? participantName,
    String? participantRole,
    String? participantAvatar,
    String? routeSummary,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? phone,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      participantRole: participantRole ?? this.participantRole,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      routeSummary: routeSummary ?? this.routeSummary,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      phone: phone ?? this.phone,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String status; // 'sent', 'delivered', 'read'

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.status = 'sent',
  });
}
