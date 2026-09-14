class Conversation {
  final String id;
  final String? bookingId;
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
    this.bookingId,
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
    String? bookingId,
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
      bookingId: bookingId ?? this.bookingId,
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

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? json['booking'] as String?,
      participantName: json['participantName'] as String? ?? 'Travel Partner',
      participantRole: json['participantRole'] as String? ?? 'Driver',
      participantAvatar: json['participantAvatar'] as String?,
      routeSummary: json['routeSummary'] as String? ?? 'Highway Corridor',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'participantName': participantName,
      'participantRole': participantRole,
      'participantAvatar': participantAvatar,
      'routeSummary': routeSummary,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'phone': phone,
    };
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

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderObj = json['sender'];
    final senderId = senderObj is Map ? (senderObj['_id'] ?? senderObj['id'] ?? '') : (senderObj?.toString() ?? '');
    final isMe = currentUserId != null && senderId == currentUserId;
    final readAt = json['readAt'];

    return ChatMessage(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      conversationId: (json['booking'] ?? json['conversationId'] ?? '').toString(),
      senderId: senderId.toString(),
      text: json['text'] as String? ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMe: isMe,
      status: readAt != null ? 'read' : 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe,
      'status': status,
    };
  }
}
