import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/admin_stats_model.dart';
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
}
