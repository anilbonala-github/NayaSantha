import 'package:dio/dio.dart';

/// Typed failure surfaced to the UI, mapped from the backend error envelope
/// `{ errorCode, userMessage, developerMessage, traceId }` (Vol2 §5.1).
class ApiFailure implements Exception {
  const ApiFailure({
    required this.errorCode,
    required this.userMessage,
    this.developerMessage,
    this.traceId,
    this.isOffline = false,
  });

  final String errorCode;
  final String userMessage;
  final String? developerMessage;
  final String? traceId;
  final bool isOffline;

  bool get isVersionConflict => errorCode == 'VERSION_CONFLICT';
  bool get isUnauthorized =>
      errorCode == 'UNAUTHORIZED' || errorCode == 'TOKEN_INVALID';

  /// Builds a failure from a Dio error, reading the backend envelope when present.
  factory ApiFailure.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiFailure(
        errorCode: 'SERVER_TIMEOUT',
        userMessage:
            'The service is taking longer than expected. It may be starting up. Please wait two minutes and try again.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiFailure(
        errorCode: 'CONNECTION_ERROR',
        userMessage:
            'Unable to connect. Check your internet connection and try again.',
        isOffline: true,
      );
    }
    final data = e.response?.data;
    if (data is Map && data['errorCode'] != null) {
      return ApiFailure(
        errorCode: data['errorCode'] as String,
        userMessage:
            (data['userMessage'] as String?) ?? 'Something went wrong.',
        developerMessage: data['developerMessage'] as String?,
        traceId: data['traceId'] as String?,
      );
    }
    if ([502, 503, 504].contains(e.response?.statusCode)) {
      return const ApiFailure(
        errorCode: 'SERVICE_UNAVAILABLE',
        userMessage:
            'The service is temporarily unavailable or starting up. Please wait two minutes and try again.',
      );
    }
    return ApiFailure(
      errorCode: 'INTERNAL_ERROR',
      userMessage: 'Something went wrong. Please try again.',
      developerMessage: e.message,
    );
  }

  @override
  String toString() => 'ApiFailure($errorCode: $userMessage)';
}
