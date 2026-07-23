/// Options + result for Razorpay Standard Checkout. KEY_SECRET never appears here —
/// only the public keyId (from the backend create-order response) reaches the client.
class RazorpayOptions {
  const RazorpayOptions({
    required this.keyId,
    required this.razorpayOrderId,
    required this.amount, // paise
    this.currency = 'INR',
    this.name = 'NayaSantha',
    this.description = '',
    this.contact,
    this.email,
    this.prefillName,
  });

  final String keyId;
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String name;
  final String description;
  final String? contact;
  final String? email;
  final String? prefillName;
}

class RazorpayResult {
  RazorpayResult._({
    required this.success,
    this.cancelled = false,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
  });

  final bool success;
  final bool cancelled;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;

  factory RazorpayResult.success({String? paymentId, String? orderId, String? signature}) =>
      RazorpayResult._(success: true, paymentId: paymentId, orderId: orderId, signature: signature);

  factory RazorpayResult.cancelled() => RazorpayResult._(success: false, cancelled: true);

  factory RazorpayResult.failed(String message) =>
      RazorpayResult._(success: false, error: message);
}
