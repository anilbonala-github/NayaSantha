import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/token_store.dart';
import '../domain/auth_models.dart';
import 'msg91_login.dart';

/// Talks to the backend auth endpoints and persists tokens. Converts Dio errors
/// into typed [ApiFailure]s (Vol2 §6.1).
class AuthRepository {
  AuthRepository({required ApiClient client, required TokenStore tokens})
      : _client = client,
        _tokens = tokens;

  final ApiClient _client;
  final TokenStore _tokens;

  /// Returns null while the verified-provider rollout is disabled.
  Future<AuthSession?> signInWithSms(String mobile, {bool staff = false}) async {
    try {
      final config = await _client.get('/auth/msg91/config')
          as Map<String, dynamic>;
      if (config['enabled'] != true) return null;
      final proof = await verifyWithMsg91(config, mobile);
      final data = await _client.post('/auth/msg91/verify', auth: false,
          body: {'mobile': mobile, 'accessToken': proof, 'staff': staff});
      await _tokens.save(access: data['accessToken'], refresh: data['refreshToken']);
      return AuthSession(user: AuthUser.fromJson(data['user']), accessToken: data['accessToken']);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Requests an OTP. Returns a dev hint while the SMS provider is stubbed.
  Future<String?> requestOtp(String mobile) async {
    try {
      final data = await _client.post('/auth/otp/request',
          body: {'mobile': mobile}, auth: false);
      return data['devHint'] as String?;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<AuthSession> verifyOtp(String mobile, String code) async {
    try {
      final data = await _client.post('/auth/otp/verify',
          body: {'mobile': mobile, 'code': code}, auth: false);
      await _tokens.save(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return AuthSession(
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefresh();
    if (refresh != null) {
      try {
        await _client.post('/auth/logout',
            body: {'refreshToken': refresh}, auth: false);
      } on DioException catch (_) {/* best-effort */}
    }
    await _tokens.clear();
  }

  Future<bool> hasSession() async => (await _tokens.readAccess()) != null;
}
