import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storage;

  ApiClient({required this.storage, void Function()? onSessionExpired}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(dio, storage, onSessionExpired: onSessionExpired),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await dio.post(path, data: data);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await dio.put(path, data: data);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  dynamic _processResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      if (map.containsKey('data')) {
        return map['data'];
      }
      return map;
    }
    return response.data;
  }

  AppException _handleDioError(DioException e) {
    if (e.response != null && e.response?.data is Map) {
      final errorMap = e.response!.data as Map;
      final message = errorMap['message'] ?? 'An error occurred';
      return AppException(message.toString(), statusCode: e.response?.statusCode);
    }
    return NetworkException(e.message ?? 'Network connection error');
  }
}
