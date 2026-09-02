import 'user_model.dart';

class AuthResponseModel {
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresInMs;
  final UserModel? user;
  final bool requiresOtp;

  AuthResponseModel({
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresInMs,
    this.user,
    this.requiresOtp = false,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresInMs: json['expiresInMs'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      requiresOtp: json['requiresOtp'] ?? false,
    );
  }
}
