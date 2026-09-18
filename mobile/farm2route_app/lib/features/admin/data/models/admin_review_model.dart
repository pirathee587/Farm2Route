class AdminReviewModel {
  final String id;
  final String? bookingId;
  final String? bookingNumber;
  final String? farmerId;
  final String? farmerName;
  final String? agencyId;
  final String? agencyName;
  final String? driverId;
  final String? driverName;
  final double? agencyRating;
  final double? driverRating;
  final String? comment;
  final String? agencyComment;
  final String? driverComment;
  final String? agencyResponse;
  final DateTime? agencyRespondedAt;
  final String moderationStatus;
  final String? moderatedByAdminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminReviewModel({
    required this.id,
    this.bookingId,
    this.bookingNumber,
    this.farmerId,
    this.farmerName,
    this.agencyId,
    this.agencyName,
    this.driverId,
    this.driverName,
    this.agencyRating,
    this.driverRating,
    this.comment,
    this.agencyComment,
    this.driverComment,
    this.agencyResponse,
    this.agencyRespondedAt,
    required this.moderationStatus,
    this.moderatedByAdminId,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminReviewModel.fromJson(Map<String, dynamic> json) {
    return AdminReviewModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
      bookingNumber: json['bookingNumber']?.toString(),
      farmerId: json['farmerId']?.toString(),
      farmerName: json['farmerName']?.toString(),
      agencyId: json['agencyId']?.toString(),
      agencyName: json['agencyName']?.toString(),
      driverId: json['driverId']?.toString(),
      driverName: json['driverName']?.toString(),
      agencyRating: (json['agencyRating'] as num?)?.toDouble(),
      driverRating: (json['driverRating'] as num?)?.toDouble(),
      comment: json['comment']?.toString(),
      agencyComment: json['agencyComment']?.toString(),
      driverComment: json['driverComment']?.toString(),
      agencyResponse: json['agencyResponse']?.toString(),
      agencyRespondedAt: json['agencyRespondedAt'] != null
          ? DateTime.tryParse(json['agencyRespondedAt'].toString())
          : null,
      moderationStatus: json['moderationStatus']?.toString() ?? 'PENDING_REVIEW',
      moderatedByAdminId: json['moderatedByAdminId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingNumber': bookingNumber,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'driverId': driverId,
      'driverName': driverName,
      'agencyRating': agencyRating,
      'driverRating': driverRating,
      'comment': comment,
      'agencyComment': agencyComment,
      'driverComment': driverComment,
      'agencyResponse': agencyResponse,
      'agencyRespondedAt': agencyRespondedAt?.toIso8601String(),
      'moderationStatus': moderationStatus,
      'moderatedByAdminId': moderatedByAdminId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
