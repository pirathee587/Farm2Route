class AgencyReviewModel {
  final String id;
  final String? bookingId;
  final String? bookingNumber;
  final String? farmerId;
  final String? driverId;
  final String? driverName;
  final int? agencyRating;
  final String? agencyComment;
  final int? driverRating;
  final String? driverComment;
  final String? agencyResponse;
  final String? agencyRespondedAt;
  final String? moderationStatus;
  final String? createdAt;
  final String? updatedAt;

  const AgencyReviewModel({
    required this.id,
    this.bookingId,
    this.bookingNumber,
    this.farmerId,
    this.driverId,
    this.driverName,
    this.agencyRating,
    this.agencyComment,
    this.driverRating,
    this.driverComment,
    this.agencyResponse,
    this.agencyRespondedAt,
    this.moderationStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory AgencyReviewModel.fromJson(Map<String, dynamic> json) {
    return AgencyReviewModel(
      id: '${json['id'] ?? ''}',
      bookingId: _optional(json['bookingId']),
      bookingNumber: _optional(json['bookingNumber']),
      farmerId: _optional(json['farmerId']),
      driverId: _optional(json['driverId']),
      driverName: _optional(json['driverName']),
      agencyRating: _integer(json['agencyRating']),
      agencyComment: _optional(json['agencyComment']),
      driverRating: _integer(json['driverRating']),
      driverComment: _optional(json['driverComment']),
      agencyResponse: _optional(json['agencyResponse']),
      agencyRespondedAt: _optional(json['agencyRespondedAt']),
      moderationStatus: _optional(json['moderationStatus']),
      createdAt: _optional(json['createdAt']),
      updatedAt: _optional(json['updatedAt']),
    );
  }

  Map<String, dynamic> responseRequest(String response) =>
      {'response': response};
}

class AgencyNotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String message;
  final String notificationType;
  final String? referenceType;
  final String? referenceId;
  final bool read;
  final String? readAt;
  final String? createdAt;

  const AgencyNotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.referenceType,
    this.referenceId,
    required this.read,
    this.readAt,
    this.createdAt,
  });

  factory AgencyNotificationModel.fromJson(Map<String, dynamic> json) {
    return AgencyNotificationModel(
      id: '${json['id'] ?? ''}',
      userId: _optional(json['userId']),
      title: '${json['title'] ?? ''}',
      message: '${json['message'] ?? ''}',
      notificationType: '${json['notificationType'] ?? ''}',
      referenceType: _optional(json['referenceType']),
      referenceId: _optional(json['referenceId']),
      read: json['read'] == true,
      readAt: _optional(json['readAt']),
      createdAt: _optional(json['createdAt']),
    );
  }
}

int? _integer(Object? value) => value == null ? null : int.tryParse('$value');

String? _optional(Object? value) => value?.toString();
