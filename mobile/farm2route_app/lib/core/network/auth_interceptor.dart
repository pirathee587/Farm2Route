import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  final void Function()? onSessionExpired;

  AuthInterceptor(this._dio, this._storage, {this.onSessionExpired});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/')) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Attempt refreshing access token
          final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 && response.data['success'] == true) {
            final newAccessToken = response.data['data']['accessToken'];
            final newRefreshToken = response.data['data']['refreshToken'];

            await _storage.saveAccessToken(newAccessToken);
            if (newRefreshToken != null) {
              await _storage.saveRefreshToken(newRefreshToken);
            }

            // Retry original request with fresh access token
            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final cloneReq = await _dio.fetch(requestOptions);
            return handler.resolve(cloneReq);
          }
        } catch (e) {
          // Token refresh failed completely -> clear storage and trigger session expiry
          await _storage.clearAll();
          if (onSessionExpired != null) {
            onSessionExpired!();
          }
        }
      } else {
        await _storage.clearAll();
        if (onSessionExpired != null) {
          onSessionExpired!();
        }
      }
    }
    return handler.next(err);
  }
}
