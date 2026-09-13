class AgencyKycSummaryModel {
  final String id;
  final String companyName;
  final String contactEmail;
  final String contactPhone;
  final String kycStatus;
  final String? kycRejectionReason;
  final DateTime? createdAt;

  const AgencyKycSummaryModel({
    required this.id,
    required this.companyName,
    required this.contactEmail,
    required this.contactPhone,
    required this.kycStatus,
    this.kycRejectionReason,
    this.createdAt,
  });

  factory AgencyKycSummaryModel.fromJson(Map<String, dynamic> json) {
    return AgencyKycSummaryModel(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      kycStatus: json['kycStatus']?.toString() ?? 'PENDING',
      kycRejectionReason: json['kycRejectionReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'kycStatus': kycStatus,
      'kycRejectionReason': kycRejectionReason,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class DriverKycSummaryModel {
  final String id;
  final String driverName;
  final String phone;
  final String licenseNumber;
  final String? agencyId;
  final String? agencyName;
  final String kycStatus;
  final DateTime? createdAt;

  const DriverKycSummaryModel({
    required this.id,
    required this.driverName,
    required this.phone,
    required this.licenseNumber,
    this.agencyId,
    this.agencyName,
    required this.kycStatus,
    this.createdAt,
  });

  factory DriverKycSummaryModel.fromJson(Map<String, dynamic> json) {
    return DriverKycSummaryModel(
      id: json['id']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      agencyId: json['agencyId']?.toString(),
      agencyName: json['agencyName']?.toString(),
      kycStatus: json['kycStatus']?.toString() ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'kycStatus': kycStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class VehicleKycSummaryModel {
  final String id;
  final String registrationNumber;
  final String vehicleType;
  final String? agencyId;
  final String? agencyName;
  final String kycStatus;
  final DateTime? createdAt;

  const VehicleKycSummaryModel({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    this.agencyId,
    this.agencyName,
    required this.kycStatus,
    this.createdAt,
  });

  factory VehicleKycSummaryModel.fromJson(Map<String, dynamic> json) {
    return VehicleKycSummaryModel(
      id: json['id']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      agencyId: json['agencyId']?.toString(),
      agencyName: json['agencyName']?.toString(),
      kycStatus: json['kycStatus']?.toString() ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'kycStatus': kycStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
