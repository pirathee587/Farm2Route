import 'package:farm2route_app/features/admin/presentation/widgets/incident_resolve_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IncidentResolveDialog: status radio required (default RESOLVED), refund amount optional', (WidgetTester tester) async {
    String? capturedStatus;
    String? capturedNotes;
    double? capturedRefund;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentResolveDialog(
            incidentId: 'inc-101',
            onResolve: (status, notes, refundAmount) async {
              capturedStatus = status;
              capturedNotes = notes;
              capturedRefund = refundAmount;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify radio buttons and fields are present
    expect(find.byKey(const Key('status_radio_resolved')), findsOneWidget);
    expect(find.byKey(const Key('status_radio_rejected')), findsOneWidget);
    expect(find.byKey(const Key('resolution_notes_field')), findsOneWidget);
    expect(find.byKey(const Key('refund_amount_field')), findsOneWidget);
    expect(find.byKey(const Key('submit_resolve_button')), findsOneWidget);

    // Enter notes without refund amount (refund amount is optional)
    await tester.enterText(find.byKey(const Key('resolution_notes_field')), 'Claim verified and settled.');
    await tester.tap(find.byKey(const Key('submit_resolve_button')));
    await tester.pumpAndSettle();

    // Verify status defaults to RESOLVED and refundAmount is null
    expect(capturedStatus, equals('RESOLVED'));
    expect(capturedNotes, equals('Claim verified and settled.'));
    expect(capturedRefund, isNull);
  });

  testWidgets('IncidentResolveDialog: select REJECTED status and enter optional refund amount', (WidgetTester tester) async {
    String? capturedStatus;
    String? capturedNotes;
    double? capturedRefund;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentResolveDialog(
            incidentId: 'inc-102',
            onResolve: (status, notes, refundAmount) async {
              capturedStatus = status;
              capturedNotes = notes;
              capturedRefund = refundAmount;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Select REJECTED radio button
    await tester.tap(find.byKey(const Key('status_radio_rejected')));
    await tester.pump();

    // Enter notes and refund amount
    await tester.enterText(find.byKey(const Key('resolution_notes_field')), 'Insufficient evidence provided');
    await tester.enterText(find.byKey(const Key('refund_amount_field')), '50.00');

    await tester.tap(find.byKey(const Key('submit_resolve_button')));
    await tester.pumpAndSettle();

    expect(capturedStatus, equals('REJECTED'));
    expect(capturedNotes, equals('Insufficient evidence provided'));
    expect(capturedRefund, equals(50.0));
  });
}
