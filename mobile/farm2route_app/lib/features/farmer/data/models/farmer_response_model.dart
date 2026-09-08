class FarmerResponseModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String district;
  final String? gnDivision;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? farmSizeAcres;
  final List<String> primaryCrops;
  final String preferredLanguage;
  final bool phoneVerified;
  final String status;
  final String? token;
  final String tokenType;
  final String? createdAt;

  const FarmerResponseModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.district,
    this.gnDivision,
    this.address,
    this.latitude,
    this.longitude,
    this.farmSizeAcres,
    this.primaryCrops = const [],
    this.preferredLanguage = 'TA',
    this.phoneVerified = false,
    this.status = 'PENDING',
    this.token,
    this.tokenType = 'Bearer',
    this.createdAt,
  });

  factory FarmerResponseModel.fromJson(Map<String, dynamic> json) {
    return FarmerResponseModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      district: json['district'] as String? ?? '',
      gnDivision: json['gnDivision'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      farmSizeAcres: json['farmSizeAcres'] != null
          ? (json['farmSizeAcres'] as num).toDouble()
          : null,
      primaryCrops: json['primaryCrops'] != null
          ? List<String>.from(json['primaryCrops'] as List)
          : [],
      preferredLanguage: json['preferredLanguage'] as String? ?? 'TA',
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'PENDING',
      token: json['token'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      createdAt: json['createdAt'] as String?,
    );
  }
}
