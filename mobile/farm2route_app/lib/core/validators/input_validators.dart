class InputValidators {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final regex = RegExp(r'^\+?[0-9]{9,15}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid phone number (e.g. +94771234567)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().length != 6) {
      return 'Enter the 6-digit OTP';
    }
    return null;
  }
}
