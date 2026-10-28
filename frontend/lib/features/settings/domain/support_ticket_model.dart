class TicketMessageModel {
  final String id;
  final String sender;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  const TicketMessageModel({
    required this.id,
    required this.sender,
    required this.senderName,
    this.senderRole = 'user',
    required this.message,
    required this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: json['_id']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'user',
      senderName: json['senderName']?.toString() ?? 'Member',
      senderRole: json['senderRole']?.toString() ?? 'user',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String category;
  final String priority;
  final String status;
  final String subject;
  final String description;
  final String? bookingId;
  final String? bookingPickup;
  final String? bookingDrop;
  final List<TicketMessageModel> messages;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.category,
    required this.priority,
    required this.status,
    required this.subject,
    required this.description,
    this.bookingId,
    this.bookingPickup,
    this.bookingDrop,
    this.messages = const [],
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final bookingObj = json['booking'];
    String? bId;
    String? bPickup;
    String? bDrop;

    if (bookingObj is Map<String, dynamic>) {
      bId = bookingObj['_id']?.toString();
      bPickup = bookingObj['pickup']?['name']?.toString() ??
          bookingObj['pickupAddress']?.toString() ??
          bookingObj['origin']?['address']?.toString();
      bDrop = bookingObj['drop']?['name']?.toString() ??
          bookingObj['dropoffAddress']?.toString() ??
          bookingObj['destination']?['address']?.toString();
    } else if (bookingObj != null) {
      bId = bookingObj.toString();
    }

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final parsedMessages = rawMessages
        .map((m) => TicketMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return SupportTicketModel(
      id: json['_id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'open',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      bookingId: bId,
      bookingPickup: bPickup,
      bookingDrop: bDrop,
      messages: parsedMessages,
      resolutionNotes: json['resolutionNotes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
