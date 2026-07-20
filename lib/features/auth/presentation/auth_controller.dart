import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/token_store.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

// --- dependency providers ---------------------------------------------------
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) =>
    ApiClient(tokenStore: ref.watch(tokenStoreProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      client: ref.watch(apiClientProvider),
      tokens: ref.watch(tokenStoreProvider),
    ));

// --- auth state (Vol2 §9: initial/loading/success/error) --------------------
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP has been requested; waiting for the user to enter the code.
class AuthOtpSent extends AuthState {
  const AuthOtpSent(this.mobile, {this.devHint});
  final String mobile;
  final String? devHint;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthFailed extends AuthState {
  const AuthFailed(this.failure, {this.mobile});
  final ApiFailure failure;
  final String? mobile;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  Future<void> requestOtp(String mobile) async {
    state = const AuthLoading();
    try {
      final hint = await _repo.requestOtp(mobile);
      state = AuthOtpSent(mobile, devHint: hint);
    } on ApiFailure catch (f) {
      state = AuthFailed(f, mobile: mobile);
    }
  }

  Future<void> verifyOtp(String mobile, String code) async {
    state = const AuthLoading();
    try {
      final session = await _repo.verifyOtp(mobile, code);
      state = AuthAuthenticated(session.user);
    } on ApiFailure catch (f) {
      state = AuthFailed(f, mobile: mobile);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthInitial();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) =>
        AuthController(ref.watch(authRepositoryProvider)));
