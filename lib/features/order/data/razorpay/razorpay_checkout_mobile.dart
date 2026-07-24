import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_types.dart';

/// Android/iOS checkout via the native razorpay_flutter plugin. Returns the
/// payment id/order id/signature on success, or cancelled/failed.
Future<RazorpayResult> openRazorpayCheckout(RazorpayOptions o) {
  final completer = Completer<RazorpayResult>();
  final razorpay = Razorpay();

  void finish(RazorpayResult r) {
    if (!completer.isCompleted) completer.complete(r);
    razorpay.clear(); // remove listeners / release the instance
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
    finish(RazorpayResult.success(
      paymentId: r.paymentId,
      orderId: r.orderId,
      signature: r.signature,
    ));
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
    if (r.code == Razorpay.PAYMENT_CANCELLED) {
      finish(RazorpayResult.cancelled());
    } else {
      finish(RazorpayResult.failed(r.message ?? 'Payment failed'));
    }
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
    // Wallet app takes over; the success/error event still fires afterwards.
  });

  final options = <String, dynamic>{
    'key': o.keyId,
    'order_id': o.razorpayOrderId,
    'amount': o.amount,
    'currency': o.currency,
    'name': o.name,
    'description': o.description,
    'theme': <String, dynamic>{'color': '#0F4C2A'},
  };
  final prefill = <String, dynamic>{
    if (o.prefillName != null) 'name': o.prefillName,
    if (o.email != null) 'email': o.email,
    if (o.contact != null) 'contact': o.contact,
  };
  if (prefill.isNotEmpty) options['prefill'] = prefill;

  try {
    razorpay.open(options);
  } catch (e) {
    finish(RazorpayResult.failed(e.toString()));
  }
  return completer.future;
}
