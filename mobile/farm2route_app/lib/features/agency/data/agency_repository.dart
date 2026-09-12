import '../../../core/network/api_client.dart';

class AgencyRepository {
  final ApiClient _client;
  AgencyRepository(this._client);

  Future<dynamic> getDashboard() => _client.get('/agency/dashboard');
  Future<dynamic> getProfile() => _client.get('/agency/profile');
  Future<dynamic> updateProfile(Map<String, dynamic> body) =>
      _client.put('/agency/profile', data: body);
  Future<List<dynamic>> list(String resource) async =>
      List<dynamic>.from(await _client.get('/agency/$resource') as List);
  Future<dynamic> detail(String resource, String id) =>
      _client.get('/agency/$resource/$id');
  Future<dynamic> create(String resource, Map<String, dynamic> body) =>
      _client.post('/agency/$resource', data: body);
  Future<dynamic> update(
          String resource, String id, Map<String, dynamic> body) =>
      _client.put('/agency/$resource/$id', data: body);
  Future<void> remove(String resource, String id) async {
    await _client.delete('/agency/$resource/$id');
  }

  Future<List<dynamic>> getDrivers() async =>
      List<dynamic>.from(await _client.get('/agency/drivers') as List);
  Future<List<dynamic>> getAvailableDrivers() async => List<dynamic>.from(
      await _client.get('/agency/drivers/available') as List);
  Future<dynamic> getDriver(String id) => _client.get('/agency/drivers/$id');
  Future<dynamic> createDriver(Map<String, dynamic> body) =>
      _client.post('/agency/drivers', data: body);
  Future<dynamic> updateDriver(String id, Map<String, dynamic> body) =>
      _client.put('/agency/drivers/$id', data: body);
  Future<void> deleteDriver(String id) async =>
      _client.delete('/agency/drivers/$id');
  Future<dynamic> submitDriverKyc(String id, Map<String, dynamic> body) =>
      _client.patch('/agency/drivers/$id/kyc', data: body);
  Future<dynamic> getDriverDocument(String id) =>
      _client.get('/agency/drivers/$id/kyc/document');
  Future<List<dynamic>> getDriverReviews(String id) async => List<dynamic>.from(
      await _client.get('/agency/drivers/$id/reviews') as List);

  Future<List<dynamic>> getVehicles() async =>
      List<dynamic>.from(await _client.get('/agency/vehicles') as List);
  Future<dynamic> getVehicle(String id) => _client.get('/agency/vehicles/$id');
  Future<dynamic> createVehicle(Map<String, dynamic> body) =>
      _client.post('/agency/vehicles', data: body);
  Future<dynamic> updateVehicle(String id, Map<String, dynamic> body) =>
      _client.put('/agency/vehicles/$id', data: body);
  Future<void> deleteVehicle(String id) async =>
      _client.delete('/agency/vehicles/$id');
  Future<dynamic> getVehicleKyc(String id) =>
      _client.get('/agency/vehicles/$id/kyc');
  Future<dynamic> updateVehicleKyc(String id, Map<String, dynamic> body) =>
      _client.patch('/agency/vehicles/$id/kyc', data: body);

  Future<List<dynamic>> getPackages() async =>
      List<dynamic>.from(await _client.get('/agency/packages') as List);
  Future<dynamic> getPackage(String id) => _client.get('/agency/packages/$id');
  Future<dynamic> createPackage(Map<String, dynamic> body) =>
      _client.post('/agency/packages', data: body);
  Future<dynamic> updatePackage(String id, Map<String, dynamic> body) =>
      _client.put('/agency/packages/$id', data: body);
  Future<void> deletePackage(String id) async =>
      _client.delete('/agency/packages/$id');
  Future<dynamic> acceptBooking(String id) =>
      _client.post('/agency/bookings/$id/accept');
  Future<dynamic> rejectBooking(String id, {String? reason}) =>
      _client.post('/agency/bookings/$id/reject',
          data: {'reason': reason ?? 'Rejected by agency'});
  Future<dynamic> recommendation(String id) =>
      _client.get('/agency/bookings/$id/assignment-recommendation');
  Future<dynamic> getAssignmentRecommendation(String id) => recommendation(id);
  Future<dynamic> assign(String id, String driverId, String vehicleId) =>
      _client.post('/agency/bookings/$id/assign',
          data: {'driverId': driverId, 'vehicleId': vehicleId});
  Future<dynamic> assignBooking(String id, String driverId, String vehicleId) =>
      assign(id, driverId, vehicleId);
  Future<List<dynamic>> getBookings() async =>
      List<dynamic>.from(await _client.get('/agency/bookings') as List);
  Future<dynamic> getBooking(String id) async {
    final bookings = await getBookings();
    return bookings
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .firstWhere(
          (item) => '${item['id']}' == id,
          orElse: () => <String, dynamic>{},
        );
  }

  Future<dynamic> financeSummary() => _client.get('/agency/finance/summary');
  Future<List<dynamic>> transactions() async => List<dynamic>.from(
      await _client.get('/agency/finance/transactions') as List);
  Future<List<dynamic>> withdrawals() async => List<dynamic>.from(
      await _client.get('/agency/finance/withdrawals') as List);
  Future<dynamic> withdraw(Map<String, dynamic> body) =>
      _client.post('/agency/finance/withdrawals', data: body);
  Future<List<dynamic>> reviews() async =>
      List<dynamic>.from(await _client.get('/agency/reviews') as List);
  Future<List<dynamic>> getAgencyReviews() async =>
      List<dynamic>.from(await _client.get('/agency/reviews') as List);
  Future<dynamic> respondToReview(String reviewId, String response) => _client
      .put('/agency/reviews/$reviewId/response', data: {'response': response});
  Future<List<dynamic>> notifications() async =>
      List<dynamic>.from(await _client.get('/agency/notifications') as List);
  Future<List<dynamic>> getNotifications() async =>
      List<dynamic>.from(await _client.get('/agency/notifications') as List);
  Future<int> getUnreadNotificationCount() async {
    final data = await _client.get('/agency/notifications/unread-count');
    if (data is num) return data.toInt();
    if (data is Map) {
      final value = data['unreadCount'] ?? data['count'];
      return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    }
    return int.tryParse('$data') ?? 0;
  }

  Future<dynamic> markNotificationRead(String id) =>
      _client.patch('/agency/notifications/$id/read');
  Future<dynamic> unreadCount() =>
      _client.get('/agency/notifications/unread-count');
  Future<void> markRead(String id) async {
    await _client.patch('/agency/notifications/$id/read');
  }

  Future<List<dynamic>> maintenance() async => List<dynamic>.from(
      await _client.get('/agency/maintenance/in-progress') as List);
  Future<List<dynamic>> getVehicleMaintenance(String vehicleId) async =>
      List<dynamic>.from(
          await _client.get('/agency/vehicles/$vehicleId/maintenance') as List);
  Future<dynamic> createMaintenance(
          String vehicleId, Map<String, dynamic> body) =>
      _client.post('/agency/vehicles/$vehicleId/maintenance', data: body);
  Future<dynamic> updateMaintenance(
          String maintenanceId, Map<String, dynamic> body) =>
      _client.put('/agency/maintenance/$maintenanceId', data: body);
}
