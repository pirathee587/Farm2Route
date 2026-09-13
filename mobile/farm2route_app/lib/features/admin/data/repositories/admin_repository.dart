import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/admin_stats_model.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<AdminStatsModel> getStats() async {
    final response = await _apiClient.get(ApiEndpoints.adminStats);
    if (response is Map<String, dynamic>) {
      return AdminStatsModel.fromJson(response);
    }
    throw Exception('Failed to parse admin stats response');
  }
}
