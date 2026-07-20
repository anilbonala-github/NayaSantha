/// AI weekly plan mirroring the backend (Vol2 §6.5). Estimate and guaranteed
/// maximum are server-owned; aiExplanation/aiSource support transparency.
class PlanItem {
  const PlanItem({
    required this.id,
    required this.productId,
    this.name,
    this.emoji,
    this.unit,
    required this.quantity,
    required this.lineEstimate,
    required this.lineMax,
    this.reason,
    this.version,
  });

  final String id;
  final String productId;
  final String? name;
  final String? emoji;
  final String? unit;
  final int quantity;
  final double lineEstimate;
  final double lineMax;
  final String? reason;
  final int? version;

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        id: j['id'] as String,
        productId: j['productId'] as String,
        name: j['name'] as String?,
        emoji: j['emoji'] as String?,
        unit: j['unit'] as String?,
        quantity: (j['quantity'] as num).toInt(),
        lineEstimate: _d(j['lineEstimate']),
        lineMax: _d(j['lineMax']),
        reason: j['reason'] as String?,
        version: (j['version'] as num?)?.toInt(),
      );
}

class WeeklyPlan {
  const WeeklyPlan({
    required this.id,
    required this.weekStart,
    required this.status,
    required this.aiSource,
    this.aiExplanation,
    required this.estimatedTotal,
    required this.maximumPayable,
    required this.itemCount,
    required this.items,
    this.version,
  });

  final String id;
  final String weekStart;
  final String status;
  final String aiSource; // GEMINI | FALLBACK
  final String? aiExplanation;
  final double estimatedTotal;
  final double maximumPayable;
  final int itemCount;
  final List<PlanItem> items;
  final int? version;

  factory WeeklyPlan.fromJson(Map<String, dynamic> j) => WeeklyPlan(
        id: j['id'] as String,
        weekStart: j['weekStart'] as String,
        status: j['status'] as String,
        aiSource: j['aiSource'] as String? ?? 'FALLBACK',
        aiExplanation: j['aiExplanation'] as String?,
        estimatedTotal: (j['estimatedTotal'] as num?)?.toDouble() ?? 0,
        maximumPayable: (j['maximumPayable'] as num?)?.toDouble() ?? 0,
        itemCount: (j['itemCount'] as num).toInt(),
        items: (j['items'] as List)
            .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        version: (j['version'] as num?)?.toInt(),
      );
}
