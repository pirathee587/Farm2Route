import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/agency_repository.dart';
import 'agency_signup_provider.dart';

class AgencyVerifyState {
  final String agencyId;
  final String email;
  final String phoneNumber;
  final bool emailVerified;
  final bool phoneVerified;
  final String status;
  final bool isSubmittingOtp;
  final bool isResendingPhone;
  final bool isResendingEmail;
  final bool isCheckingStatus;
  final int resendCooldownSeconds;
  final String? errorMessage;
  final String? infoMessage;

  const AgencyVerifyState({
    this.agencyId = '',
    this.email = '',
    this.phoneNumber = '',
    this.emailVerified = false,
    this.phoneVerified = false,
    this.status = 'ACCOUNT_CREATED',
    this.isSubmittingOtp = false,
    this.isResendingPhone = false,
    this.isResendingEmail = false,
    this.isCheckingStatus = false,
    this.resendCooldownSeconds = 0,
    this.errorMessage,
    this.infoMessage,
  });

  bool get isAllVerified => emailVerified && phoneVerified;

  AgencyVerifyState copyWith({
    String? agencyId,
    String? email,
    String? phoneNumber,
    bool? emailVerified,
    bool? phoneVerified,
    String? status,
    bool? isSubmittingOtp,
    bool? isResendingPhone,
    bool? isResendingEmail,
    bool? isCheckingStatus,
    int? resendCooldownSeconds,
    String? errorMessage,
    String? infoMessage,
  }) {
    return AgencyVerifyState(
      agencyId: agencyId ?? this.agencyId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      status: status ?? this.status,
      isSubmittingOtp: isSubmittingOtp ?? this.isSubmittingOtp,
      isResendingPhone: isResendingPhone ?? this.isResendingPhone,
      isResendingEmail: isResendingEmail ?? this.isResendingEmail,
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }
}

class AgencyVerifyNotifier extends StateNotifier<AgencyVerifyState> {
  final AgencyRepository _repository;
  Timer? _cooldownTimer;

  AgencyVerifyNotifier(this._repository) : super(const AgencyVerifyState());

  void init({
    required String agencyId,
    required String email,
    required String phoneNumber,
    bool emailVerified = false,
    bool phoneVerified = false,
    String status = 'ACCOUNT_CREATED',
  }) {
    state = state.copyWith(
      agencyId: agencyId,
      email: email,
      phoneNumber: phoneNumber,
      emailVerified: emailVerified,
      phoneVerified: phoneVerified,
      status: status,
      errorMessage: null,
      infoMessage: null,
    );
  }

  Future<bool> verifyPhone(String otp) async {
    if (state.agencyId.isEmpty) return false;
    state = state.copyWith(
      isSubmittingOtp: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      final result = await _repository.verifyPhone(state.agencyId, otp.trim());
      state = state.copyWith(
        isSubmittingOtp: false,
        phoneVerified: result.phoneVerified,
        emailVerified: result.emailVerified,
        status: result.status,
        infoMessage: 'Phone number verified successfully!',
      );
      return result.phoneVerified;
    } catch (e) {
      final msg = e is AppException ? e.message : 'Invalid verification code';
      state = state.copyWith(
        isSubmittingOtp: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> resendPhoneOtp() async {
    if (state.agencyId.isEmpty || state.resendCooldownSeconds > 0) return;
    state = state.copyWith(
      isResendingPhone: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      await _repository.resendPhoneOtp(state.agencyId);
      state = state.copyWith(
        isResendingPhone: false,
        infoMessage: 'Verification code resent to your phone',
      );
      startCooldownTimer();
    } catch (e) {
      final msg = e is AppException ? e.message : 'Failed to resend code';
      state = state.copyWith(
        isResendingPhone: false,
        errorMessage: msg,
      );
    }
  }

  Future<void> resendEmail() async {
    if (state.agencyId.isEmpty) return;
    state = state.copyWith(
      isResendingEmail: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      await _repository.resendEmail(state.agencyId);
      state = state.copyWith(
        isResendingEmail: false,
        infoMessage: 'Verification email sent! Please check your inbox.',
      );
    } catch (e) {
      final msg = e is AppException ? e.message : 'Failed to resend email';
      state = state.copyWith(
        isResendingEmail: false,
        errorMessage: msg,
      );
    }
  }

  Future<void> checkStatus() async {
    if (state.agencyId.isEmpty) return;
    state = state.copyWith(
      isCheckingStatus: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      final result = await _repository.getStatus(state.agencyId);
      state = state.copyWith(
        isCheckingStatus: false,
        emailVerified: result.emailVerified,
        phoneVerified: result.phoneVerified,
        status: result.status,
        infoMessage: result.emailVerified
            ? 'Email has been verified!'
            : 'Email not verified yet. Please check your inbox.',
      );
    } catch (e) {
      final msg = e is AppException ? e.message : 'Failed to refresh status';
      state = state.copyWith(
        isCheckingStatus: false,
        errorMessage: msg,
      );
    }
  }

  void startCooldownTimer([int seconds = 30]) {
    _cooldownTimer?.cancel();
    state = state.copyWith(resendCooldownSeconds: seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCooldownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
      } else {
        state = state.copyWith(
          resendCooldownSeconds: state.resendCooldownSeconds - 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}

final agencyVerifyNotifierProvider =
    StateNotifierProvider<AgencyVerifyNotifier, AgencyVerifyState>((ref) {
  final repository = ref.watch(agencyRepositoryProvider);
  return AgencyVerifyNotifier(repository);
});
