import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/models/pod_model.dart';
import '../../data/repositories/pod_repository.dart';

class PodSubmissionState {
  final bool isSubmitting;
  final double uploadProgress;
  final PodModel? submittedPod;
  final String? errorMessage;
  final bool isNotAssignedError;

  const PodSubmissionState({
    this.isSubmitting = false,
    this.uploadProgress = 0.0,
    this.submittedPod,
    this.errorMessage,
    this.isNotAssignedError = false,
  });

  PodSubmissionState copyWith({
    bool? isSubmitting,
    double? uploadProgress,
    PodModel? submittedPod,
    String? errorMessage,
    bool? isNotAssignedError,
  }) {
    return PodSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      submittedPod: submittedPod ?? this.submittedPod,
      errorMessage: errorMessage,
      isNotAssignedError: isNotAssignedError ?? this.isNotAssignedError,
    );
  }
}

class PodSubmissionNotifier extends StateNotifier<PodSubmissionState> {
  final PodRepository _repository;

  PodSubmissionNotifier(this._repository) : super(const PodSubmissionState());

  Future<bool> submitPod({
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
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      uploadProgress: 0.0,
      errorMessage: null,
      isNotAssignedError: false,
    );

    try {
      final pod = await _repository.submitPod(
        bookingId: bookingId,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        notes: notes,
        signatureBytes: signatureBytes,
        signatureFilename: signatureFilename,
        photoBytes: photoBytes,
        photoFilename: photoFilename,
        onSendProgress: (count, total) {
          if (total > 0 && mounted) {
            state = state.copyWith(uploadProgress: count / total);
          }
        },
      );

      state = state.copyWith(
        isSubmitting: false,
        uploadProgress: 1.0,
        submittedPod: pod,
      );
      return true;
    } catch (e) {
      final is403 = (e is AppException && e.statusCode == 403) ||
          e.toString().toLowerCase().contains('403') ||
          e.toString().toLowerCase().contains('assigned');

      final errorMsg = is403
          ? 'Access Denied: You are not assigned as the active driver for this booking trip.'
          : (e is AppException ? e.message : e.toString());

      state = state.copyWith(
        isSubmitting: false,
        uploadProgress: 0.0,
        errorMessage: errorMsg,
        isNotAssignedError: is403,
      );
      return false;
    }
  }

  void reset() {
    state = const PodSubmissionState();
  }
}

final podSubmissionProvider =
    StateNotifierProvider.autoDispose<PodSubmissionNotifier, PodSubmissionState>((ref) {
  final repository = ref.watch(podRepositoryProvider);
  return PodSubmissionNotifier(repository);
});
