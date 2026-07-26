// Wallet ledger mirroring the backend WalletDtos.

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class WalletTx {
  const WalletTx({
    required this.id,
    required this.amount,
    required this.type,
    this.reason,
    this.orderId,
    required this.balanceAfter,
    required this.createdAt,
  });

  final String id;
  final double amount; // + credit, - debit
  final String type;   // REFUND | PROMO | REFERRAL | TOPUP | ORDER_PAYMENT | ADJUSTMENT
  final String? reason;
  final String? orderId;
  final double balanceAfter;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;

  factory WalletTx.fromJson(Map<String, dynamic> j) => WalletTx(
        id: j['id'] as String,
        amount: _d(j['amount']),
        type: j['type'] as String? ?? 'ADJUSTMENT',
        reason: j['reason'] as String?,
        orderId: j['orderId'] as String?,
        balanceAfter: _d(j['balanceAfter']),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
}

class Wallet {
  const Wallet({required this.balance, required this.transactions});
  final double balance;
  final List<WalletTx> transactions;

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        balance: _d(j['balance']),
        transactions: ((j['transactions'] as List?) ?? const [])
            .map((e) => WalletTx.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
