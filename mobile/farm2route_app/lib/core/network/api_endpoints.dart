class ApiEndpoints {
  // Base endpoint
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Farmer
  static const String farmerProfile = '/farmer/profile';
  static const String myBookings = '/bookings/my-bookings';
  static const String createBooking = '/bookings';

  // Agency
  static const String agencyProfile = '/agency/profile';

  // Driver
  static const String driverProfile = '/driver/profile';
  static const String driverAvailability = '/driver/availability';

  // Admin
  static const String adminStats = '/admin/stats';
}
