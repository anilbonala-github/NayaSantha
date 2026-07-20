/// Basket domain models mirroring the backend (Vol2 §6.6). Estimate and
/// guaranteed maximum are computed by the server, never the client.

class BasketItem {
  const BasketItem({
    required this.id,
    required this.productId,
    this.name,
    this.emoji,
    this.unit,
    required this.quantity,
    required this.unitSellingPrice,
    required this.unitMaxPrice,
    required this.lineEstimate,
    required this.lineMax,
    this.version,
  });

  final String id;
  final String productId;
  final String? name;
  final String? emoji;
  final String? unit;
  final int quantity;
  final double unitSellingPrice;
  final double unitMaxPrice;
  final double lineEstimate;
  final double lineMax;
  final int? version;

  static double _d(dynamic v) => (v as num).toDouble();

  factory BasketItem.fromJson(Map<String, dynamic> j) => BasketItem(
        id: j['id'] as String,
        productId: j['productId'] as String,
        name: j['name'] as String?,
        emoji: j['emoji'] as String?,
        unit: j['unit'] as String?,
        quantity: (j['quantity'] as num).toInt(),
        unitSellingPrice: _d(j['unitSellingPrice']),
        unitMaxPrice: _d(j['unitMaxPrice']),
        lineEstimate: _d(j['lineEstimate']),
        lineMax: _d(j['lineMax']),
        version: (j['version'] as num?)?.toInt(),
      );
}

class Basket {
  const Basket({
    required this.id,
    required this.status,
    required this.itemCount,
    required this.estimatedTotal,
    required this.maximumPayable,
    required this.items,
    this.version,
  });

  final String id;
  final String status;
  final int itemCount;
  final double estimatedTotal;
  final double maximumPayable;
  final List<BasketItem> items;
  final int? version;

  bool get isEmpty => items.isEmpty;

  factory Basket.fromJson(Map<String, dynamic> j) => Basket(
        id: j['id'] as String,
        status: j['status'] as String,
        itemCount: (j['itemCount'] as num).toInt(),
        estimatedTotal: (j['estimatedTotal'] as num?)?.toDouble() ?? 0,
        maximumPayable: (j['maximumPayable'] as num?)?.toDouble() ?? 0,
        items: (j['items'] as List)
            .map((e) => BasketItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        version: (j['version'] as num?)?.toInt(),
      );
}
