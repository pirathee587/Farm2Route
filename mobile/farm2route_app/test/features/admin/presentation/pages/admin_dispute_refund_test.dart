import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_review_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/pages/admin_incident_detail_page.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockDisputeAdminRepository implements AdminRepository {
  final AdminIncidentModel incident;
  double? lastRefundAmount;
  String? lastRefundDecision;

  MockDisputeAdminRepository({required this.incident});

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
  Future<AdminIncidentModel> getIncidentDetail(String id) async => incident;

  @override
  Future<AdminIncidentModel> addIncidentNote(String id, String note) async => incident;

  @override
  Future<AdminIncidentModel> resolveIncident(
    String id, {
    required String status,
    String? notes,
    double? refundAmount,
  }) async =>
      incident;

  @override
  Future<AdminIncidentModel> escalateIncident(String id, String notes) async => incident;

  @override
  Future<List<AdminReviewModel>> getReportedReviews({int page = 0, int size = 20}) async => [];

  @override
  Future<AdminReviewModel?> hideReview(String id, {String? reason}) async => null;

  @override
  Future<AdminReviewModel?> restoreReview(String id) async => null;

  @override
  Future<AdminReviewModel?> escalateReview(String id, {String? reason}) async => null;

  @override
  Future<AdminIncidentModel?> recordAgencyResponse(String id, String responseText) async => incident;

  @override
  Future<AdminIncidentModel?> decideRefund(String id, double amount, String decision) async {
    lastRefundAmount = amount;
    lastRefundDecision = decision;
    return incident;
  }
}

void main() {
  Widget buildTestableWidget(AdminRepository repository, String incidentId) {
    return ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: AdminIncidentDetailPage(incidentId: incidentId),
      ),
    );
  }

  group('Refund Decision Validation Widget Tests', () {
    testWidgets('refund amount field rejects 0 and negative input before submit button is enabled',
        (tester) async {
      const cargoIncident = AdminIncidentModel(
        id: 'inc-dispute-1',
        bookingId: 'bk-100',
        bookingNumber: 'BK-100',
        incidentType: 'CARGO_DAMAGE',
        title: 'Damaged Apples Cargo',
        description: 'Apples ruined during transit due to cooling failure.',
        status: 'OPEN',
      );

      final mockRepo = MockDisputeAdminRepository(incident: cargoIncident);

      await tester.pumpWidget(buildTestableWidget(mockRepo, cargoIncident.id));
      await tester.pumpAndSettle();

      final refundAmountFinder = find.byKey(const Key('refund_amount_field'));
      final refundDecisionFinder = find.byKey(const Key('refund_decision_field'));
      final submitButtonFinder = find.byKey(const Key('submit_refund_button'));

      expect(refundAmountFinder, findsOneWidget);
      expect(refundDecisionFinder, findsOneWidget);
      expect(submitButtonFinder, findsOneWidget);

      // Initially empty -> Submit button disabled
      final initialButton = tester.widget<ElevatedButton>(submitButtonFinder);
      expect(initialButton.onPressed, isNull);

      // 1. Enter decision text, leave amount empty -> Button disabled
      await tester.enterText(refundDecisionFinder, 'Agreed refund for ruined apples');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(submitButtonFinder).onPressed, isNull);

      // 2. Enter 0 in refund amount field -> Button STILL disabled & error shown
      await tester.enterText(refundAmountFinder, '0');
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than 0'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(submitButtonFinder).onPressed, isNull);

      // 3. Enter negative amount (-50) -> Button STILL disabled & error shown
      await tester.enterText(refundAmountFinder, '-50');
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than 0'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(submitButtonFinder).onPressed, isNull);

      // 4. Enter valid positive amount (150.50) -> Button becomes ENABLED
      await tester.enterText(refundAmountFinder, '150.50');
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than 0'), findsNothing);

      final enabledButton = tester.widget<ElevatedButton>(submitButtonFinder);
      expect(enabledButton.onPressed, isNotNull);
    });
  });
}
