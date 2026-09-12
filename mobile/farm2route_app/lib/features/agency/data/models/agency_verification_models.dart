export 'agency_response_model.dart';

class AgencyStatusModel {
  final String agencyId;
  final String email;
  final String phoneNumber;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;
  final String? rejectionReason;

  const AgencyStatusModel({
    required this.agencyId,
    required this.email,
    required this.phoneNumber,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    this.rejectionReason,
  });

  factory AgencyStatusModel.fromJson(Map<String, dynamic> json) {
    return AgencyStatusModel(
      agencyId: (json['agencyId'] ?? json['id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'ACCOUNT_CREATED',
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
