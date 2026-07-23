import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'razorpay_types.dart';

/// Opens the Razorpay Standard Checkout modal (checkout.js loaded in web/index.html)
/// and resolves with the payment id/order id/signature, or cancelled/failed.
Future<RazorpayResult> openRazorpayCheckout(RazorpayOptions o) {
  final completer = Completer<RazorpayResult>();
  var done = false;
  void finish(RazorpayResult r) {
    if (!done) {
      done = true;
      if (!completer.isCompleted) completer.complete(r);
    }
  }

  final ctor = globalContext.getProperty('Razorpay'.toJS);
  if (ctor == null || ctor.isUndefinedOrNull) {
    finish(RazorpayResult.failed('Razorpay checkout script not loaded'));
    return completer.future;
  }

  String? propStr(JSAny? obj, String key) {
    if (obj == null || obj.isUndefinedOrNull) return null;
    final v = (obj as JSObject).getProperty(key.toJS);
    return (v.isUndefinedOrNull) ? null : (v as JSString).toDart;
  }

  final data = <String, dynamic>{
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
  if (prefill.isNotEmpty) data['prefill'] = prefill;

  final options = data.jsify() as JSObject;

  // Success handler.
  options.setProperty(
    'handler'.toJS,
    ((JSObject resp) {
      finish(RazorpayResult.success(
        paymentId: propStr(resp, 'razorpay_payment_id'),
        orderId: propStr(resp, 'razorpay_order_id'),
        signature: propStr(resp, 'razorpay_signature'),
      ));
    }).toJS,
  );

  // Modal dismiss (user cancelled).
  final modal = JSObject();
  modal.setProperty('ondismiss'.toJS, (() {
    finish(RazorpayResult.cancelled());
  }).toJS);
  options.setProperty('modal'.toJS, modal);

  final rzp = (ctor as JSFunction).callAsConstructor<JSObject>(options);

  // payment.failed event.
  rzp.callMethod(
    'on'.toJS,
    'payment.failed'.toJS,
    ((JSObject resp) {
      final err = resp.getProperty('error'.toJS);
      finish(RazorpayResult.failed(propStr(err, 'description') ?? 'Payment failed'));
    }).toJS,
  );

  rzp.callMethod('open'.toJS);
  return completer.future;
}
