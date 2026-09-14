class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String category; // 'booking', 'ride', 'safety', 'system'
  final DateTime timestamp;
  final bool isRead;
  final String? routeTarget;
  final Map<String, dynamic>? routeParams;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.routeTarget,
    this.routeParams,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    DateTime? timestamp,
    bool? isRead,
    String? routeTarget,
    Map<String, dynamic>? routeParams,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      routeTarget: routeTarget ?? this.routeTarget,
      routeParams: routeParams ?? this.routeParams,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      routeTarget: json['routeTarget'] as String?,
      routeParams: json['routeParams'] is Map<String, dynamic>
          ? json['routeParams'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'routeTarget': routeTarget,
      'routeParams': routeParams,
    };
  }
}
