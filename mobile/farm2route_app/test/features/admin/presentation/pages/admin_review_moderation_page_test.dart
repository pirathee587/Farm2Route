import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_review_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/pages/admin_review_moderation_page.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAdminRepositoryWidget implements AdminRepository {
  final List<AdminReviewModel> mockReviews;

  MockAdminRepositoryWidget({this.mockReviews = const []});

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
  Widget buildTestableWidget(AdminRepository repository) {
    return ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: AdminReviewModerationPage(),
      ),
    );
  }

  group('AdminReviewModerationPage Widget Tests', () {
    testWidgets('displays empty state when queue is empty', (tester) async {
      final mockRepo = MockAdminRepositoryWidget(mockReviews: []);

      await tester.pumpWidget(buildTestableWidget(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('No reviews currently flagged for moderation'), findsOneWidget);
    });

    testWidgets('Restore button only appears for HIDDEN reviews', (tester) async {
      const pendingReview = AdminReviewModel(
        id: 'rev-pending',
        bookingId: 'bk-1',
        bookingNumber: 'BK-1001',
        farmerId: 'f-1',
        farmerName: 'John Farmer',
        agencyId: 'a-1',
        agencyName: 'Green Haulers',
        agencyRating: 4.0,
        comment: 'Driver arrived late',
        moderationStatus: 'PENDING_REVIEW',
      );

      const hiddenReview = AdminReviewModel(
        id: 'rev-hidden',
        bookingId: 'bk-2',
        bookingNumber: 'BK-1002',
        farmerId: 'f-2',
        farmerName: 'Alice Farmer',
        agencyId: 'a-2',
        agencyName: 'Swift Logistics',
        agencyRating: 1.0,
        comment: 'Spam comment',
        moderationStatus: 'HIDDEN',
      );

      final mockRepo = MockAdminRepositoryWidget(
        mockReviews: [pendingReview, hiddenReview],
      );

      await tester.pumpWidget(buildTestableWidget(mockRepo));
      await tester.pumpAndSettle();

      // We have 2 Hide buttons, 2 Escalate buttons, but exactly 1 Restore button (only for the hidden review)
      expect(find.text('Hide'), findsNWidgets(2));
      expect(find.text('Escalate'), findsNWidgets(2));
      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('Restore button does NOT appear when all reviews are PENDING_REVIEW', (tester) async {
      const pendingReview = AdminReviewModel(
        id: 'rev-pending-1',
        bookingId: 'bk-1',
        bookingNumber: 'BK-1001',
        farmerId: 'f-1',
        farmerName: 'John Farmer',
        agencyId: 'a-1',
        agencyName: 'Green Haulers',
        agencyRating: 4.0,
        comment: 'Driver arrived late',
        moderationStatus: 'PENDING_REVIEW',
      );

      final mockRepo = MockAdminRepositoryWidget(
        mockReviews: [pendingReview],
      );

      await tester.pumpWidget(buildTestableWidget(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Hide'), findsOneWidget);
      expect(find.text('Escalate'), findsOneWidget);
      expect(find.text('Restore'), findsNothing);
    });
  });
}
