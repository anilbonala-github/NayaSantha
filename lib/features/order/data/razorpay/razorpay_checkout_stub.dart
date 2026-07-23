import 'razorpay_types.dart';

/// Non-web platforms: Standard *Web* Checkout isn't available. On Android/iOS use
/// the razorpay_flutter plugin instead (separate follow-up). Callers fall back to
/// the simulated capture when this returns a failure.
Future<RazorpayResult> openRazorpayCheckout(RazorpayOptions options) async {
  return RazorpayResult.failed('Razorpay web checkout is only available on the web build');
}
