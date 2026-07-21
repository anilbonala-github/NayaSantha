/// Customer order mirroring the backend OrderDto (Vol2A §11). Named CustomerOrder
/// to avoid clashing with the legacy mock `Order`.
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.pricePreference,
    required this.estimatedTotal,
    required this.maximumPayable,
    this.finalTotal,
    this.savings,
    this.deliverySlot,
    this.paymentStatus,
    this.items = const <OrderLine>[],
    this.exception,
  });

  final String id;
  final String status;
  final String pricePreference;
  final double estimatedTotal;
  final double maximumPayable;
  final double? finalTotal;
  final double? savings;
  final String? deliverySlot;
  final String? paymentStatus;
  final List<OrderLine> items;
  final OrderException? exception;

  bool get awaitingApproval => status == 'AWAITING_APPROVAL';
  bool get isPaid => status == 'PAID';

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
        id: j['id'] as String,
        status: j['status'] as String,
        pricePreference: j['pricePreference'] as String,
        estimatedTotal: _d(j['estimatedTotal']) ?? 0,
        maximumPayable: _d(j['maximumPayable']) ?? 0,
        finalTotal: _d(j['finalTotal']),
        savings: _d(j['savings']),
        deliverySlot: j['deliverySlot'] as String?,
        paymentStatus: j['paymentStatus'] as String?,
        items: (j['items'] as List?)
                ?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <OrderLine>[],
        exception: j['exception'] == null
            ? null
            : OrderException.fromJson(j['exception'] as Map<String, dynamic>),
      );
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.name,
    this.unit,
    required this.quantity,
    required this.forecastRate,
    required this.estimatedAmount,
    this.actualRate,
    this.finalAmount,
    this.substitutionReason,
  });

  final String id;
  final String name;
  final String? unit;
  final int quantity;
  final double forecastRate;
  final double estimatedAmount;
  final double? actualRate;
  final double? finalAmount;
  final String? substitutionReason;

  bool get removed => finalAmount != null && finalAmount == 0;

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Item',
        unit: j['unit'] as String?,
        quantity: (j['quantity'] as num).toInt(),
        forecastRate: _d(j['forecastRate']) ?? 0,
        estimatedAmount: _d(j['estimatedAmount']) ?? 0,
        actualRate: _d(j['actualRate']),
        finalAmount: _d(j['finalAmount']),
        substitutionReason: j['substitutionReason'] as String?,
      );
}

class OrderException {
  const OrderException(
      {required this.reason, required this.finalTotal, required this.maxPayable});
  final String reason;
  final double finalTotal;
  final double maxPayable;

  factory OrderException.fromJson(Map<String, dynamic> j) => OrderException(
        reason: j['reason'] as String? ?? 'Final total exceeds your maximum',
        finalTotal: (j['finalTotal'] as num?)?.toDouble() ?? 0,
        maxPayable: (j['maxPayable'] as num?)?.toDouble() ?? 0,
      );
}
