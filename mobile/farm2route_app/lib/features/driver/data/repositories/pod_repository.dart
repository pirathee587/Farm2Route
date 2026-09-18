import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/pod_model.dart';

class PodRepository {
  final ApiClient _apiClient;

  PodRepository(this._apiClient);

  Future<PodModel> submitPod({
    required String bookingId,
    required String recipientName,
    required String recipientPhone,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? notes,
    required List<int> signatureBytes,
    String signatureFilename = 'signature.png',
    required List<int> photoBytes,
    String photoFilename = 'delivery_photo.jpg',
    void Function(int count, int total)? onSendProgress,
  }) async {
    final jsonPayload = jsonEncode({
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'notes': notes,
    });

    final formData = FormData.fromMap({
      'data': MultipartFile.fromString(
        jsonPayload,
        contentType: DioMediaType('application', 'json'),
      ),
      'signature': MultipartFile.fromBytes(
        signatureBytes,
        filename: signatureFilename,
        contentType: DioMediaType('image', 'png'),
      ),
      'photo': MultipartFile.fromBytes(
        photoBytes,
        filename: photoFilename,
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    final response = await _apiClient.postMultipart(
      ApiEndpoints.bookingPod(bookingId),
      formData,
      onSendProgress: onSendProgress,
    );

    if (response is Map<String, dynamic>) {
      return PodModel.fromJson(response);
    }
    return PodModel.fromJson({});
  }

  Future<PodModel?> getPod(String bookingId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.bookingPod(bookingId));
      if (response != null && response is Map<String, dynamic>) {
        return PodModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }
}

final podRepositoryProvider = Provider<PodRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PodRepository(apiClient);
});
