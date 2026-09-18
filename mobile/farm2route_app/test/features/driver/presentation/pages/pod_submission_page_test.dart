import 'dart:typed_data';

import 'package:farm2route_app/features/driver/presentation/pages/pod_submission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: PodSubmissionPage(bookingId: 'book-8842'),
      ),
    );
  }

  testWidgets('submit button is disabled until recipient name, phone, signature, and photo are all present', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final submitBtnFinder = find.byKey(const Key('pod_submit_btn'));
    expect(submitBtnFinder, findsOneWidget);

    // Verify submit button is disabled initially
    var elevatedButton = tester.widget<ElevatedButton>(
      find.descendant(of: submitBtnFinder, matching: find.byType(ElevatedButton)),
    );
    expect(elevatedButton.onPressed, isNull);

    // Enter recipient name
    await tester.enterText(find.byKey(const Key('pod_recipient_name_input')), 'Sunil Shantha');
    await tester.pumpAndSettle();

    elevatedButton = tester.widget<ElevatedButton>(
      find.descendant(of: submitBtnFinder, matching: find.byType(ElevatedButton)),
    );
    expect(elevatedButton.onPressed, isNull);

    // Enter recipient phone
    await tester.enterText(find.byKey(const Key('pod_recipient_phone_input')), '+94771234567');
    await tester.pumpAndSettle();

    elevatedButton = tester.widget<ElevatedButton>(
      find.descendant(of: submitBtnFinder, matching: find.byType(ElevatedButton)),
    );
    expect(elevatedButton.onPressed, isNull);

    final kTransparentPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ]);

    // Simulate populating signature bytes and photo bytes on state
    final state = tester.state(find.byType(PodSubmissionPage));
    (state as dynamic).setTestBytes(
      signatureBytes: kTransparentPng,
      photoBytes: kTransparentPng,
    );
    await tester.pumpAndSettle();

    // Verify submit button is now ENABLED
    elevatedButton = tester.widget<ElevatedButton>(
      find.descendant(of: submitBtnFinder, matching: find.byType(ElevatedButton)),
    );
    expect(elevatedButton.onPressed, isNotNull);
  });
}
