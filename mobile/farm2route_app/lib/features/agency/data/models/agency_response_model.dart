class AgencyResponseModel {
  final String id;
  final String agencyName;
  final String email;
  final String phoneNumber;
  final String agencyType;
  final String? businessRegNumber;
  final String district;
  final String address;
  final String? contactPersonName;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;
  final String? createdAt;
  final String? updatedAt;

  const AgencyResponseModel({
    required this.id,
    required this.agencyName,
    required this.email,
    required this.phoneNumber,
    required this.agencyType,
    this.businessRegNumber,
    required this.district,
    required this.address,
    this.contactPersonName,
    required this.status,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AgencyResponseModel.fromJson(Map<String, dynamic> json) {
    return AgencyResponseModel(
      id: json['id'] as String? ?? '',
      agencyName: json['agencyName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      agencyType: json['agencyType'] as String? ?? '',
      businessRegNumber: json['businessRegNumber'] as String?,
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactPersonName: json['contactPersonName'] as String?,
      status: json['status'] as String? ?? 'ACCOUNT_CREATED',
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agencyName': agencyName,
      'email': email,
      'phoneNumber': phoneNumber,
      'agencyType': agencyType,
      'businessRegNumber': businessRegNumber,
      'district': district,
      'address': address,
      'contactPersonName': contactPersonName,
      'status': status,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
