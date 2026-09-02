class UserModel {
  final String id;
  final String? email;
  final String phoneNumber;
  final String fullName;
  final String role;
  final String status;
  final String? profileImageUrl;
  final bool isPhoneVerified;
  final bool isEmailVerified;

  UserModel({
    required this.id,
    this.email,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.status,
    this.profileImageUrl,
    required this.isPhoneVerified,
    required this.isEmailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'FARMER',
      status: json['status'] ?? 'PENDING_VERIFICATION',
      profileImageUrl: json['profileImageUrl'],
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'role': role,
      'status': status,
      'profileImageUrl': profileImageUrl,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
    };
  }
}
