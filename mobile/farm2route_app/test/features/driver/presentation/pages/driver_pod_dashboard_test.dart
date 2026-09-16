import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farm2route_app/features/driver/presentation/pages/driver_pod_dashboard_page.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: DriverPodDashboardPage(),
      ),
    );
  }

  group('DriverPodDashboardPage Widget Tests', () {
    testWidgets('renders title, metric cards, and active haul spotlight',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Driver POD Hub'), findsOneWidget);

      // Metrics
      expect(find.text('14'), findsOneWidget);
      expect(find.text('PODs Uploaded'), findsOneWidget);
      expect(find.text('Farmer Confirmed'), findsWidgets);
      expect(find.text('Disputed'), findsOneWidget);

      // Active haul spotlight
      expect(find.text('DELIVERY PENDING POD'), findsOneWidget);
      expect(find.text('3.5 Tons Fresh Cabbage'), findsWidgets);
      expect(find.byKey(const Key('btn_submit_active_pod')), findsOneWidget);
    });

    testWidgets('renders recent POD submissions list with status badges',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Recent submissions section header
      expect(find.text('Recent POD Submissions'), findsOneWidget);

      // Status badges
      expect(find.text('POD Pending Submission'), findsOneWidget);
      expect(find.text('Delivered & Verified'), findsOneWidget);
      expect(find.text('Disputed by Farmer'), findsOneWidget);
    });
  });
}
