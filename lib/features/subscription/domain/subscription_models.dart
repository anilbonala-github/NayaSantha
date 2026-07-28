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
    this.pricePerMonth = 0,
    this.renewsAt,
    this.lastBilledAt,
  });

  final String id;
  final String planCode;
  final String? planName;
  final String status;
  final double pricePerMonth;
  final DateTime? renewsAt;
  final DateTime? lastBilledAt;

  bool get isPastDue => status == 'PAST_DUE';

  factory CurrentSubscription.fromJson(Map<String, dynamic> j) => CurrentSubscription(
        id: j['id'] as String,
        planCode: j['planCode'] as String? ?? 'FREE',
        planName: j['planName'] as String?,
        status: j['status'] as String? ?? 'ACTIVE',
        pricePerMonth: (j['pricePerMonth'] as num?)?.toDouble() ?? 0,
        renewsAt: DateTime.tryParse(j['renewsAt'] as String? ?? '')?.toLocal(),
        lastBilledAt: DateTime.tryParse(j['lastBilledAt'] as String? ?? '')?.toLocal(),
      );
}

class SubscriptionPayment {
  const SubscriptionPayment({
    required this.id,
    this.planCode,
    required this.amount,
    required this.status,
    this.reason,
    this.periodEnd,
    this.createdAt,
  });

  final String id;
  final String? planCode;
  final double amount;
  final String status; // PAID | FAILED
  final String? reason;
  final DateTime? periodEnd;
  final DateTime? createdAt;

  bool get isPaid => status == 'PAID';

  factory SubscriptionPayment.fromJson(Map<String, dynamic> j) => SubscriptionPayment(
        id: j['id'] as String,
        planCode: j['planCode'] as String?,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'PAID',
        reason: j['reason'] as String?,
        periodEnd: DateTime.tryParse(j['periodEnd'] as String? ?? '')?.toLocal(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal(),
      );
}
