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
}
