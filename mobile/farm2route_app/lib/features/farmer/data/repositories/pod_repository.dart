import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/pod_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FarmerPodRepository {
  final ApiClient _apiClient;

  FarmerPodRepository(this._apiClient);

  /// Fetch POD details for a booking
  Future<PodModel?> getPod(String bookingId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.bookingPod(bookingId));
      if (response != null && response is Map<String, dynamic>) {
        return PodModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  /// Confirm or dispute POD status for a booking
  /// status: CONFIRMED or DISPUTED
  Future<PodModel> confirmPod({
    required String bookingId,
    required String status,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.confirmBookingPod(bookingId),
      data: {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response != null && response is Map<String, dynamic>) {
      return PodModel.fromJson(response);
    }
    return PodModel.fromJson({'bookingId': bookingId, 'farmerConfirmationStatus': status});
  }
}

final farmerPodRepositoryProvider = Provider<FarmerPodRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FarmerPodRepository(apiClient);
});
