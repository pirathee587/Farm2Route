import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_review_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/audit_log_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_incident_provider.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockIncidentAdminRepository implements AdminRepository {
  String? searchStatus;
  String? searchType;
  int? searchPage;

  @override
  Future<AdminStatsModel> getStats() async => const AdminStatsModel(
        totalUsers: 10,
        totalFarmers: 5,
        totalAgencies: 2,
        totalDrivers: 3,
        pendingKycs: 1,
        activeBookings: 0,
        openIncidents: 1,
      );

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
  Future<List<AdminIncidentModel>> searchIncidents({
    String? status,
    String? incidentType,
    String? fromDate,
    String? toDate,
    int page = 0,
    int size = 20,
  }) async {
    searchStatus = status;
    searchType = incidentType;
    searchPage = page;
    return [
      AdminIncidentModel(
        id: 'inc-99',
        incidentType: incidentType ?? 'CROP_DAMAGE',
        title: 'Filtered Incident',
        description: 'Test description',
        status: status ?? 'OPEN',
      ),
    ];
  }

  @override
  Future<AdminIncidentModel> getIncidentDetail(String id) async {
    return const AdminIncidentModel(
      id: 'inc-99',
      incidentType: 'CROP_DAMAGE',
      title: 'Filtered Incident Detail',
      description: 'Test description detail',
      status: 'OPEN',
    );
  }

  @override
  Future<AdminIncidentModel> addIncidentNote(String id, String note) async {
    throw UnimplementedError();
  }

  @override
  Future<AdminIncidentModel> resolveIncident(
    String id, {
    required String status,
    String? notes,
    double? refundAmount,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AdminIncidentModel> escalateIncident(String id, String notes) async {
    throw UnimplementedError();
  }

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

  @override
  Future<PagedAuditLogModel> getAuditLogs({String? action, String? entityName, String? actorId, String? fromDate, String? toDate, int page = 0, int size = 20}) async =>
      const PagedAuditLogModel(content: [], pageNumber: 0, pageSize: 20, totalElements: 0, totalPages: 0, last: true);
}

void main() {
  group('Admin Incident Notifier & Filtered Search', () {
    test('fetches incidents with initial default filters', () async {
      final mockRepo = MockIncidentAdminRepository();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial fetch
      final state = container.read(adminIncidentNotifierProvider);
      expect(state.isLoading, isTrue);

      await Future.delayed(Duration.zero);

      final listState = container.read(adminIncidentNotifierProvider);
      expect(listState.hasValue, isTrue);
      expect(listState.value!.length, equals(1));
      expect(mockRepo.searchStatus, isNull);
      expect(mockRepo.searchType, isNull);
      expect(mockRepo.searchPage, equals(0));
    });

    test('updating status and incidentType filters builds correct query params', () async {
      final mockRepo = MockIncidentAdminRepository();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adminIncidentNotifierProvider.notifier);

      // Apply status and type filters
      notifier.setFilter(status: 'INVESTIGATING', incidentType: 'BREAKDOWN', page: 1);
      await Future.delayed(Duration.zero);

      expect(mockRepo.searchStatus, equals('INVESTIGATING'));
      expect(mockRepo.searchType, equals('BREAKDOWN'));
      expect(mockRepo.searchPage, equals(1));

      final listState = container.read(adminIncidentNotifierProvider);
      expect(listState.value!.first.status, equals('INVESTIGATING'));
    });
  });
}
