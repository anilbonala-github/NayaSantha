import 'package:flutter/widgets.dart';
import '../../../core/api/api_failure.dart';

Future<String> verifyWithMsg91(Map<String, dynamic> config, String mobile) async {
  throw const ApiFailure(errorCode: 'SMS_PLATFORM_PENDING',
      userMessage: 'SMS sign-in is available on nayasantha.com. The mobile app update is coming soon.');
}

Widget msg91Captcha() => const SizedBox.shrink();
Future<void> prepareMsg91(Map<String, dynamic> config) async => throw UnsupportedError('Web only');
Future<void> sendMsg91(String mobile) async => throw UnsupportedError('Web only');
Future<String> verifyMsg91(String mobile, String code) async => throw UnsupportedError('Web only');

void resetMsg91() {}
