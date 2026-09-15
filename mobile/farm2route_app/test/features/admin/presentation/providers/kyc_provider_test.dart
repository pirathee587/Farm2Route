import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_review_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:farm2route_app/features/admin/presentation/providers/kyc_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockKycAdminRepository implements AdminRepository {
  final List<AgencyKycSummaryModel> mockAgencies;
  final List<DriverKycSummaryModel> mockDrivers;
  final List<VehicleKycSummaryModel> mockVehicles;

  String? lastDecisionEntityType;
  String? lastDecisionEntityId;
  String? lastDecisionStatus;
  String? lastDecisionReason;

  MockKycAdminRepository({
    this.mockAgencies = const [],
    this.mockDrivers = const [],
    this.mockVehicles = const [],
  });

  @override
  Future<AdminStatsModel> getStats() async => const AdminStatsModel(
        totalUsers: 50,
        totalFarmers: 30,
        totalAgencies: 10,
        totalDrivers: 10,
        pendingKycs: 3,
        activeBookings: 2,
        openIncidents: 0,
      );

  @override
  Future<List<AgencyKycSummaryModel>> getPendingAgencyKyc({List<String>? statusFilter}) async {
    return mockAgencies;
  }

  @override
  Future<List<DriverKycSummaryModel>> getPendingDriverKyc({List<String>? statusFilter}) async {
    return mockDrivers;
  }

  @override
  Future<List<VehicleKycSummaryModel>> getPendingVehicleKyc({List<String>? statusFilter}) async {
    return mockVehicles;
  }

  @override
  Future<void> submitKycDecision({
    required String entityType,
    required String entityId,
    required String status,
    String? rejectionReason,
  }) async {
    lastDecisionEntityType = entityType;
    lastDecisionEntityId = entityId;
    lastDecisionStatus = status;
    lastDecisionReason = rejectionReason;
  }

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

  @override
  Future<List<AdminReviewModel>> getReportedReviews({int page = 0, int size = 20}) async => [];

  @override
  Future<AdminReviewModel?> hideReview(String id, {String? reason}) async => null;

  @override
  Future<AdminReviewModel?> restoreReview(String id) async => null;

  @override
  Future<AdminReviewModel?> escalateReview(String id, {String? reason}) async => null;

  @override
  Future<AdminIncidentModel?> recordAgencyResponse(String id, String responseText) async => null;

  @override
  Future<AdminIncidentModel?> decideRefund(String id, double amount, String decision) async => null;
}

void main() {
  group('KYC Providers & Decision Submission', () {
    test('fetch pending agency, driver, and vehicle KYC queues', () async {
      const agency = AgencyKycSummaryModel(
        id: 'ag-1',
        companyName: 'Alpha Logistics',
        contactEmail: 'alpha@logistics.com',
        contactPhone: '9876543210',
        kycStatus: 'PENDING',
      );
      const driver = DriverKycSummaryModel(
        id: 'dr-1',
        driverName: 'John Doe',
        phone: '1234567890',
        licenseNumber: 'LIC-999',
        kycStatus: 'PENDING',
      );
      const vehicle = VehicleKycSummaryModel(
        id: 'vh-1',
        registrationNumber: 'KA-01-AB-1234',
        vehicleType: 'TRUCK',
        kycStatus: 'PENDING',
      );

      final mockRepo = MockKycAdminRepository(
        mockAgencies: [agency],
        mockDrivers: [driver],
        mockVehicles: [vehicle],
      );

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final agencies = await container.read(pendingAgencyKycProvider.future);
      final drivers = await container.read(pendingDriverKycProvider.future);
      final vehicles = await container.read(pendingVehicleKycProvider.future);

      expect(agencies.length, equals(1));
      expect(agencies.first.companyName, equals('Alpha Logistics'));

      expect(drivers.length, equals(1));
      expect(drivers.first.driverName, equals('John Doe'));

      expect(vehicles.length, equals(1));
      expect(vehicles.first.registrationNumber, equals('KA-01-AB-1234'));
    });

    test('submitKycDecision posts decision parameters correctly', () async {
      final mockRepo = MockKycAdminRepository();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(adminRepositoryProvider);
      await repo.submitKycDecision(
        entityType: 'driver',
        entityId: 'dr-100',
        status: 'APPROVED',
      );

      expect(mockRepo.lastDecisionEntityType, equals('driver'));
      expect(mockRepo.lastDecisionEntityId, equals('dr-100'));
      expect(mockRepo.lastDecisionStatus, equals('APPROVED'));
      expect(mockRepo.lastDecisionReason, isNull);
    });
  });
}
