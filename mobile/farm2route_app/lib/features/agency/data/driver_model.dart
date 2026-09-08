class DriverModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String drivingLicenseNumber;
  final String licenseExpiryDate;
  final String nicNumber;
  final String kycStatus;
  final String availabilityStatus;
  final double? ratingAverage;
  final int totalRatingsCount;

  const DriverModel(
      {required this.id,
      required this.fullName,
      required this.email,
      required this.phoneNumber,
      required this.drivingLicenseNumber,
      required this.licenseExpiryDate,
      required this.nicNumber,
      required this.kycStatus,
      required this.availabilityStatus,
      this.ratingAverage,
      required this.totalRatingsCount});

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        id: '${json['id'] ?? ''}',
        fullName: '${json['fullName'] ?? ''}',
        email: '${json['email'] ?? ''}',
        phoneNumber: '${json['phoneNumber'] ?? ''}',
        drivingLicenseNumber: '${json['drivingLicenseNumber'] ?? ''}',
        licenseExpiryDate: '${json['licenseExpiryDate'] ?? ''}',
        nicNumber: '${json['nicNumber'] ?? ''}',
        kycStatus: '${json['kycStatus'] ?? 'PENDING'}',
        availabilityStatus: '${json['availabilityStatus'] ?? 'INACTIVE'}',
        ratingAverage: (json['ratingAverage'] as num?)?.toDouble(),
        totalRatingsCount: (json['totalRatingsCount'] as num?)?.toInt() ?? 0,
      );
}
