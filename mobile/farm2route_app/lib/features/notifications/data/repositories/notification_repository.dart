import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20}) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'size': size},
    );

    if (response is Map<String, dynamic> && response.containsKey('content')) {
      final List content = response['content'] as List? ?? [];
      return content.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return response.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.notificationsUnreadCount);
    if (response is Map<String, dynamic>) {
      final count = response['unreadCount'];
      if (count is num) {
        return count.toInt();
      }
    }
    return 0;
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.notificationRead(id));
    if (response is Map<String, dynamic>) {
      return NotificationModel.fromJson(response);
    }
    throw Exception('Failed to mark notification as read');
  }
}
