// Membership plans + subscription mirroring the backend SubscriptionDtos.

class MembershipPlan {
  const MembershipPlan({
    required this.code,
    required this.name,
    this.badge,
    required this.pricePerMonth,
    required this.perks,
  });

  final String code;
  final String name;
  final String? badge;
  final double pricePerMonth;
  final List<String> perks;

  bool get isFree => pricePerMonth == 0;

  factory MembershipPlan.fromJson(Map<String, dynamic> j) => MembershipPlan(
        code: j['code'] as String,
        name: j['name'] as String,
        badge: j['badge'] as String?,
        pricePerMonth: (j['pricePerMonth'] as num?)?.toDouble() ?? 0,
        perks: ((j['perks'] as List?) ?? const []).map((e) => e as String).toList(),
      );
}

class CurrentSubscription {
  const CurrentSubscription({
    required this.id,
    required this.planCode,
    this.planName,
    required this.status,
    this.renewsAt,
  });

  final String id;
  final String planCode;
  final String? planName;
  final String status;
  final DateTime? renewsAt;

  factory CurrentSubscription.fromJson(Map<String, dynamic> j) => CurrentSubscription(
        id: j['id'] as String,
        planCode: j['planCode'] as String? ?? 'FREE',
        planName: j['planName'] as String?,
        status: j['status'] as String? ?? 'ACTIVE',
        renewsAt: DateTime.tryParse(j['renewsAt'] as String? ?? '')?.toLocal(),
      );
}
