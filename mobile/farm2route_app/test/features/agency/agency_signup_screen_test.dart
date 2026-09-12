import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/agency/presentation/screens/agency_signup_screen.dart';
import 'package:farm2route_app/shared/widgets/agrizel_pill_button.dart';

Widget createTestWidget() {
  return const ProviderScope(
    child: MaterialApp(
      home: AgencySignupScreen(),
    ),
  );
}

void main() {
  group('AgencySignupScreen Widget Tests', () {
    testWidgets('renders all required form fields and disabled submit button initially',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Agency Registration'), findsOneWidget);
      expect(find.text('Register Your Fleet'), findsOneWidget);

      // Verify fields
      expect(find.widgetWithText(TextFormField, 'Agency Name *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email Address *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Phone Number *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password *'), findsOneWidget);
      expect(find.text('Agency Type *'), findsOneWidget);
      expect(find.text('District *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Office Address *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contact Person Name (Optional)'), findsOneWidget);

      // Verify terms checkbox
      expect(find.byType(Checkbox), findsOneWidget);

      // Verify submit button is disabled initially
      final submitButton = tester.widget<AgrizelPillButton>(find.byType(AgrizelPillButton));
      expect(submitButton.onPressed, isNull);
    });

    testWidgets('shows validation error when password and confirm password mismatch',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter agency name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Agency Name *'), 'Lanka Freight');

      // Enter valid email
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'), 'lanka@freight.lk');

      // Enter phone
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '771234567');

      // Enter password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password *'), 'Password123!');

      // Enter mismatched confirm password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password *'), 'DifferentPassword456!');

      // Select Agency Type
      final agencyTypeDropdown = find.text('Agency Type *');
      await tester.ensureVisible(agencyTypeDropdown);
      await tester.tap(agencyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registered Company').last);
      await tester.pumpAndSettle();

      // Select District
      final districtDropdown = find.text('District *');
      await tester.ensureVisible(districtDropdown);
      await tester.tap(districtDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombo').last);
      await tester.pumpAndSettle();

      // Enter Address
      final addressField = find.widgetWithText(TextFormField, 'Office Address *');
      await tester.ensureVisible(addressField);
      await tester.enterText(addressField, '45 Harbour Road, Colombo');

      // Check Terms checkbox
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Now submit button should be enabled
      final submitButtonFinder = find.byType(AgrizelPillButton);
      await tester.ensureVisible(submitButtonFinder);
      final submitButton = tester.widget<AgrizelPillButton>(submitButtonFinder);
      expect(submitButton.onPressed, isNotNull);

      // Tap submit button to trigger validators
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // Mismatch error message should appear
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows validation error when email format is invalid',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter agency name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Agency Name *'), 'Lanka Freight');

      // Enter invalid email
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'), 'not-an-email');

      // Enter phone
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '771234567');

      // Enter password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password *'), 'Password123!');

      // Enter matching confirm password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password *'), 'Password123!');

      // Select Agency Type
      final agencyTypeDropdown = find.text('Agency Type *');
      await tester.ensureVisible(agencyTypeDropdown);
      await tester.tap(agencyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registered Company').last);
      await tester.pumpAndSettle();

      // Select District
      final districtDropdown = find.text('District *');
      await tester.ensureVisible(districtDropdown);
      await tester.tap(districtDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombo').last);
      await tester.pumpAndSettle();

      // Enter Address
      final addressField = find.widgetWithText(TextFormField, 'Office Address *');
      await tester.ensureVisible(addressField);
      await tester.enterText(addressField, '45 Harbour Road, Colombo');

      // Check Terms checkbox
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Tap submit button to trigger validators
      final submitButtonFinder = find.byType(AgrizelPillButton);
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // Invalid email error message should appear
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows validation error when password is under 8 characters',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Agency Name *'), 'Lanka Freight');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'), 'agency@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '771234567');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password *'), 'short');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password *'), 'short');

      // Select Agency Type
      final agencyTypeDropdown = find.text('Agency Type *');
      await tester.ensureVisible(agencyTypeDropdown);
      await tester.tap(agencyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Individual Owner-Operator').last);
      await tester.pumpAndSettle();

      // Select District
      final districtDropdown = find.text('District *');
      await tester.ensureVisible(districtDropdown);
      await tester.tap(districtDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gampaha').last);
      await tester.pumpAndSettle();

      final addressField = find.widgetWithText(TextFormField, 'Office Address *');
      await tester.ensureVisible(addressField);
      await tester.enterText(addressField, '12 Kandy Road, Gampaha');

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final submitButtonFinder = find.byType(AgrizelPillButton);
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('keeps submit button disabled if terms checkbox is not checked',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill all fields but do NOT check terms
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Agency Name *'), 'Lanka Freight');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'), 'agency@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '771234567');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password *'), 'Password123!');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password *'), 'Password123!');

      final agencyTypeDropdown = find.text('Agency Type *');
      await tester.ensureVisible(agencyTypeDropdown);
      await tester.tap(agencyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Individual Owner-Operator').last);
      await tester.pumpAndSettle();

      final districtDropdown = find.text('District *');
      await tester.ensureVisible(districtDropdown);
      await tester.tap(districtDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombo').last);
      await tester.pumpAndSettle();

      final addressField = find.widgetWithText(TextFormField, 'Office Address *');
      await tester.ensureVisible(addressField);
      await tester.enterText(addressField, '12 Kandy Road, Colombo');
      await tester.pumpAndSettle();

      // Submit button should still be disabled because terms are not checked
      final submitButtonFinder = find.byType(AgrizelPillButton);
      await tester.ensureVisible(submitButtonFinder);
      final submitButton = tester.widget<AgrizelPillButton>(submitButtonFinder);
      expect(submitButton.onPressed, isNull);
    });
  });
}
