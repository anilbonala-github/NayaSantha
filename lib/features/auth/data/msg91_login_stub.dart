import '../../../core/api/api_failure.dart';

Future<String> verifyWithMsg91(Map<String, dynamic> config, String mobile) async {
  throw const ApiFailure(errorCode: 'SMS_PLATFORM_PENDING',
      userMessage: 'SMS sign-in is available on nayasantha.com. The mobile app update is coming soon.');
}
