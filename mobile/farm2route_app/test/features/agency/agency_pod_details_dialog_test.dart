import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/driver/data/models/pod_model.dart';
import 'package:farm2route_app/features/driver/data/repositories/pod_repository.dart';
import 'package:farm2route_app/features/agency/presentation/widgets/agency_pod_details_dialog.dart';

class MockPodRepository implements PodRepository {
  final PodModel? mockPod;

  MockPodRepository(this.mockPod);

  @override
  Future<PodModel?> getPod(String bookingId) async {
    return mockPod;
  }

  @override
  Future<PodModel> submitPod({
    required String bookingId,
    required String recipientName,
    required String recipientPhone,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? notes,
    required List<int> signatureBytes,
    String signatureFilename = 'signature.png',
    required List<int> photoBytes,
    String photoFilename = 'delivery_photo.jpg',
    void Function(int count, int total)? onSendProgress,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('AgencyPodDetailsDialog Widget Tests', () {
    testWidgets('renders loading and then POD details when available', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final samplePod = PodModel(
        id: 'pod-101',
        bookingId: 'book-8842',
        bookingNumber: 'BKG-8842',
        driverName: 'Kamal Perera',
        recipientName: 'Sunil Weerasinghe',
        recipientPhone: '+94771234567',
        deliveryLatitude: 6.9271,
        deliveryLongitude: 79.8612,
        deliveryTimestamp: DateTime(2026, 9, 15, 14, 30),
        notes: 'Delivered directly to main warehouse bay 2',
      );

      final mockRepo = MockPodRepository(samplePod);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            podRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AgencyPodDetailsDialog(
                bookingId: 'book-8842',
                bookingNumber: 'BKG-8842',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Proof of Delivery (POD)'), findsOneWidget);
      expect(find.text('Booking: BKG-8842'), findsOneWidget);
      expect(find.text('DELIVERED & VERIFIED BY DRIVER'), findsOneWidget);
      expect(find.text('Sunil Weerasinghe'), findsOneWidget);
      expect(find.text('+94771234567'), findsOneWidget);
      expect(find.text('Kamal Perera'), findsOneWidget);
      expect(find.text('6.927100, 79.861200'), findsOneWidget);
      expect(find.text('Delivered directly to main warehouse bay 2'), findsOneWidget);
    });

    testWidgets('renders placeholder banner when no POD is found', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockPodRepository(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            podRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AgencyPodDetailsDialog(
                bookingId: 'book-9999',
                bookingNumber: 'BKG-9999',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Proof of Delivery (POD)'), findsOneWidget);
      expect(find.text('POD submission records will appear here once driver completes delivery.'), findsOneWidget);
    });
  });
}
