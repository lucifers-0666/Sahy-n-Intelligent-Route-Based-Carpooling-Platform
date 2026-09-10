import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/notification_model.dart';

class NotificationsState {
  final List<NotificationItem> items;
  final String activeFilter; // 'all', 'booking', 'ride', 'safety'
  final bool isLoading;

  const NotificationsState({
    required this.items,
    this.activeFilter = 'all',
    this.isLoading = false,
  });

  List<NotificationItem> get filteredItems {
    if (activeFilter == 'all') return items;
    return items.where((n) => n.category == activeFilter).toList();
  }

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    String? activeFilter,
    bool? isLoading,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier()
    : super(
        NotificationsState(
          items: [
            NotificationItem(
              id: 'notif-1',
              title: 'Booking Confirmed',
              message:
                  'Your seat request for Ahmedabad to Vadodara has been accepted by driver Karan Patel.',
              category: 'booking',
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              routeTarget: '/active-journey',
            ),
            NotificationItem(
              id: 'notif-2',
              title: 'Driver Started Boarding',
              message:
                  'Vehicle Hyundai Creta (GJ-01-AB-1234) is preparing for departure at Iscon Cross Roads.',
              category: 'ride',
              timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              routeTarget: '/active-journey',
            ),
            NotificationItem(
              id: 'notif-3',
              title: 'Safety Check Reminder',
              message:
                  'Remember to verify the driver vehicle number and pin before boarding your carpool.',
              category: 'safety',
              timestamp: DateTime.now().subtract(const Duration(hours: 4)),
              routeTarget: '/trip-safety',
            ),
            NotificationItem(
              id: 'notif-4',
              title: 'New Corridor Added',
              message:
                  'Frequent daily routes are now available between Gandhinagar and GIFT City.',
              category: 'system',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              isRead: true,
              routeTarget: '/search-results',
            ),
          ],
        ),
      );

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void markAsRead(String id) {
    final updated = state.items.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void markAllAsRead() {
    final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated);
  }

  void clearAll() {
    state = state.copyWith(items: []);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier();
    });
