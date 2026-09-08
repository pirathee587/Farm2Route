import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/farmer_response_model.dart';
import '../../data/models/farmer_signup_request.dart';
import '../../data/repositories/farmer_repository_impl.dart';
import '../../domain/repositories/farmer_repository.dart';

enum FarmerSignupStatus { initial, requestingOtp, otpSent, submitting, success, error }

class FarmerSignupState {
  final FarmerSignupStatus status;
  final String? phoneNumber;
  final String? otp;
  final String? errorMessage;
  final FarmerResponseModel? response;
  final double? latitude;
  final double? longitude;
  final List<String> selectedCrops;
  final String? district;

  const FarmerSignupState({
    this.status = FarmerSignupStatus.initial,
    this.phoneNumber,
    this.otp,
    this.errorMessage,
    this.response,
    this.latitude,
    this.longitude,
    this.selectedCrops = const [],
    this.district,
  });

  FarmerSignupState copyWith({
    FarmerSignupStatus? status,
    String? phoneNumber,
    String? otp,
    String? errorMessage,
    FarmerResponseModel? response,
    double? latitude,
    double? longitude,
    List<String>? selectedCrops,
    String? district,
  }) {
    return FarmerSignupState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otp: otp ?? this.otp,
      errorMessage: errorMessage,
      response: response ?? this.response,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selectedCrops: selectedCrops ?? this.selectedCrops,
      district: district ?? this.district,
    );
  }
}

class FarmerSignupNotifier extends StateNotifier<FarmerSignupState> {
  final FarmerRepository _repository;
  final SecureStorageService _secureStorage;
  final AuthNotifier _authNotifier;

  FarmerSignupNotifier({
    required FarmerRepository repository,
    required SecureStorageService secureStorage,
    required AuthNotifier authNotifier,
  })  : _repository = repository,
        _secureStorage = secureStorage,
        _authNotifier = authNotifier,
        super(const FarmerSignupState());

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void setOtp(String otp) {
    state = state.copyWith(otp: otp);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
  }

  void toggleCrop(String crop) {
    final current = List<String>.from(state.selectedCrops);
    if (current.contains(crop)) {
      current.remove(crop);
    } else {
      current.add(crop);
    }
    state = state.copyWith(selectedCrops: current);
  }

  void setDistrict(String district) {
    state = state.copyWith(district: district);
  }

  Future<bool> requestOtp(String phoneNumber) async {
    state = state.copyWith(
      status: FarmerSignupStatus.requestingOtp,
      phoneNumber: phoneNumber,
      errorMessage: null,
    );

    try {
      await _repository.requestOtp(phoneNumber);
      state = state.copyWith(status: FarmerSignupStatus.otpSent);
      return true;
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = state.copyWith(
        status: FarmerSignupStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  bool holdOtp(String otp) {
    if (otp.trim().length != 6) {
      state = state.copyWith(
        status: FarmerSignupStatus.error,
        errorMessage: 'Please enter a valid 6-digit OTP code',
      );
      return false;
    }
    state = state.copyWith(
      otp: otp.trim(),
      errorMessage: null,
    );
    return true;
  }

  Future<bool> completeSignup(FarmerSignupRequest request) async {
    state = state.copyWith(
      status: FarmerSignupStatus.submitting,
      errorMessage: null,
    );

    try {
      final response = await _repository.verifyAndSignup(request);

      if (response.token != null && response.token!.isNotEmpty) {
        await _secureStorage.saveAccessToken(response.token!);
        await _secureStorage.saveUserRole('FARMER');

        // Update global auth state to authenticated
        _authNotifier.state = _authNotifier.state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel(
            id: response.id,
            phoneNumber: response.phoneNumber,
            email: response.email,
            fullName: response.fullName,
            role: 'FARMER',
            status: response.status,
            isPhoneVerified: response.phoneVerified,
            isEmailVerified: false,
          ),
        );
      }

      state = state.copyWith(
        status: FarmerSignupStatus.success,
        response: response,
      );
      return true;
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = state.copyWith(
        status: FarmerSignupStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  void reset() {
    state = const FarmerSignupState();
  }
}

final farmerRepositoryProvider = Provider<FarmerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FarmerRepositoryImpl(apiClient);
});

final farmerSignupProvider =
    StateNotifierProvider<FarmerSignupNotifier, FarmerSignupState>((ref) {
  final repository = ref.watch(farmerRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  return FarmerSignupNotifier(
    repository: repository,
    secureStorage: secureStorage,
    authNotifier: authNotifier,
  );
});
