import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya_santha/core/api/api_failure.dart';

void main() {
  final request = RequestOptions(path: '/auth/otp/request');
  test('server timeouts do not claim the device is offline', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout
    ]) {
      final failure =
          ApiFailure.fromDio(DioException(requestOptions: request, type: type));
      expect(failure.errorCode, 'SERVER_TIMEOUT');
      expect(failure.isOffline, isFalse);
      expect(failure.userMessage, contains('starting up'));
    }
  });
  test('host gateway HTML errors explain service unavailability', () {
    for (final status in [502, 503, 504]) {
      final failure = ApiFailure.fromDio(DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(
              requestOptions: request,
              statusCode: status,
              data: '<html>Unavailable</html>')));
      expect(failure.errorCode, 'SERVICE_UNAVAILABLE');
      expect(failure.userMessage, contains('try again'));
    }
  });
  test('structured API errors retain their precise message and trace', () {
    final failure = ApiFailure.fromDio(DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: request, statusCode: 400, data: {
          'errorCode': 'OTP_INVALID',
          'userMessage': 'OTP expired',
          'traceId': 'trace'
        })));
    expect(failure.errorCode, 'OTP_INVALID');
    expect(failure.userMessage, 'OTP expired');
    expect(failure.traceId, 'trace');
  });
  test('connection errors ask for an explicit retry', () {
    final failure = ApiFailure.fromDio(DioException(
        requestOptions: request, type: DioExceptionType.connectionError));
    expect(failure.isOffline, isTrue);
    expect(failure.userMessage, isNot(contains("We'll retry")));
  });
}
