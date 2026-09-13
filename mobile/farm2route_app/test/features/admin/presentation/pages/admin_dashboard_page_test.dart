import 'package:farm2route_app/app/router/route_names.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:farm2route_app/features/notifications/data/models/notification_model.dart';
import 'package:farm2route_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:farm2route_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20}) async => [];
  @override
  Future<int> getUnreadCount() async => 0;
  @override
  Future<NotificationModel> markAsRead(String id) async => throw UnimplementedError();
}

void main() {
  const fakeStats = AdminStatsModel(
    totalUsers: 1737,
    totalFarmers: 1240,
    totalAgencies: 85,
    totalDrivers: 412,
    pendingKycs: 5,
    activeBookings: 18,
    openIncidents: 1,
  );

  testWidgets('renders metric card numbers from mocked AdminStatsModel', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminStatsProvider.overrideWith((ref) async => fakeStats),
          notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
        ],
        child: const MaterialApp(
          home: AdminDashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metric_Farmers')), findsOneWidget);
    expect(find.text('1240'), findsOneWidget);

    expect(find.byKey(const Key('metric_Agencies')), findsOneWidget);
    expect(find.text('85'), findsOneWidget);

    expect(find.byKey(const Key('metric_Drivers')), findsOneWidget);
    expect(find.text('412'), findsOneWidget);

    expect(find.text('5 NEW'), findsOneWidget);
    expect(find.text('1 ACTION'), findsOneWidget);
  });

  testWidgets('tapping KYC card and Incidents card navigates to respective routes', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.adminHome,
      routes: [
        GoRoute(
          path: RouteNames.adminHome,
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: RouteNames.adminKyc,
          builder: (context, state) => const Scaffold(body: Text('Admin KYC Queue Page')),
        ),
        GoRoute(
          path: RouteNames.adminIncidents,
          builder: (context, state) => const Scaffold(body: Text('Admin Incidents Moderation Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminStatsProvider.overrideWith((ref) async => fakeStats),
          notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap KYC card
    await tester.tap(find.byKey(const Key('kyc_action_card')));
    await tester.pumpAndSettle();

    expect(find.text('Admin KYC Queue Page'), findsOneWidget);

    // Navigate back to dashboard
    router.go(RouteNames.adminHome);
    await tester.pumpAndSettle();

    // Tap Incidents card
    await tester.tap(find.byKey(const Key('incidents_action_card')));
    await tester.pumpAndSettle();

    expect(find.text('Admin Incidents Moderation Page'), findsOneWidget);
  });
}
