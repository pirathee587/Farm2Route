class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  AppException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.statusCode})
      : super(errorType: 'NetworkError');
}

class AuthException extends AppException {
  AuthException(super.message, {super.statusCode})
      : super(errorType: 'AuthError');
}
