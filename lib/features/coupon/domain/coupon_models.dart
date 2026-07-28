// Coupon mirroring the backend CouponDto.

class Coupon {
  const Coupon({
    required this.code,
    required this.title,
    this.description,
    this.summary,
    required this.discountType,
    required this.discountValue,
    this.minBasket = 0,
    this.maxDiscount,
    this.newUsersOnly = false,
    this.membersOnly = false,
    this.tint,
    this.validUntil,
  });

  final String code;
  final String title;
  final String? description;
  final String? summary;
  final String discountType; // PERCENT | FLAT
  final double discountValue;
  final double minBasket;
  final double? maxDiscount;
  final bool newUsersOnly;
  final bool membersOnly;
  final String? tint;
  final DateTime? validUntil;

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        code: j['code'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        summary: j['summary'] as String?,
        discountType: j['discountType'] as String? ?? 'FLAT',
        discountValue: _d(j['discountValue']),
        minBasket: _d(j['minBasket']),
        maxDiscount: j['maxDiscount'] == null ? null : _d(j['maxDiscount']),
        newUsersOnly: j['newUsersOnly'] as bool? ?? false,
        membersOnly: j['membersOnly'] as bool? ?? false,
        tint: j['tint'] as String?,
        validUntil: j['validUntil'] == null
            ? null
            : DateTime.tryParse(j['validUntil'] as String),
      );
}
