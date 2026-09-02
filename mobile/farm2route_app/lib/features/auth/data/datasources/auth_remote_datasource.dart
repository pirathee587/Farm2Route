import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
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

  Future<void> logout({String? refreshToken});

  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return AuthResponseModel.fromJson(response);
  }

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'identifier': identifier,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response);
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String purpose,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
        'purpose': purpose,
      },
    );
    return AuthResponseModel.fromJson(response);
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    await apiClient.post(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  @override
  Future<UserModel> getMe() async {
    final response = await apiClient.get(ApiEndpoints.me);
    return UserModel.fromJson(response);
  }
}
