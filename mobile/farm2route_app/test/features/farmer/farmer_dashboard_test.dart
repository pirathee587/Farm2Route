import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/farmer/data/models/farmer_dashboard_models.dart';
import 'package:farm2route_app/features/farmer/domain/repositories/farmer_dashboard_repository.dart';
import 'package:farm2route_app/features/farmer/presentation/providers/farmer_dashboard_provider.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_dashboard_screen.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_hauler_results_screen.dart';
import 'package:farm2route_app/features/farmer/presentation/screens/farmer_package_details_screen.dart';
import 'package:farm2route_app/shared/widgets/agrizel_pill_button.dart';

class MockFarmerDashboardRepository implements FarmerDashboardRepository {
  @override
  Future<List<DispatchAvailabilitySlot>> checkAvailability(DateTime month) async {
    return List.generate(14, (idx) {
      final day = DateTime(month.year, month.month, idx + 1);
      final isFull = (idx == 3 || idx == 10);
      return DispatchAvailabilitySlot(
        date: day,
        availableSlots: isFull ? 0 : 6,
        isFullyBooked: isFull,
      );
    });
  }

  @override
  Future<FareEstimateModel> estimateFare({
    required String pickup,
    required String destination,
    required double weightKg,
    required String produceType,
  }) async {
    return const FareEstimateModel(
      distanceKm: 148,
      estimatedFare: 18500,
      durationText: '3 hr 30 min',
    );
  }

  @override
  Future<List<HaulerAgencyModel>> findHaulers(FindHaulersRequest request) async {
    return [
      const HaulerAgencyModel(
        id: 'h1',
        name: 'MKC Logistics & Freight Hub',
        rating: 4.9,
        reviewsCount: 340,
        etaMinutes: 28,
        estimatedFare: 18500,
        promoBadge: '20% Harvest Rebate',
        vehicleType: 'Isuzu Elf Cold Box (6-T)',
        vehiclePlate: 'WP-NB-8821',
        phone: '+94 77 123 4567',
        coldChainSupported: true,
      ),
    ];
  }

  @override
  Future<List<LogisticsPackageModel>> getPackages() async {
    return const [
      LogisticsPackageModel(
        id: 'pkg-1',
        name: 'Seasonal Harvest Unlimited Pass',
        frequency: 'Seasonal (3 Months)',
        price: 45000,
        discountBadge: 'Save 35%',
        description: 'Priority dispatch access across all Central Province markets.',
        features: ['Guaranteed hauler dispatch within 60 mins'],
      ),
    ];
  }

  @override
  Future<bool> subscribeToPackage(String farmerId, String packageId) async => true;

  @override
  Future<FarmerOrderModel> createBooking(BookingSubmissionRequest request) async {
    return FarmerOrderModel(
      id: 'ord-1',
      bookingRef: 'F2R-8849-LK',
      pickup: request.pickupLocation,
      destination: request.destinationLocation,
      produceType: request.produceType,
      weightKg: request.weightKg,
      fare: request.fare,
      status: 'CONFIRMED',
      date: 'Today, 04:30 AM',
    );
  }

  @override
  Future<List<FarmerOrderModel>> getRecentOrders() async {
    return const [
      FarmerOrderModel(
        id: 'ord-101',
        bookingRef: 'F2R-8849-LK',
        pickup: 'My Farm, Dambulla Hub',
        destination: 'Manning Wholesale Market, Colombo',
        produceType: 'Carrots & Fresh Leeks',
        weightKg: 2800,
        fare: 24500,
        status: 'IN_TRANSIT',
        date: 'Today, 04:30 AM',
      ),
    ];
  }
}

Widget createDashboardTestApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      farmerDashboardRepositoryProvider
          .overrideWithValue(MockFarmerDashboardRepository()),
      ...overrides,
    ],
    child: const MaterialApp(
      home: FarmerDashboardScreen(),
    ),
  );
}

void main() {
  group('FarmerDashboardScreen Widget Tests', () {
    testWidgets('renders top header, filter tabs, booking card, packages, and bottom nav',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDashboardTestApp());
      await tester.pumpAndSettle();

      // Top Header elements
      expect(find.text('PICKUP FARM GATE'), findsOneWidget);
      expect(find.text('My Farm, Dambulla'), findsWidgets);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Express Haul'), findsOneWidget);
      expect(find.text('Harvests'), findsOneWidget);
      expect(find.text('Bulk Freight'), findsOneWidget);

      // Booking Widget Card fields
      expect(find.text('Dispatch Booking'), findsOneWidget);
      expect(find.text('Manning Wholesale Market, Colombo'), findsOneWidget);
      expect(find.text('Cargo Weight'), findsOneWidget);
      expect(find.text('KG'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Find Haulers CTA Button
      expect(find.widgetWithText(AgrizelPillButton, 'Find Available Haulers'),
          findsOneWidget);

      // Featured packages header
      expect(find.text('Featured Logistics Packages'), findsOneWidget);

      // Recent Dispatches header
      expect(find.text('Recent Dispatches'), findsOneWidget);

      // Bottom Navigation Bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Prices'), findsOneWidget);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('validates cargo weight field when weight is zero or cleared',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDashboardTestApp());
      await tester.pumpAndSettle();

      // Clear weight field to 0
      final weightField = find.byType(TextField);
      await tester.enterText(weightField, '0');
      await tester.pumpAndSettle();

      // Tap Find Haulers CTA
      final findButton = find.widgetWithText(AgrizelPillButton, 'Find Available Haulers');
      await tester.tap(findButton);
      await tester.pumpAndSettle();

      // Should show validation SnackBar
      expect(find.textContaining('valid harvest cargo weight'), findsOneWidget);
    });

    testWidgets('renders date availability sheet with slots and disabled full dates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDashboardTestApp());
      await tester.pumpAndSettle();

      // Tap dispatch date box
      await tester.tap(find.text('Dispatch Date'));
      await tester.pumpAndSettle();

      // Verify availability modal opened
      expect(find.text('Select Dispatch Date'), findsOneWidget);
      expect(find.text('Live Hauler Slots'), findsOneWidget);

      // Should show slot counts or full badges
      expect(find.textContaining('slots'), findsWidgets);
    });

    testWidgets('bottom navigation bar switches between tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDashboardTestApp());
      await tester.pumpAndSettle();

      // Tap Prices tab
      await tester.tap(find.text('Prices'));
      await tester.pumpAndSettle();
      expect(find.text('Market Prices'), findsOneWidget);

      // Tap Account tab
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Farmer Account'), findsOneWidget);
      expect(find.widgetWithText(AgrizelPillButton, 'Sign Out'), findsOneWidget);

      // Tap Home tab to return
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Dispatch Booking'), findsOneWidget);
    });
  });

  group('FarmerHaulerResultsScreen Widget Tests', () {
    final mockHaulers = [
      const HaulerAgencyModel(
        id: 'h1',
        name: 'MKC Logistics & Freight Hub',
        rating: 4.9,
        reviewsCount: 340,
        etaMinutes: 28,
        estimatedFare: 18500,
        promoBadge: '20% Harvest Rebate',
        vehicleType: 'Isuzu Elf Cold Box (6-T)',
        vehiclePlate: 'WP-NB-8821',
        phone: '+94 77 123 4567',
        coldChainSupported: true,
      ),
      const HaulerAgencyModel(
        id: 'h2',
        name: 'Central Agri Dispatch Fleet',
        rating: 4.8,
        reviewsCount: 195,
        etaMinutes: 35,
        estimatedFare: 16200,
        promoBadge: 'Verified Farm Partner',
        vehicleType: 'Tata Ultra (10-T)',
        vehiclePlate: 'CP-DA-4190',
        phone: '+94 71 987 6543',
        coldChainSupported: false,
      ),
    ];

    testWidgets('renders agency cards with rating, fare, ETA, and promo badge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FarmerHaulerResultsScreen(initialHaulers: mockHaulers),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Agency names
      expect(find.text('MKC Logistics & Freight Hub'), findsOneWidget);
      expect(find.text('Central Agri Dispatch Fleet'), findsOneWidget);

      // Ratings
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);

      // Promo badge
      expect(find.text('20% Harvest Rebate'), findsOneWidget);

      // Select buttons
      expect(find.widgetWithText(ElevatedButton, 'Select'), findsNWidgets(2));
    });

    testWidgets('tapping Select opens booking confirmation sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmerDashboardRepositoryProvider
                .overrideWithValue(MockFarmerDashboardRepository()),
          ],
          child: MaterialApp(
            home: FarmerHaulerResultsScreen(initialHaulers: mockHaulers),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first select button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Select').first);
      await tester.pumpAndSettle();

      // Confirmation modal should open
      expect(find.text('Booking Confirmation'), findsOneWidget);
      expect(find.widgetWithText(AgrizelPillButton, 'Confirm Booking'), findsOneWidget);
    });
  });

  group('FarmerPackageDetailsScreen Widget Tests', () {
    const testPackage = LogisticsPackageModel(
      id: 'pkg-1',
      name: 'Seasonal Harvest Unlimited Pass',
      frequency: 'Seasonal (3 Months)',
      price: 45000,
      discountBadge: 'Save 35%',
      description: 'Priority dispatch access across all Central Province markets.',
      features: [
        'Guaranteed hauler dispatch within 60 mins',
        'Zero cancellation fees',
      ],
    );

    testWidgets('renders package title, frequency, price, discount, features, and subscribe CTA',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FarmerPackageDetailsScreen(package: testPackage),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seasonal Harvest Unlimited Pass'), findsOneWidget);
      expect(find.text('Seasonal (3 Months)'), findsOneWidget);
      expect(find.text('Save 35%'), findsOneWidget);
      expect(find.text('LKR 45000'), findsOneWidget);
      expect(find.text('Guaranteed hauler dispatch within 60 mins'), findsOneWidget);
      expect(find.widgetWithText(AgrizelPillButton, 'Subscribe to Package'), findsOneWidget);
    });
  });
}
