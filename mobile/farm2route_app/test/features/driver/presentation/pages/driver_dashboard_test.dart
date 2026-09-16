import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farm2route_app/features/driver/presentation/pages/driver_dashboard_page.dart';

void main() {
  testWidgets('DriverDashboardPage renders and opens route incident modal sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DriverDashboardPage(),
        ),
      ),
    );

    expect(find.text('Encountered an Issue on Route?'), findsOneWidget);

    final issueButtonFinder = find.byKey(const Key('btn_encountered_issue'));
    final scrollFinder = find.byType(SingleChildScrollView);

    // Scroll card into view
    await tester.dragUntilVisible(
      issueButtonFinder,
      scrollFinder,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    // Tap on the Encountered an Issue on Route card
    await tester.tap(issueButtonFinder);
    await tester.pumpAndSettle();

    // Verify modal sheet opens
    expect(find.text('Report Route Incident / Delay'), findsOneWidget);
    expect(find.text('Log Incident & Notify Agency'), findsOneWidget);

    // Tap submit incident button inside modal
    await tester.tap(find.byKey(const Key('btn_submit_route_incident')));
    await tester.pumpAndSettle();

    // Verify modal closes and snackbar appears safely
    expect(find.text('Report Route Incident / Delay'), findsNothing);
    expect(find.text('Incident logged! Agency dispatch has been notified.'), findsOneWidget);
  });
}
