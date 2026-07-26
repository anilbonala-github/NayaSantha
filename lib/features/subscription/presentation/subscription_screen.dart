import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
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
      _snack(p.code == 'FREE' ? 'Switched to Basic' : 'You are now on ${p.name}');
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
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PageBody(maxWidth: 1000, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Membership'),
            const Text('Change or cancel any time. Charges apply from the next billing cycle.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.xl),
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
            const SizedBox(height: Gap.section),
          ],
        )),
      ),
    );
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
