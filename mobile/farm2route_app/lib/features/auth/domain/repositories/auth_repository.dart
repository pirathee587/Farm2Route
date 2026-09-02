import '../../data/models/auth_response_model.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  });

  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  });

  Future<AuthResponseModel> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String purpose,
  });

  Future<void> logout();

  Future<UserModel> getMe();

  Future<bool> checkAuthStatus();

  Future<String?> getCurrentRole();
}
