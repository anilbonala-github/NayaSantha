// Ops/admin portal models mirroring the backend `OpsDtos` (Vol3).

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class OpsSummary {
  const OpsSummary({
    required this.weekStart,
    required this.lockedOrders,
    required this.households,
    required this.totalEstimated,
    required this.totalMaxPayable,
    required this.distinctProducts,
    required this.pricesCaptured,
    required this.pricesPending,
  });

  final String weekStart;
  final int lockedOrders;
  final int households;
  final double totalEstimated;
  final double totalMaxPayable;
  final int distinctProducts;
  final int pricesCaptured;
  final int pricesPending;

  bool get readyToFinalize => distinctProducts > 0 && pricesPending == 0;

  factory OpsSummary.fromJson(Map<String, dynamic> j) => OpsSummary(
        weekStart: j['weekStart'] as String,
        lockedOrders: (j['lockedOrders'] as num).toInt(),
        households: (j['households'] as num).toInt(),
        totalEstimated: _d(j['totalEstimated']),
        totalMaxPayable: _d(j['totalMaxPayable']),
        distinctProducts: (j['distinctProducts'] as num).toInt(),
        pricesCaptured: (j['pricesCaptured'] as num).toInt(),
        pricesPending: (j['pricesPending'] as num).toInt(),
      );
}

class PurchaseLine {
  const PurchaseLine({
    required this.productId,
    required this.name,
    this.unit,
    required this.totalQuantity,
    required this.bufferPercent,
    required this.buyQuantity,
    required this.forecastRate,
    required this.maxRate,
    this.capturedRate,
    required this.estimatedAmount,
  });

  final String productId;
  final String name;
  final String? unit;
  final int totalQuantity;
  final int bufferPercent;
  final int buyQuantity;
  final double forecastRate;
  final double maxRate;
  final double? capturedRate;
  final double estimatedAmount;

  /// Actual-vs-forecast variance as a fraction (e.g. 0.158 = +15.8%). Null until captured.
  double? get variance =>
      (capturedRate == null || forecastRate == 0) ? null : (capturedRate! - forecastRate) / forecastRate;

  /// Material price change flag (Vol2A: |variance| > 10%).
  bool get isPriceAlert => variance != null && variance!.abs() > 0.10;

  factory PurchaseLine.fromJson(Map<String, dynamic> j) => PurchaseLine(
        productId: j['productId'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String?,
        totalQuantity: (j['totalQuantity'] as num).toInt(),
        bufferPercent: (j['bufferPercent'] as num?)?.toInt() ?? 0,
        buyQuantity: (j['buyQuantity'] as num?)?.toInt() ?? (j['totalQuantity'] as num).toInt(),
        forecastRate: _d(j['forecastRate']),
        maxRate: _d(j['maxRate']),
        capturedRate: j['capturedRate'] == null ? null : _d(j['capturedRate']),
        estimatedAmount: _d(j['estimatedAmount']),
      );
}

class CutoffException {
  const CutoffException({required this.orderRef, required this.reason, required this.type});
  final String orderRef;
  final String reason;
  final String type;

  factory CutoffException.fromJson(Map<String, dynamic> j) => CutoffException(
        orderRef: j['orderRef'] as String,
        reason: j['reason'] as String,
        type: j['type'] as String? ?? 'INFO',
      );
}

class Cutoff {
  const Cutoff({
    required this.weekStart,
    required this.approved,
    required this.pending,
    required this.needsAttention,
    required this.cancelled,
    required this.exceptions,
  });

  final String weekStart;
  final int approved;
  final int pending;
  final int needsAttention;
  final int cancelled;
  final List<CutoffException> exceptions;

  factory Cutoff.fromJson(Map<String, dynamic> j) => Cutoff(
        weekStart: j['weekStart'] as String,
        approved: (j['approved'] as num).toInt(),
        pending: (j['pending'] as num).toInt(),
        needsAttention: (j['needsAttention'] as num).toInt(),
        cancelled: (j['cancelled'] as num).toInt(),
        exceptions: ((j['exceptions'] as List?) ?? const [])
            .map((e) => CutoffException.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FulfillmentOrder {
  const FulfillmentOrder({
    required this.orderId,
    required this.ref,
    required this.community,
    this.slot,
    required this.stage,
    this.finalTotal,
  });

  final String orderId;
  final String ref;
  final String community;
  final String? slot;
  final String stage; // PENDING | PACKING | PACKED | OUT_FOR_DELIVERY | DELIVERED
  final double? finalTotal;

  factory FulfillmentOrder.fromJson(Map<String, dynamic> j) => FulfillmentOrder(
        orderId: j['orderId'] as String,
        ref: j['ref'] as String,
        community: j['community'] as String? ?? 'Unassigned',
        slot: j['slot'] as String?,
        stage: j['stage'] as String? ?? 'PENDING',
        finalTotal: j['finalTotal'] == null ? null : _d(j['finalTotal']),
      );
}

class PackingWave {
  const PackingWave({required this.community, required this.total, required this.packed, required this.orders});
  final String community;
  final int total;
  final int packed;
  final List<FulfillmentOrder> orders;

  double get progress => total == 0 ? 0 : packed / total;

  factory PackingWave.fromJson(Map<String, dynamic> j) => PackingWave(
        community: j['community'] as String? ?? 'Unassigned',
        total: (j['total'] as num).toInt(),
        packed: (j['packed'] as num).toInt(),
        orders: ((j['orders'] as List?) ?? const [])
            .map((e) => FulfillmentOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PackingSummary {
  const PackingSummary({
    required this.total,
    required this.pending,
    required this.packing,
    required this.packed,
    required this.waves,
  });
  final int total;
  final int pending;
  final int packing;
  final int packed;
  final List<PackingWave> waves;

  factory PackingSummary.fromJson(Map<String, dynamic> j) => PackingSummary(
        total: (j['total'] as num).toInt(),
        pending: (j['pending'] as num).toInt(),
        packing: (j['packing'] as num).toInt(),
        packed: (j['packed'] as num).toInt(),
        waves: ((j['waves'] as List?) ?? const [])
            .map((e) => PackingWave.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DeliverySummary {
  const DeliverySummary({
    required this.readyToDispatch,
    required this.outForDelivery,
    required this.delivered,
    required this.orders,
  });
  final int readyToDispatch;
  final int outForDelivery;
  final int delivered;
  final List<FulfillmentOrder> orders;

  factory DeliverySummary.fromJson(Map<String, dynamic> j) => DeliverySummary(
        readyToDispatch: (j['readyToDispatch'] as num).toInt(),
        outForDelivery: (j['outForDelivery'] as num).toInt(),
        delivered: (j['delivered'] as num).toInt(),
        orders: ((j['orders'] as List?) ?? const [])
            .map((e) => FulfillmentOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CaptureResult {
  const CaptureResult({required this.weekStart, required this.captured});
  final String weekStart;
  final int captured;

  factory CaptureResult.fromJson(Map<String, dynamic> j) => CaptureResult(
        weekStart: j['weekStart'] as String,
        captured: (j['captured'] as num).toInt(),
      );
}

class FinalizeResult {
  const FinalizeResult({
    required this.weekStart,
    required this.ordersProcessed,
    required this.finalized,
    required this.awaitingApproval,
    required this.totalFinal,
  });

  final String weekStart;
  final int ordersProcessed;
  final int finalized;
  final int awaitingApproval;
  final double totalFinal;

  factory FinalizeResult.fromJson(Map<String, dynamic> j) => FinalizeResult(
        weekStart: j['weekStart'] as String,
        ordersProcessed: (j['ordersProcessed'] as num).toInt(),
        finalized: (j['finalized'] as num).toInt(),
        awaitingApproval: (j['awaitingApproval'] as num).toInt(),
        totalFinal: _d(j['totalFinal']),
      );
}
