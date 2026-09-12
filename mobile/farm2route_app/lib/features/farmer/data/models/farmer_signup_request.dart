class FarmerSignupRequest {
  final String phoneNumber;
  final String otp;
  final String fullName;
  final String? email;
  final String district;
  final String? gnDivision;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? farmSizeAcres;
  final List<String> primaryCrops;
  final String preferredLanguage;
  final String? bankAccountNumber;
  final String? mobileWalletNumber;
  final String? nicNumber;

  const FarmerSignupRequest({
    required this.phoneNumber,
    required this.otp,
    required this.fullName,
    this.email,
    required this.district,
    this.gnDivision,
    this.address,
    this.latitude,
    this.longitude,
    this.farmSizeAcres,
    this.primaryCrops = const [],
    this.preferredLanguage = 'TA',
    this.bankAccountNumber,
    this.mobileWalletNumber,
    this.nicNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phoneNumber': phoneNumber,
      'otp': otp,
      'fullName': fullName,
      'district': district,
      'preferredLanguage': preferredLanguage,
      'primaryCrops': primaryCrops,
    };

    if (email != null && email!.trim().isNotEmpty) {
      map['email'] = email!.trim();
    }
    if (gnDivision != null && gnDivision!.trim().isNotEmpty) {
      map['gnDivision'] = gnDivision!.trim();
    }
    if (address != null && address!.trim().isNotEmpty) {
      map['address'] = address!.trim();
    }
    if (latitude != null) {
      map['latitude'] = latitude;
    }
    if (longitude != null) {
      map['longitude'] = longitude;
    }
    if (farmSizeAcres != null && farmSizeAcres! > 0) {
      map['farmSizeAcres'] = farmSizeAcres;
    }
    if (bankAccountNumber != null && bankAccountNumber!.trim().isNotEmpty) {
      map['bankAccountNumber'] = bankAccountNumber!.trim();
    }
    if (mobileWalletNumber != null && mobileWalletNumber!.trim().isNotEmpty) {
      map['mobileWalletNumber'] = mobileWalletNumber!.trim();
    }
    if (nicNumber != null && nicNumber!.trim().isNotEmpty) {
      map['nicNumber'] = nicNumber!.trim();
    }

    return map;
  }
}
