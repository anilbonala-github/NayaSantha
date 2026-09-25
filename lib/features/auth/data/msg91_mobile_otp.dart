import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import '../../../core/api/api_failure.dart';

typedef OtpCall = Future<Map<String, dynamic>?> Function(Map<String, dynamic>);

/// One in-memory OTP challenge. No OTP or provider proof is persisted or logged.
class Msg91MobileOtp {
  Msg91MobileOtp({OtpCall? send, OtpCall? retry, OtpCall? verify,
      DateTime Function()? clock})
      : _send = send ?? OTPWidget.sendOTP,
        _retry = retry ?? OTPWidget.retryOTP,
        _verify = verify ?? OTPWidget.verifyOTP,
        _clock = clock ?? DateTime.now;
  final OtpCall _send, _retry, _verify;
  final DateTime Function() _clock;
  String? _mobile, _requestId;
  DateTime? _lastSent;
  int _retries = 0;
  bool _busy = false;

  void configure(Map<String, dynamic> config) {
    OTPWidget.initializeWidget(config['widgetId'] as String, config['widgetToken'] as String);
  }

  Future<void> send(String mobile) async {
    if (_busy) throw failure('Please wait for the current request.');
    final retry = _mobile == mobile && _requestId != null;
    if (retry && _lastSent != null && _clock().difference(_lastSent!).inSeconds < 30) {
      throw failure('Please wait 30 seconds before requesting another code.');
    }
    if (retry && _retries >= 2) throw failure('Resend limit reached. Please try signing in later.');
    _busy = true;
    try {
      final result = retry
          ? await _retry({'reqId': _requestId})
          : await _send({'identifier': '91$mobile'});
      check(result);
      if (!retry) {
        final id = result!['reqId'] ?? result['message'];
        if (id is! String || id.isEmpty) throw failure('Could not start SMS verification. Please try again.');
        _requestId = id;
        _retries = 0;
      } else {
        _retries++;
      }
      _mobile = mobile;
      _lastSent = _clock();
    } on ApiFailure { rethrow; }
    catch (_) { throw failure('Could not send the SMS. Please try again.'); }
    finally { _busy = false; }
  }

  Future<String> verify(String mobile, String code) async {
    if (_busy) throw failure('Please wait for the current request.');
    if (_mobile != mobile || _requestId == null) throw failure('Request a new code for this mobile number.');
    if (!RegExp(r'^\d{6}$').hasMatch(code)) throw failure('Enter the 6-digit code.');
    _busy = true;
    try {
      final result = await _verify({'reqId': _requestId, 'otp': code});
      check(result);
      final proof = result!['message'];
      if (proof is! String || proof.split('.').length != 3) throw failure('Verification could not be completed. Request a new code.');
      _requestId = null;
      return proof;
    } on ApiFailure { rethrow; }
    catch (_) { throw failure('Could not verify the code. Please try again.'); }
    finally { _busy = false; }
  }

  static void check(Map<String, dynamic>? result) {
    if (result?['type'] != 'success') throw failure('The code could not be sent or verified. Check it and try again.');
  }
  static ApiFailure failure(String message) => ApiFailure(errorCode:'SMS_VERIFICATION_FAILED', userMessage:message);
}
