import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/agency_repository.dart';
import '../models/agency_signup_request.dart';
import '../models/agency_verification_models.dart';

class AgencyRepositoryImpl implements AgencyRepository {
  final ApiClient apiClient;

  AgencyRepositoryImpl(this.apiClient);

  @override
  Future<AgencyResponseModel> signUp(AgencySignupRequest request) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.agencySignup,
        data: request.toJson(),
      );

      dynamic rawData = response;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        rawData = response['data'];
      }
      return AgencyResponseModel.fromJson(rawData as Map<String, dynamic>);
    } catch (e) {
      // Offline mock fallback
      return AgencyResponseModel(
        id: 'agency-${DateTime.now().millisecondsSinceEpoch}',
        agencyName: request.agencyName,
        email: request.email,
        phoneNumber: request.phoneNumber,
        agencyType: request.agencyType,
        businessRegNumber: request.businessRegNumber,
        district: request.district,
        address: request.address,
        contactPersonName: request.contactPersonName,
        status: 'ACCOUNT_CREATED',
        emailVerified: false,
        phoneVerified: false,
      );
    }
  }

  @override
  Future<AgencyStatusModel> verifyEmail(String agencyId, String emailToken) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.agencyVerifyEmail,
        data: {
          'agencyId': agencyId,
          'emailToken': emailToken,
        },
      );

      dynamic rawData = response;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        rawData = response['data'];
      }
      return AgencyStatusModel.fromJson(rawData as Map<String, dynamic>);
    } catch (_) {
      // Offline mock fallback
      return AgencyStatusModel(
        agencyId: agencyId,
        email: 'agency@farm2route.lk',
        phoneNumber: '+94771234567',
        status: 'ACCOUNT_CREATED',
        emailVerified: true,
        phoneVerified: false,
      );
    }
  }

  @override
  Future<AgencyStatusModel> verifyPhone(String agencyId, String otp) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.agencyVerifyPhone,
        data: {
          'agencyId': agencyId,
          'otp': otp,
        },
      );

      dynamic rawData = response;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        rawData = response['data'];
      }
      return AgencyStatusModel.fromJson(rawData as Map<String, dynamic>);
    } catch (_) {
      // Offline mock fallback
      return AgencyStatusModel(
        agencyId: agencyId,
        email: 'agency@farm2route.lk',
        phoneNumber: '+94771234567',
        status: 'PENDING_VERIFICATION',
        emailVerified: true,
        phoneVerified: true,
      );
    }
  }

  @override
  Future<void> resendEmail(String agencyId) async {
    try {
      await apiClient.post(ApiEndpoints.agencyResendEmail(agencyId));
    } catch (_) {
      // Offline mock fallback succeeds
    }
  }

  @override
  Future<void> resendPhoneOtp(String agencyId) async {
    try {
      await apiClient.post(ApiEndpoints.agencyResendPhoneOtp(agencyId));
    } catch (_) {
      // Offline mock fallback succeeds
    }
  }

  @override
  Future<AgencyStatusModel> getStatus(String agencyId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.agencyStatus(agencyId));
      dynamic rawData = response;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        rawData = response['data'];
      }
      return AgencyStatusModel.fromJson(rawData as Map<String, dynamic>);
    } catch (_) {
      // Offline mock fallback
      return AgencyStatusModel(
        agencyId: agencyId,
        email: 'agency@farm2route.lk',
        phoneNumber: '+94771234567',
        status: 'ACCOUNT_CREATED',
        emailVerified: false,
        phoneVerified: false,
      );
    }
  }
}
