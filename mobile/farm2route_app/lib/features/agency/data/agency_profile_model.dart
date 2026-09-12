class AgencyProfileModel {
  final String? id;
  final String? userId;
  final String companyName;
  final String businessRegistrationNumber;
  final String taxIdentificationNumber;
  final String officeAddress;
  final String district;
  final String contactPersonName;
  final String contactPersonPhone;
  final String? kycStatus;
  final String? kycDocumentUrl;
  final String? commissionRatePercentage;

  const AgencyProfileModel({
    this.id,
    this.userId,
    required this.companyName,
    required this.businessRegistrationNumber,
    required this.taxIdentificationNumber,
    required this.officeAddress,
    required this.district,
    required this.contactPersonName,
    required this.contactPersonPhone,
    this.kycStatus,
    this.kycDocumentUrl,
    this.commissionRatePercentage,
  });

  factory AgencyProfileModel.fromJson(Map<String, dynamic> json) {
    String value(String key) => '${json[key] ?? ''}';
    String? optional(String key) => json[key] == null ? null : value(key);

    return AgencyProfileModel(
      id: optional('id'),
      userId: optional('userId'),
      companyName: value('companyName'),
      businessRegistrationNumber: value('businessRegistrationNumber'),
      taxIdentificationNumber: value('taxIdentificationNumber'),
      officeAddress: value('officeAddress'),
      district: value('district'),
      contactPersonName: value('contactPersonName'),
      contactPersonPhone: value('contactPersonPhone'),
      kycStatus: optional('kycStatus'),
      kycDocumentUrl: optional('kycDocumentUrl'),
      commissionRatePercentage: optional('commissionRatePercentage'),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'companyName': companyName,
        'businessRegistrationNumber': businessRegistrationNumber,
        'taxIdentificationNumber':
            taxIdentificationNumber.isEmpty ? null : taxIdentificationNumber,
        'officeAddress': officeAddress,
        'district': district,
        'contactPersonName': contactPersonName,
        'contactPersonPhone': contactPersonPhone,
      };
}
