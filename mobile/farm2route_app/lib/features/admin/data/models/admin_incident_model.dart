class AdminIncidentModel {
  final String id;
  final String? bookingId;
  final String? bookingNumber;
  final String? reportedByUserId;
  final String incidentType;
  final String title;
  final String description;
  final String status;
  final String? adminNotes;
  final String? investigationNotes;
  final String? resolvedByAdminId;
  final String? resolutionOutcome;
  final double? refundAmount;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<EvidenceModel> evidenceList;
  final FarmerSummaryModel? farmerSummary;
  final AgencySummaryModel? agencySummary;
  final DriverSummaryModel? driverSummary;
  final VehicleSummaryModel? vehicleSummary;

  const AdminIncidentModel({
    required this.id,
    this.bookingId,
    this.bookingNumber,
    this.reportedByUserId,
    required this.incidentType,
    required this.title,
    required this.description,
    required this.status,
    this.adminNotes,
    this.investigationNotes,
    this.resolvedByAdminId,
    this.resolutionOutcome,
    this.refundAmount,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.evidenceList = const [],
    this.farmerSummary,
    this.agencySummary,
    this.driverSummary,
    this.vehicleSummary,
  });

  factory AdminIncidentModel.fromJson(Map<String, dynamic> json) {
    return AdminIncidentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
      bookingNumber: json['bookingNumber']?.toString(),
      reportedByUserId: json['reportedByUserId']?.toString(),
      incidentType: json['incidentType']?.toString() ?? 'OTHER',
      title: json['title']?.toString() ?? 'Untitled Incident',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      adminNotes: json['adminNotes']?.toString(),
      investigationNotes: json['investigationNotes']?.toString(),
      resolvedByAdminId: json['resolvedByAdminId']?.toString(),
      resolutionOutcome: json['resolutionOutcome']?.toString(),
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      evidenceList: json['evidenceList'] is List
          ? (json['evidenceList'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => EvidenceModel.fromJson(e))
              .toList()
          : const [],
      farmerSummary: json['farmerSummary'] is Map<String, dynamic>
          ? FarmerSummaryModel.fromJson(json['farmerSummary'] as Map<String, dynamic>)
          : null,
      agencySummary: json['agencySummary'] is Map<String, dynamic>
          ? AgencySummaryModel.fromJson(json['agencySummary'] as Map<String, dynamic>)
          : null,
      driverSummary: json['driverSummary'] is Map<String, dynamic>
          ? DriverSummaryModel.fromJson(json['driverSummary'] as Map<String, dynamic>)
          : null,
      vehicleSummary: json['vehicleSummary'] is Map<String, dynamic>
          ? VehicleSummaryModel.fromJson(json['vehicleSummary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingNumber': bookingNumber,
      'reportedByUserId': reportedByUserId,
      'incidentType': incidentType,
      'title': title,
      'description': description,
      'status': status,
      'adminNotes': adminNotes,
      'investigationNotes': investigationNotes,
      'resolvedByAdminId': resolvedByAdminId,
      'resolutionOutcome': resolutionOutcome,
      'refundAmount': refundAmount,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'evidenceList': evidenceList.map((e) => e.toJson()).toList(),
      'farmerSummary': farmerSummary?.toJson(),
      'agencySummary': agencySummary?.toJson(),
      'driverSummary': driverSummary?.toJson(),
      'vehicleSummary': vehicleSummary?.toJson(),
    };
  }
}

class EvidenceModel {
  final String id;
  final String? fileUrl;
  final String? photoUrl;
  final String? fileType;
  final String? caption;
  final DateTime? createdAt;

  const EvidenceModel({
    required this.id,
    this.fileUrl,
    this.photoUrl,
    this.fileType,
    this.caption,
    this.createdAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      fileType: json['fileType']?.toString(),
      caption: json['caption']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileUrl': fileUrl,
      'photoUrl': photoUrl,
      'fileType': fileType,
      'caption': caption,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class FarmerSummaryModel {
  final String? farmerId;
  final String? userId;
  final String? farmName;
  final String? farmerName;
  final String? farmerEmail;
  final String? farmerPhone;

  const FarmerSummaryModel({
    this.farmerId,
    this.userId,
    this.farmName,
    this.farmerName,
    this.farmerEmail,
    this.farmerPhone,
  });

  factory FarmerSummaryModel.fromJson(Map<String, dynamic> json) {
    return FarmerSummaryModel(
      farmerId: json['farmerId']?.toString(),
      userId: json['userId']?.toString(),
      farmName: json['farmName']?.toString(),
      farmerName: json['farmerName']?.toString(),
      farmerEmail: json['farmerEmail']?.toString(),
      farmerPhone: json['farmerPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmerId': farmerId,
      'userId': userId,
      'farmName': farmName,
      'farmerName': farmerName,
      'farmerEmail': farmerEmail,
      'farmerPhone': farmerPhone,
    };
  }
}

class AgencySummaryModel {
  final String? agencyId;
  final String? userId;
  final String? companyName;
  final String? contactPhone;

  const AgencySummaryModel({
    this.agencyId,
    this.userId,
    this.companyName,
    this.contactPhone,
  });

  factory AgencySummaryModel.fromJson(Map<String, dynamic> json) {
    return AgencySummaryModel(
      agencyId: json['agencyId']?.toString(),
      userId: json['userId']?.toString(),
      companyName: json['companyName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agencyId': agencyId,
      'userId': userId,
      'companyName': companyName,
      'contactPhone': contactPhone,
    };
  }
}

class DriverSummaryModel {
  final String? driverId;
  final String? userId;
  final String? driverName;
  final String? driverPhone;
  final String? licenseNumber;

  const DriverSummaryModel({
    this.driverId,
    this.userId,
    this.driverName,
    this.driverPhone,
    this.licenseNumber,
  });

  factory DriverSummaryModel.fromJson(Map<String, dynamic> json) {
    return DriverSummaryModel(
      driverId: json['driverId']?.toString(),
      userId: json['userId']?.toString(),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'userId': userId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'licenseNumber': licenseNumber,
    };
  }
}

class VehicleSummaryModel {
  final String? vehicleId;
  final String? registrationNumber;
  final String? vehicleType;
  final double? capacityKg;

  const VehicleSummaryModel({
    this.vehicleId,
    this.registrationNumber,
    this.vehicleType,
    this.capacityKg,
  });

  factory VehicleSummaryModel.fromJson(Map<String, dynamic> json) {
    return VehicleSummaryModel(
      vehicleId: json['vehicleId']?.toString(),
      registrationNumber: json['registrationNumber']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      capacityKg: (json['capacityKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'capacityKg': capacityKg,
    };
  }
}
