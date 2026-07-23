// Public entry for Razorpay Standard Checkout. Re-exports the platform impl
// (web = checkout.js via JS interop; other platforms = stub) plus the shared types.
export 'razorpay_types.dart';
export 'razorpay_checkout_stub.dart'
    if (dart.library.js) 'razorpay_checkout_web.dart';
