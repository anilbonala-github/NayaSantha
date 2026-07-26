// Referral code + apply result mirroring the backend ReferralDtos.

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class ReferralInfo {
  const ReferralInfo({
    required this.code,
    required this.referredCount,
    required this.totalEarned,
    required this.bonusPerReferral,
  });

  final String code;
  final int referredCount;
  final double totalEarned;
  final double bonusPerReferral;

  factory ReferralInfo.fromJson(Map<String, dynamic> j) => ReferralInfo(
        code: j['code'] as String,
        referredCount: (j['referredCount'] as num?)?.toInt() ?? 0,
        totalEarned: _d(j['totalEarned']),
        bonusPerReferral: _d(j['bonusPerReferral']),
      );
}

class ApplyReferralResult {
  const ApplyReferralResult({required this.bonus, required this.walletBalance});
  final double bonus;
  final double walletBalance;

  factory ApplyReferralResult.fromJson(Map<String, dynamic> j) => ApplyReferralResult(
        bonus: _d(j['bonus']),
        walletBalance: _d(j['walletBalance']),
      );
}
