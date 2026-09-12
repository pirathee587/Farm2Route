import '../../data/models/agency_signup_request.dart';
import '../../data/models/agency_verification_models.dart';

abstract class AgencyRepository {
  Future<AgencyResponseModel> signUp(AgencySignupRequest request);
  Future<AgencyStatusModel> verifyEmail(String agencyId, String emailToken);
  Future<AgencyStatusModel> verifyPhone(String agencyId, String otp);
  Future<void> resendEmail(String agencyId);
  Future<void> resendPhoneOtp(String agencyId);
  Future<AgencyStatusModel> getStatus(String agencyId);
}
