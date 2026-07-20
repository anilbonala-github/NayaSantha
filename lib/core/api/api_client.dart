import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'token_store.dart';

/// Thin Dio wrapper that unwraps the `{ data, meta }` success envelope,
/// attaches the bearer token, and transparently refreshes it on a 401 once
/// (Vol2 §5 token refresh rotation, §11 secure storage).
class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
      : _tokens = tokenStore,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}'
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 20)
      ..contentType = 'application/json';
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  final Dio _dio;
  final TokenStore _tokens;
  bool _refreshing = false;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler h) async {
    if (options.extra['auth'] != false) {
      final token = await _tokens.readAccess();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    h.next(options);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final isAuthCall = e.requestOptions.path.startsWith('/auth');
    if (e.response?.statusCode == 401 && !isAuthCall && !_refreshing) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          final retry = await _dio.fetch(e.requestOptions);
          return h.resolve(retry);
        } catch (_) {/* fall through to original error */}
      }
    }
    h.next(e);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) return false;
    _refreshing = true;
    try {
      final res = await _dio.post('/auth/refresh',
          data: {'refreshToken': refresh},
          options: Options(extra: {'auth': false}));
      final data = res.data['data'] as Map<String, dynamic>;
      await _tokens.save(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// GET returning the unwrapped `data` payload.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await _dio.get(path, queryParameters: query)).data['data'];

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async =>
      (await _dio.post(path, data: body, options: Options(extra: {'auth': auth})))
          .data['data'];

  Future<dynamic> patch(String path, {Object? body}) async =>
      (await _dio.patch(path, data: body)).data['data'];

  Future<void> delete(String path) => _dio.delete(path);
}
