import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farm2route_app/features/farmer/presentation/pages/pod_review_page.dart';
import 'package:farm2route_app/shared/models/pod_model.dart';

void main() {
  final samplePendingPod = PodModel(
    id: 'pod-101',
    bookingId: 'F2R-8849-LK',
    bookingNumber: 'F2R-8849-LK',
    driverName: 'Kamal Silva',
    recipientName: 'Sunil Wickrama',
    recipientPhone: '+94771234567',
    deliveryPhotoUrl: 'https://example.com/photo.jpg',
    recipientSignatureUrl: 'https://example.com/sig.png',
    deliveryLatitude: 6.9271,
    deliveryLongitude: 79.8612,
    deliveryTimestamp: DateTime(2026, 9, 16, 10, 30),
    farmerConfirmationStatus: 'PENDING',
  );

  final sampleConfirmedPod = PodModel(
    id: 'pod-102',
    bookingId: 'F2R-7721-LK',
    recipientName: 'Anura Perera',
    recipientPhone: '+94719876543',
    farmerConfirmationStatus: 'CONFIRMED',
    farmerConfirmedAt: DateTime(2026, 9, 16, 11, 00),
    notes: 'All items in pristine condition',
  );

  final sampleDisputedPod = PodModel(
    id: 'pod-103',
    bookingId: 'F2R-6512-LK',
    recipientName: 'Nimal Jayasuriya',
    recipientPhone: '+94723334444',
    farmerConfirmationStatus: 'DISPUTED',
    notes: 'Boxes water damaged during transport',
  );

  Widget createWidgetUnderTest(PodModel pod) {
    return ProviderScope(
      child: MaterialApp(
        home: PodReviewPage(
          bookingId: pod.bookingId,
          initialPod: pod,
        ),
      ),
    );
  }

  group('PodReviewPage Widget Tests', () {
    testWidgets('CONFIRMED path does not require notes text before enabling submit button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(samplePendingPod));
      await tester.pumpAndSettle();

      // Verify recipient details rendered
      expect(find.text('Sunil Wickrama'), findsOneWidget);

      // Verify radio option for Confirm Delivery is selected by default
      final submitBtnFinder = find.byKey(const Key('btn_submit_pod_decision'));
      expect(submitBtnFinder, findsOneWidget);

      // Verify submit button is ENABLED immediately without notes
      final ElevatedButton buttonWidget = tester.widget(submitBtnFinder);
      expect(buttonWidget.onPressed, isNotNull);
      expect(buttonWidget.enabled, isTrue);
    });

    testWidgets('DISPUTED path requires notes text before submit button enables',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(samplePendingPod));
      await tester.pumpAndSettle();

      final radioDisputeFinder = find.byKey(const Key('radio_report_problem'));
      expect(radioDisputeFinder, findsOneWidget);

      // Scroll into view and select "Report a Problem (Dispute)"
      await tester.ensureVisible(radioDisputeFinder);
      await tester.tap(radioDisputeFinder);
      await tester.pumpAndSettle();

      // Verify notes textfield appears
      final notesFieldFinder = find.byKey(const Key('field_dispute_notes'));
      expect(notesFieldFinder, findsOneWidget);

      // Verify submit button is now DISABLED because notes field is empty
      final submitBtnFinder = find.byKey(const Key('btn_submit_pod_decision'));
      ElevatedButton buttonWidget = tester.widget(submitBtnFinder);
      expect(buttonWidget.onPressed, isNull);

      // Enter notes explaining the problem
      await tester.ensureVisible(notesFieldFinder);
      await tester.enterText(notesFieldFinder, '2 crates of tomatoes crushed during transit');
      await tester.pumpAndSettle();

      // Verify submit button is now ENABLED
      buttonWidget = tester.widget(submitBtnFinder);
      expect(buttonWidget.onPressed, isNotNull);
      expect(buttonWidget.enabled, isTrue);
    });

    testWidgets('Renders read-only status banner and hides action buttons if already CONFIRMED',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleConfirmedPod));
      await tester.pumpAndSettle();

      // Read-only status title should appear
      expect(find.text('Delivery Confirmed'), findsOneWidget);
      expect(find.text('All items in pristine condition'), findsOneWidget);

      // Radio options and Submit button should NOT exist
      expect(find.byKey(const Key('radio_confirm_delivery')), findsNothing);
      expect(find.byKey(const Key('radio_report_problem')), findsNothing);
      expect(find.byKey(const Key('btn_submit_pod_decision')), findsNothing);
    });

    testWidgets('Renders read-only status banner if already DISPUTED',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleDisputedPod));
      await tester.pumpAndSettle();

      // Read-only status title for disputed delivery
      expect(find.text('Delivery Disputed'), findsOneWidget);
      expect(find.text('Boxes water damaged during transport'), findsOneWidget);

      // Action buttons should NOT exist
      expect(find.byKey(const Key('btn_submit_pod_decision')), findsNothing);
    });
  });
}
