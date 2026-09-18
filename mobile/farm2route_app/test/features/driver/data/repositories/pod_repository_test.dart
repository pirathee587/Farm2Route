import 'package:dio/dio.dart';
import 'package:farm2route_app/core/network/api_client.dart';
import 'package:farm2route_app/core/storage/secure_storage.dart';
import 'package:farm2route_app/features/driver/data/repositories/pod_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService extends Fake implements SecureStorageService {}

class MockPodApiClient extends ApiClient {
  MockPodApiClient() : super(storage: FakeSecureStorageService());

  String? lastPath;
  FormData? lastFormData;

  @override
  Future<dynamic> postMultipart(
    String path,
    FormData formData, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    lastPath = path;
    lastFormData = formData;
    return {
      'id': 'pod-001',
      'bookingId': 'book-8842',
      'bookingNumber': 'BK-8842',
      'driverId': 'dr-100',
      'driverName': 'Kamal Perera',
      'recipientName': 'Sunil Shantha',
      'recipientPhone': '+94 77 123 4567',
      'recipientSignatureUrl': 'https://storage.supabase.co/pod/sig.png',
      'deliveryPhotoUrl': 'https://storage.supabase.co/pod/photo.jpg',
      'deliveryLatitude': 6.9271,
      'deliveryLongitude': 79.8612,
      'farmerConfirmationStatus': 'PENDING',
      'notes': 'Handed directly to recipient.',
    };
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    return {
      'id': 'pod-001',
      'bookingId': 'book-8842',
      'recipientName': 'Sunil Shantha',
      'recipientPhone': '+94 77 123 4567',
      'farmerConfirmationStatus': 'PENDING',
    };
  }
}

void main() {
  late MockPodApiClient mockApiClient;
  late PodRepository repository;

  setUp(() {
    mockApiClient = MockPodApiClient();
    repository = PodRepository(mockApiClient);
  });

  test('submitPod builds multipart FormData with data, signature, photo and parses response', () async {
    final result = await repository.submitPod(
      bookingId: 'book-8842',
      recipientName: 'Sunil Shantha',
      recipientPhone: '+94 77 123 4567',
      deliveryLatitude: 6.9271,
      deliveryLongitude: 79.8612,
      notes: 'Handed directly to recipient.',
      signatureBytes: [1, 2, 3, 4],
      photoBytes: [5, 6, 7, 8],
    );

    expect(mockApiClient.lastPath, equals('/bookings/book-8842/pod'));
    expect(mockApiClient.lastFormData, isNotNull);
    final fields = mockApiClient.lastFormData!.fields;
    final files = mockApiClient.lastFormData!.files;

    expect(files.any((f) => f.key == 'data'), isTrue);
    expect(files.any((f) => f.key == 'signature'), isTrue);
    expect(files.any((f) => f.key == 'photo'), isTrue);

    expect(result.id, equals('pod-001'));
    expect(result.bookingId, equals('book-8842'));
    expect(result.recipientName, equals('Sunil Shantha'));
    expect(result.farmerConfirmationStatus, equals('PENDING'));
  });

  test('getPod requests POD details by bookingId', () async {
    final pod = await repository.getPod('book-8842');

    expect(mockApiClient.lastPath, equals('/bookings/book-8842/pod'));
    expect(pod, isNotNull);
    expect(pod!.bookingId, equals('book-8842'));
  });
}
