class OtpVerifyRequest {
  final String phoneNumber;
  final String otp;

  const OtpVerifyRequest({
    required this.phoneNumber,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'otp': otp,
    };
  }
}
