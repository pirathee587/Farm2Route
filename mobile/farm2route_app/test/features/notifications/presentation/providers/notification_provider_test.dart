import 'package:farm2route_app/features/notifications/data/models/notification_model.dart';
import 'package:farm2route_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:farm2route_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MutableFakeNotificationRepository implements NotificationRepository {
  final List<NotificationModel> notifications;
  int unreadCount;

  MutableFakeNotificationRepository({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20}) async {
    return List.from(notifications);
  }

  @override
  Future<int> getUnreadCount() async {
    return unreadCount;
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updated = notifications[index].copyWith(read: true, readAt: DateTime.now());
      notifications[index] = updated;
      if (unreadCount > 0) unreadCount--;
      return updated;
    }
    throw Exception('Notification not found');
  }
}

void main() {
  test('markAsRead updates notification read status in list', () async {
    final initialItem = NotificationModel(
      id: 'notif-1',
      userId: 'user-1',
      title: 'Booking Confirmed',
      message: 'Your transport booking has been accepted',
      notificationType: 'BOOKING_UPDATE',
      read: false,
      createdAt: DateTime.now(),
    );

    final mockRepo = MutableFakeNotificationRepository(
      notifications: [initialItem],
      unreadCount: 1,
    );

    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    // Read provider to trigger initial fetch
    container.read(notificationsNotifierProvider);
    // Wait for microtask/async resolution
    await Future.delayed(Duration.zero);

    final initialListState = container.read(notificationsNotifierProvider);
    expect(initialListState.value?.first.read, isFalse);

    // Act: mark notification as read
    await container.read(notificationsNotifierProvider.notifier).markAsRead('notif-1');

    // Assert: state updated to read = true
    final updatedListState = container.read(notificationsNotifierProvider);
    expect(updatedListState.value?.first.read, isTrue);
  });
}
