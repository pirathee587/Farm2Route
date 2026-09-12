import '../../data/models/farmer_response_model.dart';
import '../../data/models/farmer_signup_request.dart';

abstract class FarmerRepository {
  Future<String> requestOtp(String phoneNumber);
  Future<FarmerResponseModel> verifyAndSignup(FarmerSignupRequest request);
}
