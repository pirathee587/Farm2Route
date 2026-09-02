import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// Providers
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    onSessionExpired: () {
      ref.read(authNotifierProvider.notifier).logout();
    },
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(remoteDataSource: remote, secureStorage: storage);
});

// State
enum AuthStatus { initial, loading, authenticated, requiresOtp, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? pendingPhone;
  final String? pendingPurpose;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.pendingPhone,
    this.pendingPurpose,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? pendingPhone,
    String? pendingPurpose,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingPurpose: pendingPurpose ?? this.pendingPurpose,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final hasToken = await _repository.checkAuthStatus();
      if (hasToken) {
        final user = await _repository.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.login(identifier: identifier, password: password);
      if (response.requiresOtp) {
        state = state.copyWith(
          status: AuthStatus.requiresOtp,
          pendingPhone: response.user?.phoneNumber ?? identifier,
          pendingPurpose: 'LOGIN',
        );
      } else if (response.user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
      } else {
        final user = await _repository.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(
        status: AuthStatus.requiresOtp,
        pendingPhone: phoneNumber,
        pendingPurpose: 'REGISTRATION',
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otpCode) async {
    if (state.pendingPhone == null) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.verifyOtp(
        phoneNumber: state.pendingPhone!,
        otpCode: otpCode,
        purpose: state.pendingPurpose ?? 'REGISTRATION',
      );
      if (response.user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
      } else {
        final user = await _repository.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
