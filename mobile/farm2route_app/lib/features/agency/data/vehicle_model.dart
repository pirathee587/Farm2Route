class VehicleModel {
  final String id;
  final String registrationNumber;
  final String makeAndModel;
  final String vehicleType;
  final double? capacity;
  final double? cargoVolumeCbm;
  final bool refrigerated;
  final String kycStatus;
  final String status;
  final String insurancePolicyNumber;
  final String insuranceExpiryDate;
  final String revenueLicenseNumber;
  final String revenueLicenseExpiryDate;

  const VehicleModel(
      {required this.id,
      required this.registrationNumber,
      required this.makeAndModel,
      required this.vehicleType,
      this.capacity,
      this.cargoVolumeCbm,
      required this.refrigerated,
      required this.kycStatus,
      required this.status,
      required this.insurancePolicyNumber,
      required this.insuranceExpiryDate,
      required this.revenueLicenseNumber,
      required this.revenueLicenseExpiryDate});

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: '${json['id'] ?? ''}',
        registrationNumber: '${json['registrationNumber'] ?? ''}',
        makeAndModel: '${json['makeAndModel'] ?? ''}',
        vehicleType: '${json['vehicleType'] ?? ''}',
        capacity: (json['capacity'] as num?)?.toDouble(),
        cargoVolumeCbm: (json['cargoVolumeCbm'] as num?)?.toDouble(),
        refrigerated:
            json['refrigerated'] == true || json['isRefrigerated'] == true,
        kycStatus: '${json['kycStatus'] ?? 'PENDING'}',
        status: '${json['status'] ?? 'INACTIVE'}',
        insurancePolicyNumber: '${json['insurancePolicyNumber'] ?? ''}',
        insuranceExpiryDate: '${json['insuranceExpiryDate'] ?? ''}',
        revenueLicenseNumber: '${json['revenueLicenseNumber'] ?? ''}',
        revenueLicenseExpiryDate: '${json['revenueLicenseExpiryDate'] ?? ''}',
      );
}
