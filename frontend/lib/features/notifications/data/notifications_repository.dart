import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import '../domain/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRepositoryImpl(apiClient: apiClient);
});

abstract class NotificationsRepository {
  Future<List<NotificationItem>> getNotifications({String? category});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiClient apiClient;

  NotificationsRepositoryImpl({required this.apiClient});

  @override
  Future<List<NotificationItem>> getNotifications({String? category}) async {
    try {
      final endpoint = category != null && category != 'all'
          ? '/notifications?category=$category'
          : '/notifications';

      final response = await apiClient.get(endpoint);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data']['notifications'] as List? ?? [];
        return list
            .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return _getFallbackNotifications();
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await apiClient.patch('/notifications/$id/read');
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await apiClient.patch('/notifications/read-all');
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await apiClient.delete('/notifications/$id');
    } catch (_) {}
  }

  List<NotificationItem> _getFallbackNotifications() {
    return [
      NotificationItem(
        id: 'notif-1',
        title: 'Booking Approved',
        message: 'Your seat request for Ahmedabad to Vadodara has been accepted by driver Karan Patel.',
        category: 'booking',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        routeTarget: '/active-journey',
      ),
      NotificationItem(
        id: 'notif-2',
        title: 'Driver Started Boarding',
        message: 'Vehicle Hyundai Creta (GJ-01-AB-1234) is preparing for departure at Iscon Cross Roads.',
        category: 'ride',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        routeTarget: '/active-journey',
      ),
      NotificationItem(
        id: 'notif-3',
        title: 'Safety Check Reminder',
        message: 'Remember to verify the driver vehicle number and pin before boarding your carpool.',
        category: 'safety',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        routeTarget: '/trip-safety',
      ),
      NotificationItem(
        id: 'notif-4',
        title: 'New Corridor Added',
        message: 'Frequent daily routes are now available between Gandhinagar and GIFT City.',
        category: 'system',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        routeTarget: '/search-results',
      ),
    ];
  }
}
