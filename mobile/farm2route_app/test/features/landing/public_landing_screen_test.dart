import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farm2route_app/features/landing/data/models/transport_package_model.dart';
import 'package:farm2route_app/features/landing/domain/repositories/landing_repository.dart';
import 'package:farm2route_app/features/landing/presentation/providers/landing_providers.dart';
import 'package:farm2route_app/features/landing/presentation/screens/public_landing_screen.dart';
import 'package:farm2route_app/features/landing/presentation/widgets/landing_top_bar.dart';
import 'package:farm2route_app/features/landing/data/models/featured_promo_model.dart';
import 'package:farm2route_app/features/landing/data/models/agro_agency_model.dart';

class TestLandingRepository implements LandingRepository {
  final List<TransportPackageModel> packages = [
    const TransportPackageModel(
      id: 'pkg-1',
      agencyName: 'Central Agro Hub',
      rating: 4.8,
      reviewCount: 120,
      pickupLocation: 'Dambulla',
      deliveryMarket: 'Manning Wholesale Market, Colombo',
      pricePerKg: 15.0,
      vehicleType: 'Bulk Cargo Truck',
      maxWeightKg: 5000,
      availableTrucks: 24,
      distanceKm: 12.0,
      status: 'ACTIVE',
      category: 'Bulk Cargo',
      hasOffer: true,
      offerLabel: '20% OFF',
    ),
    const TransportPackageModel(
      id: 'pkg-2',
      agencyName: 'Northern Agro Logistics',
      rating: 4.7,
      reviewCount: 95,
      pickupLocation: 'Jaffna',
      deliveryMarket: 'Colombo Wholesale Market',
      pricePerKg: 18.0,
      vehicleType: 'Harvest Transport Truck',
      maxWeightKg: 3000,
      availableTrucks: 8,
      distanceKm: 5.0,
      status: 'ACTIVE',
      category: 'Harvest Transport',
      hasOffer: true,
      offerLabel: 'LKR 150 OFF',
    ),
    const TransportPackageModel(
      id: 'pkg-3',
      agencyName: 'Green Farm Transport',
      rating: 4.9,
      reviewCount: 180,
      pickupLocation: 'Vavuniya',
      deliveryMarket: 'Kandy Market',
      pricePerKg: 14.0,
      vehicleType: 'Refrigerated Truck',
      maxWeightKg: 2000,
      availableTrucks: 12,
      distanceKm: 8.0,
      status: 'ACTIVE',
      category: 'Refrigerated',
      hasOffer: false,
    ),
    const TransportPackageModel(
      id: 'pkg-inactive-demo',
      agencyName: 'Inactive Discarded Fleet',
      rating: 3.0,
      reviewCount: 5,
      pickupLocation: 'Colombo',
      deliveryMarket: 'Galle',
      pricePerKg: 30.0,
      vehicleType: 'Flatbed',
      maxWeightKg: 1000,
      availableTrucks: 0,
      distanceKm: 40.0,
      status: 'INACTIVE',
      category: 'Bulk Cargo',
    ),
  ];

  @override
  Future<List<TransportPackageModel>> getActivePackages({
    String? category,
    String? district,
    String? produceType,
    double? maxPrice,
    bool? offersOnly,
  }) async {
    var list = packages.where((p) => p.status == 'ACTIVE').toList();
    if (category != null && category != 'All') {
      list = list.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (offersOnly == true) {
      list = list.where((p) => p.hasOffer).toList();
    }
    return list;
  }

  @override
  Future<List<FeaturedPromoModel>> getFeaturedPromos() async {
    return [
      const FeaturedPromoModel(
        id: 'promo-1',
        title: '20% OFF Your First Transport',
        ribbonBadge: '20% OFF',
        agencyName: 'Central Agro Hub',
        rating: 4.8,
        reviewsCount: 120,
        availabilityTag: '24 trucks available',
        bannerColor: Color(0xFF1B5E20),
        icon: Icons.local_shipping_rounded,
        code: 'FIRST20',
      ),
      const FeaturedPromoModel(
        id: 'promo-2',
        title: 'LKR 150 OFF Selected Trips',
        ribbonBadge: 'LKR 150 OFF',
        agencyName: 'Highland Agro Fleet',
        rating: 4.7,
        reviewsCount: 95,
        availabilityTag: '8 trucks available',
        bannerColor: Color(0xFF0D47A1),
        icon: Icons.flash_on_rounded,
        code: 'TRIP150',
      ),
    ];
  }

  @override
  Future<List<AgroAgencyModel>> getTopAgencies() async {
    return [
      const AgroAgencyModel(
        id: 'ag-1',
        name: 'Central Agro Hub',
        rating: 4.8,
        reviewsCount: 120,
        availableTrucks: 24,
        district: 'Dambulla',
      ),
    ];
  }
}

Widget createLandingTestApp({LandingRepository? repo}) {
  return ProviderScope(
    overrides: [
      landingRepositoryProvider.overrideWithValue(repo ?? TestLandingRepository()),
    ],
    child: const MaterialApp(
      home: PublicLandingScreen(),
    ),
  );
}

void main() {
  group('PublicLandingScreen Widget Tests (Uber Eats Style)', () {
    testWidgets('renders all key layout sections on public open without any auth gate',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // 1. Top Bar
      expect(find.byType(LandingTopBar), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LandingTopBar),
          matching: find.text('🌾'),
        ),
        findsOneWidget,
      );

      // 2. Location Row
      expect(find.text('Pickup near'), findsOneWidget);
      expect(find.text('Jaffna, Sri Lanka'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

      // 3. Search Bar
      expect(find.text('Search transport, agency, or market'), findsOneWidget);

      // 4. Filter Pills Row
      expect(find.text('🏷️ Offers'), findsOneWidget);
      expect(find.text('💰 Price ▼'), findsOneWidget);
      expect(find.text('⭐ Rating'), findsOneWidget);
      expect(find.text('📏 Nearest'), findsOneWidget);

      // 5. Promo Carousel
      expect(find.text('🔥 Featured on Farm2Route'), findsOneWidget);
      expect(find.text('20% OFF Your First Transport'), findsOneWidget);
      expect(find.text('20% OFF'), findsWidgets);

      // 6. Top Rated Agencies Section
      expect(find.text('⭐ Top Rated Agencies'), findsOneWidget);

      // 7. Main Vertical List
      expect(find.text('📦 Transport Packages Near You'), findsOneWidget);
      expect(find.text('Compare transport options from trusted agencies'), findsOneWidget);

      // Verify Package 1, 2, 3 are displayed
      expect(find.text('Central Agro Hub'), findsWidgets);
      expect(find.text('Northern Agro Logistics'), findsOneWidget);
      expect(find.text('Green Farm Transport'), findsOneWidget);

      // Inactive package must NOT be present
      expect(find.text('Inactive Discarded Fleet'), findsNothing);

      // Verify Bottom Navigation Bar is NOT present on public landing screen
      expect(find.text('Explore'), findsNothing);
      expect(find.text('Account'), findsNothing);
    });

    testWidgets('filtering by Offers filter pill updates the package list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Tap Offers filter pill
      final offersPill = find.byKey(const Key('filter_pill_offers'));
      await tester.ensureVisible(offersPill);
      await tester.tap(offersPill);
      await tester.pumpAndSettle();

      // Shows packages with offers (Central Agro Hub & Northern Agro Logistics)
      expect(find.text('Central Agro Hub'), findsWidgets);
      expect(find.text('Northern Agro Logistics'), findsOneWidget);
      // Non-offer package should be filtered out
      expect(find.text('Green Farm Transport'), findsNothing);
    });

    testWidgets('tapping View Details opens details sheet without login gate',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Tap View Details on Package 1
      final viewDetailsButton = find.byKey(const Key('view_details_pkg-1'));
      await tester.ensureVisible(viewDetailsButton);
      await tester.tap(viewDetailsButton);
      await tester.pumpAndSettle();

      // Expect Details sheet content
      expect(find.text('Scheduled Route'), findsOneWidget);
      expect(find.text('Max Payload'), findsOneWidget);
      expect(find.text('5000 KG'), findsOneWidget);
      expect(find.text('Bulk Cargo Truck'), findsWidgets);
      expect(find.text('Farm2Route Delivery Guarantees'), findsOneWidget);
    });

    testWidgets('tapping Book Now opens Login Required bottom sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Tap Book Now on Package 1
      final bookNowButton = find.byKey(const Key('book_now_pkg-1'));
      await tester.ensureVisible(bookNowButton);
      await tester.tap(bookNowButton);
      await tester.pumpAndSettle();

      // Expect Login Required Bottom Sheet
      expect(find.text('Login to continue your booking'), findsOneWidget);
      expect(find.byKey(const Key('sheet_login_button')), findsOneWidget);
      expect(find.byKey(const Key('sheet_signup_button')), findsOneWidget);
    });

    testWidgets('tapping location opens district selector sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      // Tap Location selector
      final locationSelector = find.byKey(const Key('landing_location_selector'));
      await tester.tap(locationSelector);
      await tester.pumpAndSettle();

      // Expect District Selector Sheet
      expect(find.text('Select Transport Pickup Hub'), findsOneWidget);
      expect(find.text('Use Current Device GPS'), findsOneWidget);
      expect(find.text('Dambulla, Sri Lanka'), findsOneWidget);
      expect(find.text('Kandy, Sri Lanka'), findsOneWidget);
      expect(find.text('Colombo, Sri Lanka'), findsOneWidget);

      // Select Dambulla
      final dambullaItem = find.widgetWithText(ListTile, 'Dambulla, Sri Lanka');
      await tester.ensureVisible(dambullaItem);
      await tester.tap(dambullaItem);
      await tester.pumpAndSettle();

      // Location in top row should now be updated to Dambulla
      expect(find.text('Dambulla, Sri Lanka'), findsOneWidget);
    });

    testWidgets('tapping top bar Log In and Sign Up buttons navigates to login and register routes',
        (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/landing',
        routes: [
          GoRoute(path: '/landing', builder: (_, __) => const PublicLandingScreen()),
          GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('Login Screen Target'))),
          GoRoute(path: '/register', builder: (_, __) => const Scaffold(body: Text('Register Screen Target'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            landingRepositoryProvider.overrideWithValue(TestLandingRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Log In button
      final loginBtn = find.byKey(const Key('landing_top_login_button'));
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Login Screen Target'), findsOneWidget);

      // Go back
      router.go('/landing');
      await tester.pumpAndSettle();

      // Tap Sign Up button
      final signupBtn = find.byKey(const Key('landing_top_signup_button'));
      await tester.tap(signupBtn);
      await tester.pumpAndSettle();
      expect(find.text('Register Screen Target'), findsOneWidget);
    });

    testWidgets('tapping View All Agencies opens AllAgenciesSheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      final viewAllBtn = find.byKey(const Key('view_all_agencies_button'));
      await tester.ensureVisible(viewAllBtn);
      await tester.tap(viewAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Verified Logistics Agencies'), findsOneWidget);
      expect(find.text('Compare top rated agricultural haulage fleets'), findsOneWidget);
    });

    testWidgets('tapping featured promos arrow button scrolls/moves to next package',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createLandingTestApp());
      await tester.pumpAndSettle();

      final featuredArrowBtn = find.byKey(const Key('featured_promos_view_all_button'));
      await tester.ensureVisible(featuredArrowBtn);

      // Verify promo 1 is present
      expect(find.text('20% OFF Your First Transport'), findsOneWidget);

      // Tap arrow to move to next package
      await tester.tap(featuredArrowBtn);
      await tester.pumpAndSettle();

      // Next package promo 2 is visible
      expect(find.text('LKR 150 OFF Selected Trips'), findsOneWidget);
    });
  });
}
