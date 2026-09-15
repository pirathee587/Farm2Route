import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_review_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_review_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAdminRepositoryForReview implements AdminRepository {
  final List<AdminReviewModel> mockReviews;

  String? lastHiddenId;
  String? lastHideReason;
  String? lastRestoredId;
  String? lastEscalatedId;
  String? lastEscalateReason;

  MockAdminRepositoryForReview({this.mockReviews = const []});

  @override
  Future<AdminStatsModel> getStats() async => const AdminStatsModel(
        totalUsers: 0,
        totalFarmers: 0,
        totalAgencies: 0,
        totalDrivers: 0,
        pendingKycs: 0,
        activeBookings: 0,
        openIncidents: 0,
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
  }) async =>
      [];

  @override
  Future<AdminIncidentModel> getIncidentDetail(String id) async => throw UnimplementedError();

  @override
  Future<AdminIncidentModel> addIncidentNote(String id, String note) async => throw UnimplementedError();

  @override
  Future<AdminIncidentModel> resolveIncident(
    String id, {
    required String status,
    String? notes,
    double? refundAmount,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AdminIncidentModel> escalateIncident(String id, String notes) async => throw UnimplementedError();

  @override
  Future<List<AdminReviewModel>> getReportedReviews({int page = 0, int size = 20}) async {
    return mockReviews;
  }

  @override
  Future<AdminReviewModel?> hideReview(String id, {String? reason}) async {
    lastHiddenId = id;
    lastHideReason = reason;
    return null;
  }

  @override
  Future<AdminReviewModel?> restoreReview(String id) async {
    lastRestoredId = id;
    return null;
  }

  @override
  Future<AdminReviewModel?> escalateReview(String id, {String? reason}) async {
    lastEscalatedId = id;
    lastEscalateReason = reason;
    return null;
  }

  @override
  Future<AdminIncidentModel?> recordAgencyResponse(String id, String responseText) async => null;

  @override
  Future<AdminIncidentModel?> decideRefund(String id, double amount, String decision) async => null;
}

void main() {
  group('AdminReviewProvider & Repository Calls', () {
    test('fetches reported reviews list', () async {
      const review = AdminReviewModel(
        id: 'rev-1',
        bookingId: 'bk-1',
        bookingNumber: 'BK-101',
        farmerId: 'f-1',
        farmerName: 'Farmer Joe',
        agencyId: 'a-1',
        agencyName: 'Express Logistics',
        driverId: 'd-1',
        driverName: 'Dave Driver',
        agencyRating: 4.5,
        driverRating: 5.0,
        comment: 'Great service',
        moderationStatus: 'PENDING_REVIEW',
      );

      final mockRepo = MockAdminRepositoryForReview(mockReviews: [review]);

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final reviews = await container.read(adminReportedReviewsProvider.future);
      expect(reviews.length, equals(1));
      expect(reviews.first.id, equals('rev-1'));
      expect(reviews.first.farmerName, equals('Farmer Joe'));
    });

    test('hideReview calls repository with id and reason', () async {
      final mockRepo = MockAdminRepositoryForReview();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(adminRepositoryProvider);
      await repo.hideReview('rev-123', reason: 'Inappropriate language');

      expect(mockRepo.lastHiddenId, equals('rev-123'));
      expect(mockRepo.lastHideReason, equals('Inappropriate language'));
    });

    test('restoreReview calls repository with id', () async {
      final mockRepo = MockAdminRepositoryForReview();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(adminRepositoryProvider);
      await repo.restoreReview('rev-456');

      expect(mockRepo.lastRestoredId, equals('rev-456'));
    });

    test('escalateReview calls repository with id and reason', () async {
      final mockRepo = MockAdminRepositoryForReview();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(adminRepositoryProvider);
      await repo.escalateReview('rev-789', reason: 'Legal violation');

      expect(mockRepo.lastEscalatedId, equals('rev-789'));
      expect(mockRepo.lastEscalateReason, equals('Legal violation'));
    });
  });
}
