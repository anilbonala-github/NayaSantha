import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../wallet/presentation/wallet_providers.dart';
import '../domain/subscription_models.dart';
import 'subscription_providers.dart';

/// Dynamic membership: plans from /subscription-plans, current from
/// /subscriptions/current; subscribe / cancel wired to the backend.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _busy = false;

  String get _currentCode =>
      ref.watch(currentSubscriptionProvider).maybeWhen(
          data: (s) => s?.planCode ?? 'FREE', orElse: () => 'FREE');

  Future<void> _choose(MembershipPlan p) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      if (p.code == 'FREE') {
        await repo.cancel();
      } else {
        await repo.subscribe(p.code);
      }
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionPaymentsProvider);
      ref.invalidate(walletProvider); // paid plans are charged from the wallet
      _snack(p.code == 'FREE'
          ? 'Switched to Basic'
          : 'You are now on ${p.name} · ${money(p.pricePerMonth)} charged from wallet');
    } on ApiFailure catch (f) {
      _snack(f.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(membershipPlansProvider);
    final current = _currentCode;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(membershipPlansProvider);
        ref.invalidate(currentSubscriptionProvider);
        ref.invalidate(subscriptionPaymentsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PageBody(maxWidth: 1000, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Membership'),
            const Text('Change or cancel any time. Paid plans are billed from your wallet — '
                'the first month now, then monthly.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.lg),
            _currentMembershipCard(),
            plansAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(Gap.section),
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => _errorCard(e),
              data: (plans) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 340,
                  crossAxisSpacing: Gap.md,
                  mainAxisSpacing: Gap.md,
                ),
                itemCount: plans.length,
                itemBuilder: (c, i) => _planCard(plans[i], plans[i].code == current),
              ),
            ),
            _billingHistory(),
            const SizedBox(height: Gap.section),
          ],
        )),
      ),
    );
  }

  Widget _currentMembershipCard() {
    final async = ref.watch(currentSubscriptionProvider);
    final sub = async.asData?.value;
    if (sub == null || sub.planCode == 'FREE') return const SizedBox.shrink();
    final bool pastDue = sub.isPastDue;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: NsCard(
        color: pastDue
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.06),
        borderColor: pastDue
            ? AppColors.danger.withValues(alpha: 0.5)
            : AppColors.primary.withValues(alpha: 0.4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Icon(pastDue ? Icons.error_outline : Icons.workspace_premium,
                size: 20, color: pastDue ? AppColors.danger : AppColors.primary),
            const SizedBox(width: Gap.sm),
            Text(sub.planName ?? sub.planCode,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const Spacer(),
            StatusChip(
                label: pastDue ? 'Past due' : 'Active',
                color: pastDue ? AppColors.danger : AppColors.success),
          ]),
          const SizedBox(height: Gap.sm),
          if (pastDue)
            const Text('We couldn’t renew from your wallet. Top up and we’ll retry — '
                'your membership stays active in the meantime.',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary))
          else
            Text(
              '${money(sub.pricePerMonth)}/month from wallet'
              '${sub.renewsAt != null ? ' · renews ${_fmt(sub.renewsAt!)}' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
        ]),
      ),
    );
  }

  Widget _billingHistory() {
    final async = ref.watch(subscriptionPaymentsProvider);
    final items = async.asData?.value ?? const <SubscriptionPayment>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Gap.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Billing history', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: Gap.sm),
        NsCard(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Column(children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              _paymentRow(items[i]),
              if (i != items.length - 1) const Divider(height: 1),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _paymentRow(SubscriptionPayment p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(children: <Widget>[
        Icon(p.isPaid ? Icons.check_circle : Icons.cancel,
            size: 18, color: p.isPaid ? AppColors.success : AppColors.danger),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('${p.planCode ?? 'Plan'} · ${p.reason ?? (p.isPaid ? 'Payment' : 'Failed')}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            if (p.createdAt != null)
              Text(_fmt(p.createdAt!),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        Text('${p.isPaid ? '−' : ''}${money(p.amount)}',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: p.isPaid ? AppColors.textPrimary : AppColors.textSecondary)),
      ]),
    );
  }

  static String _fmt(DateTime d) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _planCard(MembershipPlan p, bool isCurrent) {
    return NsCard(
      borderColor: isCurrent ? AppColors.primary : AppColors.border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (p.badge != null) StatusChip(label: p.badge!, color: AppColors.carrot),
        ]),
        const SizedBox(height: Gap.sm),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
          Text(p.isFree ? 'Free' : money(p.pricePerMonth),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          if (!p.isFree)
            const Padding(
              padding: EdgeInsets.only(bottom: 4, left: 4),
              child: Text('/month', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
        ]),
        const SizedBox(height: Gap.md),
        Expanded(child: ListView(padding: EdgeInsets.zero, children: <Widget>[
          for (final perk in p.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                const Icon(Icons.check_circle_outline, size: 15, color: AppColors.success),
                const SizedBox(width: Gap.sm),
                Expanded(child: Text(perk, style: const TextStyle(fontSize: 13, height: 1.3))),
              ]),
            ),
        ])),
        const SizedBox(height: Gap.sm),
        SizedBox(width: double.infinity, child: isCurrent
            ? const OutlinedButton(onPressed: null, child: Text('Current plan'))
            : FilledButton(
                onPressed: _busy ? null : () => _choose(p),
                style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
                child: Text(p.isFree ? 'Switch to Basic' : 'Choose ${p.name}'),
              )),
      ]),
    );
  }

  Widget _errorCard(Object e) {
    final msg = e is ApiFailure ? e.userMessage : 'Could not load plans.';
    return NsCard(borderColor: AppColors.danger, child: Row(children: <Widget>[
      const Icon(Icons.error_outline, color: AppColors.danger),
      const SizedBox(width: Gap.sm),
      Expanded(child: Text(msg)),
      TextButton(onPressed: () => ref.invalidate(membershipPlansProvider), child: const Text('Retry')),
    ]));
  }
}
