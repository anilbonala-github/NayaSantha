/// Delivery address mirroring the backend (Vol2 §6, §7).
class Address {
  const Address({
    required this.id,
    this.label,
    required this.line1,
    this.line2,
    this.apartment,
    required this.city,
    required this.pincode,
    required this.serviceable,
    required this.isDefault,
    this.version,
  });

  final String id;
  final String? label;
  final String line1;
  final String? line2;
  final String? apartment;
  final String city;
  final String pincode;
  final bool serviceable;
  final bool isDefault;
  final int? version;

  String get oneLine => [line1, apartment, city, pincode].where((e) => e != null && e.toString().isNotEmpty).join(', ');

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as String,
        label: j['label'] as String?,
        line1: j['line1'] as String,
        line2: j['line2'] as String?,
        apartment: j['apartment'] as String?,
        city: j['city'] as String? ?? 'Hyderabad',
        pincode: j['pincode'] as String,
        serviceable: j['serviceable'] as bool? ?? false,
        isDefault: j['isDefault'] as bool? ?? false,
        version: (j['version'] as num?)?.toInt(),
      );
}
