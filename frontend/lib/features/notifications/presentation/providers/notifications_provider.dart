import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
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
  final NotificationsRepository? repository;

  NotificationsNotifier({this.repository})
      : super(
          NotificationsState(
            items: [
              NotificationItem(
                id: 'notif-1',
                title: 'Booking Approved',
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
        ) {
    if (repository != null) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    if (repository == null) return;
    try {
      final notifs = await repository!.getNotifications(category: state.activeFilter);
      if (notifs.isNotEmpty) {
        state = state.copyWith(items: notifs);
      }
    } catch (_) {}
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
    fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    final updated = state.items.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(items: updated);

    if (repository != null) {
      try {
        await repository!.markAsRead(id);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated);

    if (repository != null) {
      try {
        await repository!.markAllAsRead();
      } catch (_) {}
    }
  }

  Future<void> dismissNotification(String id) async {
    final updated = state.items.where((n) => n.id != id).toList();
    state = state.copyWith(items: updated);

    if (repository != null) {
      try {
        await repository!.deleteNotification(id);
      } catch (_) {}
    }
  }

  void clearAll() {
    state = state.copyWith(items: []);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationsNotifier(repository: repo);
});
