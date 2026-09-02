class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  AppException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message, {int? statusCode})
      : super(message, statusCode: statusCode, errorType: 'NetworkError');
}

class AuthException extends AppException {
  AuthException(String message, {int? statusCode})
      : super(message, statusCode: statusCode, errorType: 'AuthError');
}
