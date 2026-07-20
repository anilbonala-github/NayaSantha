/// Pantry item mirroring the backend DTO (Vol2 §6.4). Stock/expiry status is
/// computed by the server, not the client.
class PantryItem {
  const PantryItem({
    required this.id,
    this.productId,
    required this.name,
    required this.quantity,
    this.unit,
    required this.lowStockThreshold,
    this.expiryDate,
    required this.stockStatus,
    required this.expiryStatus,
    this.daysToExpiry,
    this.version,
  });

  final String id;
  final String? productId;
  final String name;
  final double quantity;
  final String? unit;
  final double lowStockThreshold;
  final String? expiryDate;
  final String stockStatus; // LOW | OK
  final String expiryStatus; // OK | EXPIRING | EXPIRED
  final int? daysToExpiry;
  final int? version;

  bool get isLow => stockStatus == 'LOW';
  bool get isExpiring => expiryStatus == 'EXPIRING' || expiryStatus == 'EXPIRED';
  bool get needsAttention => isLow || isExpiring;

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        id: j['id'] as String,
        productId: j['productId'] as String?,
        name: j['name'] as String,
        quantity: _d(j['quantity']),
        unit: j['unit'] as String?,
        lowStockThreshold: _d(j['lowStockThreshold']),
        expiryDate: j['expiryDate'] as String?,
        stockStatus: j['stockStatus'] as String? ?? 'OK',
        expiryStatus: j['expiryStatus'] as String? ?? 'OK',
        daysToExpiry: (j['daysToExpiry'] as num?)?.toInt(),
        version: (j['version'] as num?)?.toInt(),
      );
}
