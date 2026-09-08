class AgencySignupRequest {
  final String agencyName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String agencyType;
  final String? businessRegNumber;
  final String district;
  final String address;
  final String? contactPersonName;

  const AgencySignupRequest({
    required this.agencyName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.agencyType,
    this.businessRegNumber,
    required this.district,
    required this.address,
    this.contactPersonName,
  });

  Map<String, dynamic> toJson() {
    return {
      'agencyName': agencyName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
      'agencyType': agencyType,
      if (businessRegNumber != null && businessRegNumber!.trim().isNotEmpty)
        'businessRegNumber': businessRegNumber!.trim(),
      'district': district,
      'address': address,
      if (contactPersonName != null && contactPersonName!.trim().isNotEmpty)
        'contactPersonName': contactPersonName!.trim(),
    };
  }

  factory AgencySignupRequest.fromJson(Map<String, dynamic> json) {
    return AgencySignupRequest(
      agencyName: json['agencyName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
      confirmPassword: json['confirmPassword'] as String,
      agencyType: json['agencyType'] as String,
      businessRegNumber: json['businessRegNumber'] as String?,
      district: json['district'] as String,
      address: json['address'] as String,
      contactPersonName: json['contactPersonName'] as String?,
    );
  }
}
