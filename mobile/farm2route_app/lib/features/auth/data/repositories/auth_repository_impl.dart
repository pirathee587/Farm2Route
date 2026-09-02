import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  }) async {
    return await remoteDataSource.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      role: role,
    );
  }

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      identifier: identifier,
      password: password,
    );
    if (response.accessToken != null) {
      await secureStorage.saveAccessToken(response.accessToken!);
    }
    if (response.refreshToken != null) {
      await secureStorage.saveRefreshToken(response.refreshToken!);
    }
    if (response.user != null) {
      await secureStorage.saveUserRole(response.user!.role);
    }
    return response;
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String purpose,
  }) async {
    final response = await remoteDataSource.verifyOtp(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
      purpose: purpose,
    );
    if (response.accessToken != null) {
      await secureStorage.saveAccessToken(response.accessToken!);
    }
    if (response.refreshToken != null) {
      await secureStorage.saveRefreshToken(response.refreshToken!);
    }
    if (response.user != null) {
      await secureStorage.saveUserRole(response.user!.role);
    }
    return response;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await secureStorage.getRefreshToken();
    try {
      await remoteDataSource.logout(refreshToken: refreshToken);
    } catch (_) {}
    await secureStorage.clearAll();
  }

  @override
  Future<UserModel> getMe() async {
    return await remoteDataSource.getMe();
  }

  @override
  Future<bool> checkAuthStatus() async {
    final accessToken = await secureStorage.getAccessToken();
    final refreshToken = await secureStorage.getRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  @override
  Future<String?> getCurrentRole() async {
    return await secureStorage.getUserRole();
  }
}
