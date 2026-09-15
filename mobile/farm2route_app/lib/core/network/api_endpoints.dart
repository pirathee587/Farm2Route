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
  static String bookingPod(String bookingId) => '/bookings/$bookingId/pod';

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
  static const String adminKycAgencies = '/admin/kyc/agencies';
  static const String adminKycDrivers = '/admin/kyc/drivers';
  static const String adminKycVehicles = '/admin/kyc/vehicles';
  static String adminKycReview(String entityType) => '/admin/kyc/$entityType';

  static const String adminIncidents = '/admin/incidents';
  static String adminIncidentDetail(String id) => '/admin/incidents/$id';
  static String adminIncidentNotes(String id) => '/admin/incidents/$id/notes';
  static String adminIncidentResolve(String id) => '/admin/incidents/$id/resolve';
  static String adminIncidentEscalate(String id) => '/admin/incidents/$id/escalate';

  static String adminDisputeAgencyResponse(String id) => '/admin/disputes/$id/agency-response';
  static String adminDisputeRefund(String id) => '/admin/disputes/$id/refund';

  static const String adminReportedReviews = '/admin/reviews/reported';
  static String adminHideReview(String id) => '/admin/reviews/$id/hide';
  static String adminRestoreReview(String id) => '/admin/reviews/$id/restore';
  static String adminEscalateReview(String id) => '/admin/reviews/$id/escalate';

  static const String adminAuditLogs = '/admin/audit-logs';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
}
