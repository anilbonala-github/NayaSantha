import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/basket_models.dart';
import 'basket_providers.dart';

/// Dynamic basket (Vol2 §6.6): items + server-recalculated estimated total and
/// guaranteed maximum payable (Vol2A). Quantity edits persist to the backend.
class BasketScreen extends ConsumerWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketAsync = ref.watch(basketProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Basket')),
      body: basketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(e is ApiFailure ? e.userMessage : 'Could not load your basket.',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: Gap.md),
              FilledButton(
                  onPressed: () => ref.read(basketProvider.notifier).refresh(),
                  child: const Text('Retry')),
            ],
          ),
        ),
        data: (basket) => basket.isEmpty
            ? EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: 'Your basket is empty',
                message: 'Browse the catalogue or generate a weekly plan to fill it.',
                actionLabel: 'Browse catalogue',
                onAction: () => context.go(Routes.categories),
              )
            : _BasketBody(basket: basket),
      ),
    );
  }
}

class _BasketBody extends ConsumerWidget {
  const _BasketBody({required this.basket});
  final Basket basket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(basketProvider.notifier);
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
                  NsCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.lg, vertical: Gap.sm),
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < basket.items.length; i++) ...<Widget>[
                          _BasketItemRow(
                            item: basket.items[i],
                            onChanged: (qty) => notifier.setQuantity(
                                basket.items[i].id, qty,
                                version: basket.items[i].version),
                          ),
                          if (i != basket.items.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  NsCard(
                    child: Column(
                      children: <Widget>[
                        _SummaryRow(
                            label: 'Estimated total',
                            value: '₹${basket.estimatedTotal.toStringAsFixed(0)}'),
                        const SizedBox(height: Gap.sm),
                        _SummaryRow(
                          label: 'Guaranteed maximum payable',
                          value: '₹${basket.maximumPayable.toStringAsFixed(0)}',
                          valueColor: AppColors.forest,
                        ),
                        const SizedBox(height: Gap.sm),
                        const Text(
                          'You are never charged above the maximum without your approval. '
                          'You pay the actual Sunday market total.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 868),
                child: FilledButton(
                  onPressed: () => context.go(Routes.checkout),
                  child: Text(
                      'Proceed · est. ₹${basket.estimatedTotal.toStringAsFixed(0)}'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item, required this.onChanged});
  final BasketItem item;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(
        children: <Widget>[
          ProduceAvatar(emoji: item.emoji ?? '🛒', size: 40),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name ?? 'Item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${item.unit ?? ''} · ₹${item.lineEstimate.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _QtyStepper(quantity: item.quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.quantity, required this.onChanged});
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(quantity <= 1 ? Icons.delete_outline : Icons.remove, size: 18),
            onPressed: () => onChanged(quantity - 1),
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.primary,
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor = AppColors.textPrimary});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }
}
