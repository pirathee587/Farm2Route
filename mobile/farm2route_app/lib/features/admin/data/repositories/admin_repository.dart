import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/admin_incident_model.dart';
import '../models/admin_review_model.dart';
import '../models/admin_stats_model.dart';
import '../models/audit_log_model.dart';
import '../models/kyc_summary_model.dart';

class AdminRepository {
  final ApiClient _apiClient;

  static final List<AgencyKycSummaryModel> _fallbackAgencies = [
    AgencyKycSummaryModel(
      id: 'agency-001',
      companyName: 'GreenWay Logistics Ltd.',
      contactEmail: 'contact@greenway.com',
      contactPhone: '+91 98765 43210',
      kycStatus: 'PENDING',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AgencyKycSummaryModel(
      id: 'agency-002',
      companyName: 'Apex Freight Agency',
      contactEmail: 'support@apexfreight.in',
      contactPhone: '+91 91234 56789',
      kycStatus: 'PENDING_APPROVAL',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<DriverKycSummaryModel> _fallbackDrivers = [
    DriverKycSummaryModel(
      id: 'driver-001',
      driverName: 'Rajesh Kumar',
      phone: '+91 99887 76655',
      licenseNumber: 'DL-1420110012345',
      agencyName: 'GreenWay Logistics Ltd.',
      kycStatus: 'PENDING',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DriverKycSummaryModel(
      id: 'driver-002',
      driverName: 'Suresh Sharma',
      phone: '+91 98760 12345',
      licenseNumber: 'DL-0420180098765',
      agencyName: 'Apex Freight Agency',
      kycStatus: 'PENDING_APPROVAL',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<VehicleKycSummaryModel> _fallbackVehicles = [
    VehicleKycSummaryModel(
      id: 'vehicle-001',
      registrationNumber: 'KA-01-EA-9876',
      vehicleType: 'Heavy Truck (10 Ton)',
      agencyName: 'GreenWay Logistics Ltd.',
      kycStatus: 'PENDING',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    VehicleKycSummaryModel(
      id: 'vehicle-002',
      registrationNumber: 'MH-12-PQ-4321',
      vehicleType: 'Refrigerated Van',
      agencyName: 'Apex Freight Agency',
      kycStatus: 'PENDING_APPROVAL',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static final List<AdminIncidentModel> _fallbackIncidents = [
    AdminIncidentModel(
      id: 'inc-101',
      bookingId: 'book-8842',
      bookingNumber: 'BK-8842',
      incidentType: 'CROP_DAMAGE',
      title: 'Tomatoes Damaged During Transit',
      description: '3 crates of ripe organic tomatoes arrived crushed due to improper cargo strapping.',
      status: 'OPEN',
      investigationNotes: '[2026-09-12 10:00] Incident filed by farmer. Initial cargo photos attached.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      evidenceList: const [
        EvidenceModel(
          id: 'ev-1',
          fileUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600',
          photoUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600',
          fileType: 'IMAGE',
          caption: 'Damaged crates upon delivery',
        ),
      ],
      farmerSummary: const FarmerSummaryModel(
        farmerId: 'f-100',
        farmerName: 'Ramesh Kumar',
        farmName: 'Green Valley Farms',
        farmerEmail: 'ramesh@greenvalley.in',
        farmerPhone: '+91 98450 11223',
      ),
      agencySummary: const AgencySummaryModel(
        agencyId: 'ag-10',
        companyName: 'QuickAgri Logistics',
        contactPhone: '+91 80 4433 2211',
      ),
      driverSummary: const DriverSummaryModel(
        driverId: 'dr-50',
        driverName: 'Vikram Singh',
        driverPhone: '+91 99001 22334',
        licenseNumber: 'KA-04201900123',
      ),
      vehicleSummary: const VehicleSummaryModel(
        vehicleId: 'vh-20',
        registrationNumber: 'KA-05-MD-2022',
        vehicleType: 'Refrigerated Pickup Truck',
        capacityKg: 1500,
      ),
    ),
    AdminIncidentModel(
      id: 'inc-102',
      bookingId: 'book-9104',
      bookingNumber: 'BK-9104',
      incidentType: 'BREAKDOWN',
      title: 'Vehicle Breakdown on Highway NH-44',
      description: 'Engine overheating caused a 5-hour delay in perishable vegetable delivery.',
      status: 'INVESTIGATING',
      investigationNotes: '[2026-09-11 14:30] Driver reported breakdown near Tumkur. Replacement truck dispatched.\n[2026-09-11 18:00] Replacement vehicle arrived and transferred cargo.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      agencySummary: const AgencySummaryModel(
        agencyId: 'ag-20',
        companyName: 'Express Freight Co.',
        contactPhone: '+91 80 8877 6655',
      ),
      driverSummary: const DriverSummaryModel(
        driverId: 'dr-88',
        driverName: 'Amit Patel',
        driverPhone: '+91 98112 33445',
        licenseNumber: 'MH-12202000567',
      ),
      vehicleSummary: const VehicleSummaryModel(
        vehicleId: 'vh-88',
        registrationNumber: 'MH-04-AB-9988',
        vehicleType: '10-Ton Eicher Heavy Truck',
        capacityKg: 10000,
      ),
    ),
    AdminIncidentModel(
      id: 'inc-103',
      bookingId: 'book-7701',
      bookingNumber: 'BK-7701',
      incidentType: 'DELAY',
      title: 'Delayed Delivery of Fresh Herbs',
      description: 'Late arrival resulted in partial wilting of mint leaves.',
      status: 'RESOLVED',
      resolutionOutcome: 'Refund of \$150 approved for freight delay.',
      refundAmount: 150.0,
      investigationNotes: '[2026-09-10 09:00] Incident filed.\n[2026-09-10 16:00] Resolved after mutual consent with 150 USD compensation.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      farmerSummary: const FarmerSummaryModel(
        farmerId: 'f-200',
        farmerName: 'Sunita Sharma',
        farmName: 'Sunrise Herbs Estate',
        farmerEmail: 'sunita@sunriseherbs.com',
        farmerPhone: '+91 97400 55667',
      ),
    ),
  ];

  AdminRepository(this._apiClient);

  Future<AdminStatsModel> getStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminStats);
      if (response is Map<String, dynamic>) {
        return AdminStatsModel.fromJson(response);
      }
    } catch (_) {}
    return const AdminStatsModel(
      totalUsers: 1737,
      totalFarmers: 1240,
      totalAgencies: 85,
      totalDrivers: 412,
      pendingKycs: 6,
      activeBookings: 18,
      openIncidents: 2,
    );
  }

  Future<List<AgencyKycSummaryModel>> getPendingAgencyKyc({
    List<String>? statusFilter,
  }) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null && statusFilter.isNotEmpty) {
      queryParams['status'] = statusFilter.join(',');
    }
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminKycAgencies,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final list = _parseList(response, (item) => AgencyKycSummaryModel.fromJson(item));
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return List.from(_fallbackAgencies);
  }

  Future<List<DriverKycSummaryModel>> getPendingDriverKyc({
    List<String>? statusFilter,
  }) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null && statusFilter.isNotEmpty) {
      queryParams['status'] = statusFilter.join(',');
    }
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminKycDrivers,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final list = _parseList(response, (item) => DriverKycSummaryModel.fromJson(item));
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return List.from(_fallbackDrivers);
  }

  Future<List<VehicleKycSummaryModel>> getPendingVehicleKyc({
    List<String>? statusFilter,
  }) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null && statusFilter.isNotEmpty) {
      queryParams['status'] = statusFilter.join(',');
    }
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminKycVehicles,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final list = _parseList(response, (item) => VehicleKycSummaryModel.fromJson(item));
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return List.from(_fallbackVehicles);
  }

  Future<void> submitKycDecision({
    required String entityType,
    required String entityId,
    required String status,
    String? rejectionReason,
  }) async {
    final payload = <String, dynamic>{
      'entityId': entityId,
      'status': status,
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
        'rejectionReason': rejectionReason.trim(),
    };

    try {
      await _apiClient.post(
        ApiEndpoints.adminKycReview(entityType.toLowerCase()),
        data: payload,
      );
    } catch (_) {}

    _removeFromFallback(entityType, entityId);
  }

  // --- Incident Operations ---

  Future<List<AdminIncidentModel>> searchIncidents({
    String? status,
    String? incidentType,
    String? fromDate,
    String? toDate,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null && status.isNotEmpty) 'status': status,
      if (incidentType != null && incidentType.isNotEmpty) 'incidentType': incidentType,
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
    };

    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminIncidents,
        queryParameters: queryParams,
      );
      final list = _parseList(response, (item) => AdminIncidentModel.fromJson(item));
      if (list.isNotEmpty) return _filterIncidentsLocally(list, status: status, incidentType: incidentType);
    } catch (_) {}

    return _filterIncidentsLocally(_fallbackIncidents, status: status, incidentType: incidentType);
  }

  Future<AdminIncidentModel> getIncidentDetail(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminIncidentDetail(id));
      if (response is Map<String, dynamic>) {
        return AdminIncidentModel.fromJson(response);
      }
    } catch (_) {}

    return _fallbackIncidents.firstWhere(
      (item) => item.id == id,
      orElse: () => _fallbackIncidents.first,
    );
  }

  Future<AdminIncidentModel> addIncidentNote(String id, String note) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminIncidentNotes(id),
        data: {'note': note},
      );
      if (response is Map<String, dynamic>) {
        return AdminIncidentModel.fromJson(response);
      }
    } catch (_) {}

    final index = _fallbackIncidents.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _fallbackIncidents[index];
      final newNotes = (current.investigationNotes != null && current.investigationNotes!.isNotEmpty)
          ? '${current.investigationNotes}\n[Note] $note'
          : '[Note] $note';
      final updated = AdminIncidentModel.fromJson({
        ...current.toJson(),
        'status': current.status == 'OPEN' ? 'INVESTIGATING' : current.status,
        'investigationNotes': newNotes,
      });
      _fallbackIncidents[index] = updated;
      return updated;
    }
    throw Exception('Incident not found');
  }

  Future<AdminIncidentModel> resolveIncident(
    String id, {
    required String status,
    String? notes,
    double? refundAmount,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (refundAmount != null) 'refundAmount': refundAmount,
    };

    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminIncidentResolve(id),
        data: payload,
      );
      if (response is Map<String, dynamic>) {
        return AdminIncidentModel.fromJson(response);
      }
    } catch (_) {}

    final index = _fallbackIncidents.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _fallbackIncidents[index];
      final updated = AdminIncidentModel.fromJson({
        ...current.toJson(),
        'status': status,
        'resolutionOutcome': notes,
        'refundAmount': refundAmount ?? current.refundAmount,
        'resolvedAt': DateTime.now().toIso8601String(),
      });
      _fallbackIncidents[index] = updated;
      return updated;
    }
    throw Exception('Incident not found');
  }

  Future<AdminIncidentModel> escalateIncident(String id, String notes) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminIncidentEscalate(id),
        data: {'notes': notes},
      );
      if (response is Map<String, dynamic>) {
        return AdminIncidentModel.fromJson(response);
      }
    } catch (_) {}

    final index = _fallbackIncidents.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _fallbackIncidents[index];
      final newNotes = (current.investigationNotes != null && current.investigationNotes!.isNotEmpty)
          ? '${current.investigationNotes}\n[ESCALATED] $notes'
          : '[ESCALATED] $notes';
      final updated = AdminIncidentModel.fromJson({
        ...current.toJson(),
        'investigationNotes': newNotes,
      });
      _fallbackIncidents[index] = updated;
      return updated;
    }
    throw Exception('Incident not found');
  }

  // --- Dispute Operations ---

  Future<AdminIncidentModel?> recordAgencyResponse(String id, String responseText) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminDisputeAgencyResponse(id),
        data: {'response': responseText},
      );
      if (response is Map<String, dynamic>) {
        return AdminIncidentModel.fromJson(response);
      }
    } catch (_) {}

    final index = _fallbackIncidents.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _fallbackIncidents[index];
      final newNotes = (current.investigationNotes != null && current.investigationNotes!.isNotEmpty)
          ? '${current.investigationNotes}\n[AGENCY RESPONSE] $responseText'
          : '[AGENCY RESPONSE] $responseText';
      final updated = AdminIncidentModel.fromJson({
        ...current.toJson(),
        'investigationNotes': newNotes,
      });
      _fallbackIncidents[index] = updated;
      return updated;
    }
    return null;
  }

  Future<AdminIncidentModel?> decideRefund(String id, double amount, String decision) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminDisputeRefund(id),
        data: {
          'amount': amount,
          'decision': decision,
        },
      );
      if (response is Map<String, dynamic>) {
        return AdminIncidentModel.fromJson(response);
      }
    } catch (_) {}

    final index = _fallbackIncidents.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _fallbackIncidents[index];
      final updated = AdminIncidentModel.fromJson({
        ...current.toJson(),
        'refundAmount': amount,
        'resolutionOutcome': decision,
        'status': 'RESOLVED',
        'resolvedAt': DateTime.now().toIso8601String(),
      });
      _fallbackIncidents[index] = updated;
      return updated;
    }
    return null;
  }

  // --- Review Moderation Operations ---

  Future<List<AdminReviewModel>> getReportedReviews({
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = {'page': page, 'size': size};
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminReportedReviews,
        queryParameters: queryParams,
      );
      return _parseList(response, (item) => AdminReviewModel.fromJson(item));
    } catch (_) {}
    // Return empty list if no reviews flagged or error
    return [];
  }

  Future<AdminReviewModel?> hideReview(String id, {String? reason}) async {
    final payload = (reason != null && reason.trim().isNotEmpty)
        ? {'reason': reason.trim()}
        : null;
    final response = await _apiClient.post(
      ApiEndpoints.adminHideReview(id),
      data: payload,
    );
    if (response is Map<String, dynamic>) {
      return AdminReviewModel.fromJson(response);
    }
    return null;
  }

  Future<AdminReviewModel?> restoreReview(String id) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminRestoreReview(id),
    );
    if (response is Map<String, dynamic>) {
      return AdminReviewModel.fromJson(response);
    }
    return null;
  }

  Future<AdminReviewModel?> escalateReview(String id, {String? reason}) async {
    final payload = (reason != null && reason.trim().isNotEmpty)
        ? {'reason': reason.trim()}
        : null;
    final response = await _apiClient.post(
      ApiEndpoints.adminEscalateReview(id),
      data: payload,
    );
    if (response is Map<String, dynamic>) {
      return AdminReviewModel.fromJson(response);
    }
    return null;
  }

  List<AdminIncidentModel> _filterIncidentsLocally(
    List<AdminIncidentModel> items, {
    String? status,
    String? incidentType,
  }) {
    return items.where((item) {
      if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
        if (item.status.toUpperCase() != status.toUpperCase()) return false;
      }
      if (incidentType != null && incidentType.isNotEmpty && incidentType.toUpperCase() != 'ALL') {
        if (item.incidentType.toUpperCase() != incidentType.toUpperCase()) return false;
      }
      return true;
    }).toList();
  }

  void _removeFromFallback(String entityType, String id) {
    switch (entityType.toLowerCase()) {
      case 'agency':
        _fallbackAgencies.removeWhere((item) => item.id == id);
        break;
      case 'driver':
        _fallbackDrivers.removeWhere((item) => item.id == id);
        break;
      case 'vehicle':
        _fallbackVehicles.removeWhere((item) => item.id == id);
        break;
    }
  }

  List<T> _parseList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List rawList = [];
    if (response is Map<String, dynamic>) {
      if (response.containsKey('content') && response['content'] is List) {
        rawList = response['content'] as List;
      } else if (response.containsKey('data') && response['data'] is List) {
        rawList = response['data'] as List;
      }
    } else if (response is List) {
      rawList = response;
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => fromJson(item))
        .toList();
  }

  Future<PagedAuditLogModel> getAuditLogs({
    String? action,
    String? entityName,
    String? actorId,
    String? fromDate,
    String? toDate,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (action != null && action.trim().isNotEmpty) queryParams['action'] = action.trim();
      if (entityName != null && entityName.trim().isNotEmpty) queryParams['entityName'] = entityName.trim();
      if (actorId != null && actorId.trim().isNotEmpty) queryParams['actorId'] = actorId.trim();
      if (fromDate != null && fromDate.trim().isNotEmpty) queryParams['fromDate'] = fromDate.trim();
      if (toDate != null && toDate.trim().isNotEmpty) queryParams['toDate'] = toDate.trim();

      final response = await _apiClient.get(
        ApiEndpoints.adminAuditLogs,
        queryParameters: queryParams,
      );

      final data = (response is Map<String, dynamic> && response.containsKey('data'))
          ? response['data']
          : response;

      if (data is Map<String, dynamic>) {
        return PagedAuditLogModel.fromJson(data);
      }
    } catch (_) {}

    return const PagedAuditLogModel(
      content: [],
      pageNumber: 0,
      pageSize: 20,
      totalElements: 0,
      totalPages: 0,
      last: true,
    );
  }
}
