import 'package:farm2route_app/core/network/api_client.dart';
import 'package:farm2route_app/core/network/api_endpoints.dart';
import 'package:farm2route_app/core/storage/secure_storage.dart';
import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake-token';
}

class MockApiClient extends ApiClient {
  final Map<String, dynamic> responseData;
  String? requestedPath;

  MockApiClient(this.responseData) : super(storage: FakeSecureStorageService());

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    requestedPath = path;
    return responseData;
  }
}

class FakeAdminRepository implements AdminRepository {
  final AdminStatsModel stats;
  bool getStatsCalled = false;

  FakeAdminRepository(this.stats);

  @override
  Future<AdminStatsModel> getStats() async {
    getStatsCalled = true;
    return stats;
  }

  @override
  Future<List<AgencyKycSummaryModel>> getPendingAgencyKyc({List<String>? statusFilter}) async => [];

  @override
  Future<List<DriverKycSummaryModel>> getPendingDriverKyc({List<String>? statusFilter}) async => [];

  @override
  Future<List<VehicleKycSummaryModel>> getPendingVehicleKyc({List<String>? statusFilter}) async => [];

  @override
  Future<void> submitKycDecision({
    required String entityType,
    required String entityId,
    required String status,
    String? rejectionReason,
  }) async {}

  @override
  Future<List<AdminIncidentModel>> searchIncidents({String? status, String? incidentType, String? fromDate, String? toDate, int page = 0, int size = 20}) async => [];

  @override
  Future<AdminIncidentModel> getIncidentDetail(String id) async => throw UnimplementedError();

  @override
  Future<AdminIncidentModel> addIncidentNote(String id, String note) async => throw UnimplementedError();

  @override
  Future<AdminIncidentModel> resolveIncident(String id, {required String status, String? notes, double? refundAmount}) async => throw UnimplementedError();

  @override
  Future<AdminIncidentModel> escalateIncident(String id, String notes) async => throw UnimplementedError();
}

void main() {
  group('AdminRepository', () {
    test('getStats calls ApiClient.get with adminStats endpoint and parses response', () async {
      final jsonResponse = {
        'totalUsers': 100,
        'totalFarmers': 50,
        'totalAgencies': 20,
        'totalDrivers': 30,
        'pendingKycs': 4,
        'activeBookings': 12,
        'openIncidents': 2,
      };

      final mockApiClient = MockApiClient(jsonResponse);
      final repository = AdminRepository(mockApiClient);

      final stats = await repository.getStats();

      expect(mockApiClient.requestedPath, equals(ApiEndpoints.adminStats));
      expect(stats.totalUsers, equals(100));
      expect(stats.totalFarmers, equals(50));
      expect(stats.totalAgencies, equals(20));
      expect(stats.totalDrivers, equals(30));
      expect(stats.pendingKycs, equals(4));
      expect(stats.activeBookings, equals(12));
      expect(stats.openIncidents, equals(2));
    });
  });

  group('adminStatsProvider', () {
    test('fetches AdminStatsModel via adminRepositoryProvider', () async {
      const expectedStats = AdminStatsModel(
        totalUsers: 200,
        totalFarmers: 100,
        totalAgencies: 40,
        totalDrivers: 60,
        pendingKycs: 8,
        activeBookings: 24,
        openIncidents: 3,
      );

      final fakeRepo = FakeAdminRepository(expectedStats);

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(adminStatsProvider.future);

      expect(fakeRepo.getStatsCalled, isTrue);
      expect(result.totalFarmers, equals(100));
      expect(result.totalAgencies, equals(40));
      expect(result.totalDrivers, equals(60));
      expect(result.pendingKycs, equals(8));
      expect(result.openIncidents, equals(3));
    });
  });
}
