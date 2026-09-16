class CheckoutLine {
  const CheckoutLine(
      {required this.name,
      required this.unit,
      required this.quantity,
      required this.unitPrice,
      required this.amount});
  final String name, unit;
  final int quantity;
  final double unitPrice, amount;
  factory CheckoutLine.fromJson(Map<String, dynamic> j) => CheckoutLine(
      name: j['name'] as String,
      unit: j['unit'] as String? ?? '',
      quantity: (j['quantity'] as num).toInt(),
      unitPrice: (j['unitPrice'] as num).toDouble(),
      amount: (j['amount'] as num).toDouble());
}

class CheckoutPreview {
  const CheckoutPreview(
      {required this.basketId,
      required this.items,
      required this.subtotal,
      required this.deliveryFee,
      required this.total,
      required this.deliveryAddress,
      this.deliverySlot,
      required this.quoteToken});
  final String basketId, deliveryAddress, quoteToken;
  final String? deliverySlot;
  final List<CheckoutLine> items;
  final double subtotal, deliveryFee, total;
  factory CheckoutPreview.fromJson(Map<String, dynamic> j) => CheckoutPreview(
      basketId: j['basketId'] as String,
      quoteToken: j['quoteToken'] as String,
      deliveryAddress: j['deliveryAddress'] as String,
      deliverySlot: j['deliverySlot'] as String?,
      subtotal: (j['subtotal'] as num).toDouble(),
      deliveryFee: (j['deliveryFee'] as num).toDouble(),
      total: (j['total'] as num).toDouble(),
      items: (j['items'] as List)
          .map((x) => CheckoutLine.fromJson(x as Map<String, dynamic>))
          .toList());
}
