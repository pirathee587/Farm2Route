import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/core/localization/app_localizations.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_details_screen.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_otp_verify_screen.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_phone_entry_screen.dart';
import 'package:farm2route_app/shared/widgets/agrizel_pill_button.dart';

Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('FarmerPhoneEntryScreen Widget Tests', () {
    testWidgets('renders phone entry UI elements and country code badge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerPhoneEntryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('+94'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(AgrizelPillButton), findsOneWidget);
    });

    testWidgets('shows validation error when phone number is invalid',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerPhoneEntryScreen()));
      await tester.pumpAndSettle();

      // Enter invalid phone
      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.pumpAndSettle();

      // Tap Send OTP
      await tester.tap(find.byType(AgrizelPillButton));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.textContaining('771234567'), findsOneWidget);
    });

    testWidgets('language dropdown changes localization',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerPhoneEntryScreen()));
      await tester.pumpAndSettle();

      // Initially default is Tamil
      expect(find.text('விவசாயி பதிவு'), findsOneWidget);

      // Tap dropdown to change language to English
      await tester.tap(find.byType(DropdownButton<AppLanguage>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      // English label should now be visible
      expect(find.text('Farmer Sign Up'), findsOneWidget);
    });
  });

  group('FarmerOtpVerifyScreen Widget Tests', () {
    testWidgets('renders 6 digit input fields and resend timer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerOtpVerifyScreen()));
      await tester.pumpAndSettle();

      // 6 digit text fields
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.byType(AgrizelPillButton), findsOneWidget);
      expect(find.textContaining('30s'), findsOneWidget);
    });
  });

  group('FarmerDetailsScreen Widget Tests', () {
    testWidgets('renders form fields: name, district, location, farm size, crops',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerDetailsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Basic Profile'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(5));
      expect(find.byType(AgrizelPillButton), findsOneWidget);
    });

    testWidgets('shows validation error when full name is empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerDetailsScreen()));
      await tester.pumpAndSettle();

      // Scroll to and tap Complete Signup without entering name
      final submitButton = find.byType(AgrizelPillButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('தேவை'), findsWidgets); // Tamil default required error
    });

    testWidgets('crop multi-select chips can be toggled',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const FarmerDetailsScreen()));
      await tester.pumpAndSettle();

      // Fruits chip
      final fruitsChip = find.widgetWithText(FilterChip, 'பழங்கள்');
      await tester.ensureVisible(fruitsChip);

      // Initially Vegetables is selected, Fruits is not
      FilterChip chipWidget = tester.widget<FilterChip>(fruitsChip);
      expect(chipWidget.selected, isFalse);

      // Tap to select Fruits
      await tester.tap(fruitsChip);
      await tester.pumpAndSettle();

      chipWidget = tester.widget<FilterChip>(fruitsChip);
      expect(chipWidget.selected, isTrue);

      // Tap again to deselect
      await tester.tap(fruitsChip);
      await tester.pumpAndSettle();

      chipWidget = tester.widget<FilterChip>(fruitsChip);
      expect(chipWidget.selected, isFalse);
    });
  });
}
