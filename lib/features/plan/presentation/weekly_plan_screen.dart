import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../basket/presentation/basket_providers.dart';
import '../domain/plan_models.dart';
import 'plan_providers.dart';

/// Dynamic AI Weekly Plan (Vol2 §6.5, Vol2A §6.1): generate, review the estimate
/// + guaranteed maximum, edit quantities, then approve with a price consent.
class AiWeeklyPlanScreen extends ConsumerWidget {
  const AiWeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weeklyPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Weekly Plan')),
      body: planAsync.when(
        loading: () => const _Busy('Loading your plan…'),
        error: (e, _) => _RetryView(
          message:
              e is ApiFailure ? e.userMessage : 'Could not load your plan.',
          onRetry: () => ref.invalidate(weeklyPlanProvider),
        ),
        data: (plan) => plan == null
            ? _GenerateEmpty(
                onGenerate: () =>
                    ref.read(weeklyPlanProvider.notifier).generate())
            : _PlanView(plan: plan),
      ),
    );
  }
}

class _GenerateEmpty extends StatelessWidget {
  const _GenerateEmpty({required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.auto_awesome_outlined,
      title: 'Plan your week with AI',
      message: 'We size a weekly basket for your household within your budget, '
          'skipping what you already have in the pantry.',
      actionLabel: 'Generate weekly plan',
      onAction: onGenerate,
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan});
  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(weeklyPlanProvider.notifier);
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: PageBody(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: Gap.lg),
                  // AI explanation + source (transparency, Vol2 §10).
                  NsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              const Icon(Icons.auto_awesome,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Week of ${plan.weekStart}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              StatusChip(
                                label: plan.aiSource == 'GEMINI'
                                    ? 'Gemini'
                                    : 'Smart plan',
                                color: AppColors.forest,
                              ),
                            ]),
                        if (plan.aiExplanation != null) ...<Widget>[
                          const SizedBox(height: Gap.sm),
                          Text(plan.aiExplanation!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  // Estimate + guaranteed maximum (Vol2A §6.1).
                  NsCard(
                    child: Column(
                      children: <Widget>[
                        _row('Item subtotal',
                            '₹${plan.estimatedTotal.toStringAsFixed(2)}'),
                        const SizedBox(height: Gap.sm),
                        Text(
                          plan.isFixedPrice
                              ? 'These item prices are fixed when you confirm. Delivery and any discounts are shown on your order before payment.'
                              : 'This is an older plan. Generate a new plan to review this week’s fixed prices.',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Text('${plan.itemCount} items',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Gap.sm),
                  NsCard(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < plan.items.length; i++) ...<Widget>[
                          _PlanItemRow(
                            item: plan.items[i],
                            onChanged: plan.status == 'DRAFT'
                                ? (q) => notifier.setItemQuantity(
                                    plan.items[i].id, q,
                                    version: plan.items[i].version)
                                : null,
                          ),
                          if (i != plan.items.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => notifier.generate(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate plan'),
                    ),
                  ),
                  const SizedBox(height: Gap.section),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 868),
                child: FilledButton(
                  onPressed: plan.status == 'APPROVED'
                      ? () => context.go(Routes.basket)
                      : plan.isFixedPrice &&
                              plan.status == 'DRAFT' &&
                              plan.items.isNotEmpty
                          ? () => _openConsent(context, ref)
                          : null,
                  child: Text(plan.status == 'DRAFT'
                      ? 'Add plan to basket'
                      : 'View basket'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openConsent(BuildContext context, WidgetRef ref) async {
    final preference = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ConsentSheet(subtotal: plan.estimatedTotal),
    );
    if (preference == null || !context.mounted) return;

    try {
      await ref.read(basketRepositoryProvider).addPlan(plan.id);
      ref.invalidate(weeklyPlanProvider);
      ref.invalidate(basketProvider);
      if (!context.mounted) return;
      context.go(Routes.basket);
    } on ApiFailure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.userMessage)));
      }
    }
  }

  Widget _row(String label, String value,
      {Color color = AppColors.textPrimary}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  const _PlanItemRow({required this.item, required this.onChanged});
  final PlanItem item;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(
        children: <Widget>[
          ProduceAvatar(emoji: item.emoji ?? '🛒', size: 38),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name ?? 'Item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${item.unit ?? ''} · ₹${item.lineEstimate.toStringAsFixed(2)}'
                  '${item.reason != null && item.reason!.isNotEmpty ? ' · ${item.reason}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _Stepper(quantity: item.quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.quantity, required this.onChanged});
  final int quantity;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(quantity <= 1 ? Icons.delete_outline : Icons.remove,
              size: 16),
          onPressed: onChanged == null ? null : () => onChanged!(quantity - 1),
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 16),
          color: AppColors.primary,
          onPressed: onChanged == null ? null : () => onChanged!(quantity + 1),
        ),
      ]),
    );
  }
}

class _ConsentSheet extends StatelessWidget {
  const _ConsentSheet({required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add plan to your basket',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Gap.md),
                Text('Item subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: Gap.sm),
                const Text(
                    'These items will be added to your existing basket at current prices. Review quantities, delivery and the full total in checkout before confirming your order.'),
                const SizedBox(height: Gap.lg),
                FilledButton(
                    onPressed: () => Navigator.pop(context, 'KEEP_EXACT_ITEMS'),
                    child: const Text('Add items')),
              ]),
        ),
      );
}

class _Busy extends StatelessWidget {
  const _Busy(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: Gap.md),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      );
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: Gap.md),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
