class AppConstants {
  static const String appName = 'Farm2Route';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyAccessToken = 'f2r_access_token';
  static const String keyRefreshToken = 'f2r_refresh_token';
  static const String keyUserRole = 'f2r_user_role';
  static const String keyUserData = 'f2r_user_data';

  // API Timeout
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
