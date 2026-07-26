import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/wallet_models.dart';
import 'wallet_providers.dart';

/// Dynamic wallet: balance + ledger from /wallet.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static const Map<String, (IconData, String)> _labels = <String, (IconData, String)>{
    'REFUND': (Icons.undo, 'Refund'),
    'PROMO': (Icons.card_giftcard, 'Promo credit'),
    'REFERRAL': (Icons.group_add, 'Referral bonus'),
    'TOPUP': (Icons.add, 'Top-up'),
    'ORDER_PAYMENT': (Icons.shopping_basket, 'Order payment'),
    'ADJUSTMENT': (Icons.tune, 'Adjustment'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(walletProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: <Widget>[
          const SizedBox(height: 120),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(e is ApiFailure ? e.userMessage : 'Could not load your wallet.',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.md),
            FilledButton(onPressed: () => ref.invalidate(walletProvider), child: const Text('Retry')),
          ])),
        ]),
        data: (w) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageBody(maxWidth: 720, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(title: 'Wallet'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.leafGradient,
                  borderRadius: BorderRadius.circular(Radii.xl),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  const Text('Available balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(money(w.balance),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Used automatically toward your next order.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: Gap.lg),
              Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
              if (w.transactions.isEmpty)
                const NsCard(child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No wallet activity yet',
                  message: 'Refunds, promos and referral bonuses will show up here.',
                ))
              else
                NsCard(
                  padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                  child: Column(children: <Widget>[
                    for (int i = 0; i < w.transactions.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, color: AppColors.border),
                      _txRow(context, w.transactions[i]),
                    ],
                  ]),
                ),
              const SizedBox(height: Gap.section),
            ],
          )),
        ),
      ),
    );
  }

  Widget _txRow(BuildContext context, WalletTx t) {
    final style = _labels[t.type] ?? (Icons.tune, t.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(children: <Widget>[
        CircleAvatar(
          radius: 18,
          backgroundColor: (t.isCredit ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.12),
          child: Icon(style.$1, size: 18, color: t.isCredit ? AppColors.success : AppColors.textSecondary),
        ),
        const SizedBox(width: Gap.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(style.$2, style: Theme.of(context).textTheme.titleSmall),
          if (t.reason != null && t.reason!.isNotEmpty)
            Text(t.reason!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text('${t.isCredit ? '+' : '−'}${money(t.amount.abs())}',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: t.isCredit ? AppColors.success : AppColors.textPrimary)),
      ]),
    );
  }
}
