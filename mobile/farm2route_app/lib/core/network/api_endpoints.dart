import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Base endpoint
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api/v1';
      default:
        return 'http://localhost:8080/api/v1';
    }
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Farmer
  static const String farmerProfile = '/farmer/profile';
  static const String farmerSignupRequestOtp = '/farmers/signup/request-otp';
  static const String farmerSignupVerify = '/farmers/signup/verify';
  static const String myBookings = '/bookings/my-bookings';
  static const String createBooking = '/bookings';

  // Dispatch & Haulers
  static const String dispatchAvailability = '/dispatch/availability';
  static const String dispatchEstimateFare = '/dispatch/estimate-fare';
  static const String dispatchFindHaulers = '/dispatch/find-haulers';

  // Packages & Subscriptions
  static const String packages = '/packages';
  static String farmerSubscriptions(String farmerId) => '/farmers/$farmerId/subscriptions';

  // Agency
  static const String agencyProfile = '/agency/profile';
  static const String agencySignup = '/agencies/signup';
  static const String agencyVerifyEmail = '/agencies/verify-email';
  static const String agencyVerifyPhone = '/agencies/verify-phone';
  static String agencyResendEmail(String id) => '/agencies/$id/resend-email';
  static String agencyResendPhoneOtp(String id) => '/agencies/$id/resend-otp';
  static String agencyStatus(String id) => '/agencies/$id/status';

  // Driver
  static const String driverProfile = '/driver/profile';
  static const String driverAvailability = '/driver/availability';

  // Admin
  static const String adminStats = '/admin/stats';
}
