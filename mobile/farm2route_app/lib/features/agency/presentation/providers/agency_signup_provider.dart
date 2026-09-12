import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/agency_response_model.dart';
import '../../data/models/agency_signup_request.dart';
import '../../data/repositories/agency_repository_impl.dart';
import '../../domain/repositories/agency_repository.dart';

enum AgencySignupStatus { initial, loading, success, error }

class AgencySignupState {
  final AgencySignupStatus status;
  final String? errorMessage;
  final AgencyResponseModel? response;

  const AgencySignupState({
    this.status = AgencySignupStatus.initial,
    this.errorMessage,
    this.response,
  });

  AgencySignupState copyWith({
    AgencySignupStatus? status,
    String? errorMessage,
    AgencyResponseModel? response,
  }) {
    return AgencySignupState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      response: response ?? this.response,
    );
  }
}

class AgencySignupNotifier extends StateNotifier<AgencySignupState> {
  final AgencyRepository _repository;

  AgencySignupNotifier(this._repository) : super(const AgencySignupState());

  Future<bool> signUp(AgencySignupRequest request) async {
    state = state.copyWith(status: AgencySignupStatus.loading, errorMessage: null);
    try {
      final response = await _repository.signUp(request);
      state = state.copyWith(status: AgencySignupStatus.success, response: response);
      return true;
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = state.copyWith(status: AgencySignupStatus.error, errorMessage: message);
      return false;
    }
  }

  void reset() {
    state = const AgencySignupState();
  }
}

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AgencyRepositoryImpl(apiClient);
});

final agencySignupNotifierProvider =
    StateNotifierProvider<AgencySignupNotifier, AgencySignupState>((ref) {
  final repository = ref.watch(agencyRepositoryProvider);
  return AgencySignupNotifier(repository);
});
