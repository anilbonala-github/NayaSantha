import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';
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


@JS('nayaMsg91Prepare')
external JSPromise<JSAny?> _prepare(JSString config);
@JS('nayaMsg91Send')
external JSPromise<JSString> _send(JSString mobile);
@JS('nayaMsg91Verify')
external JSPromise<JSString> _verify(JSString mobile, JSString code);

Widget msg91Captcha() => SizedBox(height: 90, child: HtmlElementView.fromTagName(
  tagName: 'div', onElementCreated: (element) {
    (element as JSObject).setProperty('id'.toJS, 'naya-otp-captcha'.toJS);
  }));
Future<void> prepareMsg91(Map<String, dynamic> config) async {
  try { await _prepare(jsonEncode(config).toJS).toDart; }
  catch (_) { throw const ApiFailure(errorCode:'SMS_SETUP', userMessage:'Could not load SMS verification. Please reload and try again.'); }
}
Future<void> sendMsg91(String mobile) async {
  try { await _send(mobile.toJS).toDart; }
  catch (_) { throw const ApiFailure(errorCode:'SMS_SEND', userMessage:'Could not send the code. Complete the security check if shown, then try again.'); }
}
Future<String> verifyMsg91(String mobile, String code) async {
  try { return (await _verify(mobile.toJS,code.toJS).toDart).toDart; }
  catch (_) { throw const ApiFailure(errorCode:'SMS_CODE_REJECTED', userMessage:'SMS verification could not complete. Check the latest code and try again.'); }
}

@JS('nayaMsg91Reset')
external void resetMsg91();
