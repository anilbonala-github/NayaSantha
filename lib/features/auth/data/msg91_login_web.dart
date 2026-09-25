import 'dart:convert';
import 'dart:js_interop';
import '../../../core/api/api_failure.dart';

@JS('nayaMsg91Login')
external JSPromise<JSString> _login(JSString config, JSString mobile);

Future<String> verifyWithMsg91(Map<String, dynamic> config, String mobile) async {
  try {
    return (await _login(jsonEncode(config).toJS, mobile.toJS).toDart).toDart;
  } catch (_) {
    throw const ApiFailure(errorCode: 'SMS_VERIFICATION_FAILED',
        userMessage: 'SMS verification was not completed. Please try again.');
  }
}
