import 'package:farm2route_app/features/notifications/data/models/notification_model.dart';
import 'package:farm2route_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:farm2route_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:farm2route_app/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationRepository implements NotificationRepository {
  final int unreadCount;
  final List<NotificationModel> notifications;

  FakeNotificationRepository({
    this.unreadCount = 0,
    this.notifications = const [],
  });

  @override
  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20}) async {
    return notifications;
  }

  @override
  Future<int> getUnreadCount() async {
    return unreadCount;
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    return NotificationModel(
      id: id,
      userId: 'user1',
      title: 'Test',
      message: 'Test message',
      notificationType: 'SYSTEM',
      read: true,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('shows correct badge count when unreadCount > 0', (WidgetTester tester) async {
    final mockRepo = FakeNotificationRepository(unreadCount: 5);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: NotificationBell(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_badge')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('hides badge when unreadCount is 0', (WidgetTester tester) async {
    final mockRepo = FakeNotificationRepository(unreadCount: 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: NotificationBell(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_badge')), findsNothing);
    expect(find.byKey(const Key('notification_bell_icon')), findsOneWidget);
  });
}
