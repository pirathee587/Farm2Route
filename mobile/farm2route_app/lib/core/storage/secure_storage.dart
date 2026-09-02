import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: AppConstants.keyUserRole, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.keyUserRole);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
