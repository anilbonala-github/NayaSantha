// In-app notification mirroring the backend NotificationDto (Vol2A §13).

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type; // ORDER_CONFIRMED | MARKET_UPDATE | PRICE_EXCEPTION | PAYMENT_COMPLETE
  final String title;
  final String body;
  final String? orderId;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'INFO',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        orderId: j['orderId'] as String?,
        read: j['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}
