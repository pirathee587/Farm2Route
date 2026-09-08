import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farm2route_app/app/router/route_names.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_landing_screen.dart';
import 'package:farm2route_app/shared/widgets/agrizel_pill_button.dart';
import 'package:farm2route_app/shared/widgets/farm2route_logo.dart';

Widget createLandingTestApp({
  String initialLocation = RouteNames.farmerLanding,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.farmerLanding,
        builder: (context, state) => const FarmerLandingScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerPhoneEntry,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Farmer Phone Entry Screen Target')),
        ),
      ),
      GoRoute(
        path: RouteNames.farmerLogin,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Farmer Login Screen Target')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('FarmerLandingScreen Widget Tests', () {
    testWidgets('renders hero visual, brand logo, headline, tagline, and CTAs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Brand Logo mark
      expect(find.byType(Farm2RouteLogo), findsOneWidget);

      // Agri-Logistics hero icons
      expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_rounded), findsOneWidget);

      // Primary & Secondary CTA buttons
      expect(find.byType(AgrizelPillButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);

      // Language selector button exists
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    });

    testWidgets('tapping "Get Started" CTA navigates to farmer phone entry screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Find and tap the primary CTA button
      final getStartedButton = find.byType(AgrizelPillButton);
      expect(getStartedButton, findsOneWidget);
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Verify navigation to phone entry screen
      expect(find.text('Farmer Phone Entry Screen Target'), findsOneWidget);
    });

    testWidgets('tapping "I already have an account" CTA navigates to farmer login screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Find and tap the secondary CTA button
      final loginButton = find.byType(OutlinedButton);
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify navigation to farmer login screen
      expect(find.text('Farmer Login Screen Target'), findsOneWidget);
    });

    testWidgets('language selector bottom sheet opens and switches language',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Initial default language is Tamil per project convention
      expect(find.text('தொடங்குங்கள்'), findsOneWidget);

      // Tap language selector
      final langButton = find.byIcon(Icons.language_rounded);
      await tester.tap(langButton);
      await tester.pumpAndSettle();

      // Bottom sheet should now be visible with language options
      expect(find.text('English'), findsOneWidget);
      expect(find.text('සිංහල'), findsOneWidget);
      expect(find.text('தமிழ்'), findsWidgets);

      // Tap English option
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // English headline and CTA should now be rendered
      expect(find.text('Welcome to Farm2Route'), findsOneWidget);
      expect(find.text('Get your harvest to market, faster.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
