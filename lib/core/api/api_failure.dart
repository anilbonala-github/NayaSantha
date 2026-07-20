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
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiFailure(
        errorCode: 'OFFLINE',
        userMessage: "You appear to be offline. We'll retry when you're back.",
        isOffline: true,
      );
    }
    final data = e.response?.data;
    if (data is Map && data['errorCode'] != null) {
      return ApiFailure(
        errorCode: data['errorCode'] as String,
        userMessage: (data['userMessage'] as String?) ?? 'Something went wrong.',
        developerMessage: data['developerMessage'] as String?,
        traceId: data['traceId'] as String?,
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
