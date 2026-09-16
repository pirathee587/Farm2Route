class RouteNames {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String agencySignup = '/agency/signup';
  static const String agencySignupForm = '/agency/signup/form';
  static const String agencyVerify = '/agency/signup/verify';
  static const String agencyPendingReview = '/agency/signup/pending';
  static const String farmerLanding = '/farmer/welcome';
  static const String farmerLogin = '/farmer/login';
  static const String farmerPhoneEntry = '/farmer/signup/phone';
  static const String farmerOtpVerify = '/farmer/signup/otp';
  static const String farmerDetails = '/farmer/signup/details';
  static const String verifyOtp = '/verify-otp';

  // Role Dashboards
  static const String farmerHome = '/farmer';
  static const String agencyHome = '/agency/dashboard';
  static const String agencyDrivers = '/agency/drivers';
  static const String agencyVehicles = '/agency/vehicles';
  static const String agencyPackages = '/agency/packages';
  static const String agencyBookings = '/agency/bookings';
  static const String agencyAssignments = '/agency/assignments';
  static const String agencyMaintenance = '/agency/maintenance';
  static const String agencyFinance = '/agency/finance';
  static const String agencyReviews = '/agency/reviews';
  static const String agencyNotifications = '/agency/notifications';
  static const String agencyProfile = '/agency/profile';
  static const String agencyProfileEdit = '/agency/profile/edit';
  static const String driverHome = '/driver';
  static const String adminHome = '/admin';

  // Features
  static const String farmerHaulerResults = '/farmer/haulers';
  static const String farmerPackageDetails = '/farmer/package/details';
  static const String bookingCreate = '/farmer/booking/create';
  static const String bookingHistory = '/farmer/bookings';
  static const String trackingLive = '/tracking';
  static const String incidentReport = '/incident/report';
  static const String podSubmit = '/driver/pod/submit';
  static String podSubmitWithId(String bookingId) => '/driver/pod/submit/$bookingId';
  static const String farmerPodReview = '/farmer/pod/review';
  static String farmerPodReviewWithId(String bookingId) => '/farmer/pod/review/$bookingId';
  static const String notifications = '/notifications';
  static const String adminKyc = '/admin/kyc';
  static const String adminIncidents = '/admin/incidents';
  static const String adminReviews = '/admin/reviews';
  static const String adminAuditLogs = '/admin/audit-logs';
}
