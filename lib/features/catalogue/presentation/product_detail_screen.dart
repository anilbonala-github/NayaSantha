import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../basket/presentation/basket_providers.dart';
import '../domain/catalogue_models.dart';
import 'catalogue_providers.dart';

/// Dynamic product page (Vol2 §6.3): loads the product by id and its current
/// price; Add persists to the backend basket.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(e is ApiFailure ? e.userMessage : 'Could not load this product.',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.md),
            FilledButton(
                onPressed: () => ref.invalidate(productProvider(productId)),
                child: const Text('Retry')),
          ]),
        ),
        data: (p) => _body(context, ref, p),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Product p) {
    final int qty = ref.watch(basketProvider).maybeWhen(
        data: (b) => b.items.where((i) => i.productId == p.id).fold<int>(0, (s, i) => s + i.quantity),
        orElse: () => 0);
    return Column(children: <Widget>[
      Expanded(
        child: SingleChildScrollView(
          child: PageBody(
            maxWidth: 700,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const SizedBox(height: Gap.lg),
              Center(child: ProduceAvatar(emoji: p.emoji ?? '🛒', size: 96)),
              const SizedBox(height: Gap.lg),
              Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(children: <Widget>[
                Text(p.unit, style: const TextStyle(color: AppColors.textSecondary)),
                if (p.rating != null) ...<Widget>[
                  const SizedBox(width: Gap.sm),
                  const Icon(Icons.star_rounded, size: 15, color: AppColors.turmeric),
                  Text('${p.rating!.toStringAsFixed(1)} (${p.ratingCount})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ]),
              const SizedBox(height: Gap.md),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                Text('₹${(p.sellingPrice ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                if (p.mrp != null && p.mrp! > (p.sellingPrice ?? 0)) ...<Widget>[
                  const SizedBox(width: Gap.sm),
                  Text('₹${p.mrp!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                ],
                const SizedBox(width: Gap.sm),
                if (p.maxPrice != null)
                  Text('max ₹${p.maxPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              if (p.badges.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.md),
                Wrap(spacing: Gap.sm, children: p.badges
                    .map((b) => StatusChip(label: b, color: AppColors.forest)).toList()),
              ],
              if (p.origin != null) ...<Widget>[
                const SizedBox(height: Gap.md),
                Text('Origin: ${p.origin}', style: const TextStyle(color: AppColors.textSecondary)),
              ],
              if (p.description != null && p.description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.md),
                Text(p.description!, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: Gap.section),
            ]),
          ),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 668),
              child: FilledButton(
                onPressed: p.inStock ? () => _add(context, ref, p) : null,
                child: Text(qty > 0 ? 'Add another (in basket: $qty)' : 'Add to basket'),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Future<void> _add(BuildContext context, WidgetRef ref, Product p) async {
    try {
      await ref.read(basketProvider.notifier).add(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${p.name} added'), duration: const Duration(seconds: 1)));
      }
    } on ApiFailure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.userMessage)));
      }
    }
  }
}
