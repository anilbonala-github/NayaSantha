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
    required this.forecastRate,
    this.capturedRate,
    required this.estimatedAmount,
  });

  final String productId;
  final String name;
  final String? unit;
  final int totalQuantity;
  final double forecastRate;
  final double? capturedRate;
  final double estimatedAmount;

  factory PurchaseLine.fromJson(Map<String, dynamic> j) => PurchaseLine(
        productId: j['productId'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String?,
        totalQuantity: (j['totalQuantity'] as num).toInt(),
        forecastRate: _d(j['forecastRate']),
        capturedRate: j['capturedRate'] == null ? null : _d(j['capturedRate']),
        estimatedAmount: _d(j['estimatedAmount']),
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
