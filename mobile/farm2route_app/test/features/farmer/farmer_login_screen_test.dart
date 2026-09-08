import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_login_screen.dart';
import 'package:farm2route_app/shared/widgets/agrizel_pill_button.dart';
import 'package:farm2route_app/shared/widgets/farm2route_logo.dart';

Widget createLoginTestApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: FarmerLoginScreen(),
    ),
  );
}

void main() {
  group('FarmerLoginScreen Widget Tests', () {
    testWidgets('renders phone entry UI, logo, and Send OTP CTA',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLoginTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(Farm2RouteLogo), findsOneWidget);
      expect(find.text('+94'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(AgrizelPillButton), findsOneWidget);
    });

    testWidgets('validates invalid phone number before sending OTP',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLoginTestApp());
      await tester.pumpAndSettle();

      // Enter invalid phone
      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.pumpAndSettle();

      // Tap Send OTP
      await tester.tap(find.byType(AgrizelPillButton));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.textContaining('771234567'), findsOneWidget);
    });
  });
}
