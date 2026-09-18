import 'package:farm2route_app/features/admin/data/models/admin_incident_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_review_model.dart';
import 'package:farm2route_app/features/admin/data/models/admin_stats_model.dart';
import 'package:farm2route_app/features/admin/data/models/audit_log_model.dart';
import 'package:farm2route_app/features/admin/data/models/kyc_summary_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:farm2route_app/features/admin/presentation/widgets/kyc_decision_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAdminRepository implements AdminRepository {
  bool submitCalled = false;
  String? submittedStatus;
  String? submittedReason;

  @override
  Future<AdminStatsModel> getStats() async => const AdminStatsModel(
        totalUsers: 10,
        totalFarmers: 5,
        totalAgencies: 2,
        totalDrivers: 3,
        pendingKycs: 1,
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
  }) async {
    submitCalled = true;
    submittedStatus = status;
    submittedReason = rejectionReason;
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

  @override
  Future<PagedAuditLogModel> getAuditLogs({String? action, String? entityName, String? actorId, String? fromDate, String? toDate, int page = 0, int size = 20}) async =>
      const PagedAuditLogModel(content: [], pageNumber: 0, pageSize: 20, totalElements: 0, totalPages: 0, last: true);
}

void main() {
  testWidgets('Reject button stays disabled until reason text is entered', (WidgetTester tester) async {
    final fakeRepo = FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: KycDecisionSheet(
              entityType: 'agency',
              entityId: 'agency-123',
              entityName: 'GreenExpress Logistics',
              kycStatus: 'PENDING',
              details: {'Email': 'contact@greenexpress.com'},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify entity details render
    expect(find.text('GreenExpress Logistics'), findsOneWidget);
    expect(find.text('contact@greenexpress.com'), findsOneWidget);

    // Find Reject button
    final rejectFinder = find.byKey(const Key('reject_button'));
    expect(rejectFinder, findsOneWidget);

    // Initially, Reject button should be disabled
    ElevatedButton rejectButtonWidget = tester.widget(rejectFinder) as ElevatedButton;
    expect(rejectButtonWidget.onPressed, isNull);

    // Enter rejection reason in text field
    final textFieldFinder = find.byKey(const Key('rejection_reason_field'));
    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, 'Incomplete business registration document');
    await tester.pump();

    // Now Reject button should be enabled
    rejectButtonWidget = tester.widget(rejectFinder) as ElevatedButton;
    expect(rejectButtonWidget.onPressed, isNotNull);

    // Tap Reject button
    await tester.tap(rejectFinder);
    await tester.pumpAndSettle();

    // Verify decision submission called on repository
    expect(fakeRepo.submitCalled, isTrue);
    expect(fakeRepo.submittedStatus, equals('REJECTED'));
    expect(fakeRepo.submittedReason, equals('Incomplete business registration document'));
  });
}
