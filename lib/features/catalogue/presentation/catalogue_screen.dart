import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../basket/presentation/basket_providers.dart';
import '../domain/catalogue_models.dart';
import 'catalogue_providers.dart';

/// Dynamic catalogue: real categories + products from the backend, with Add
/// persisting to the backend basket (Vol2 §6.3). Replaces the mock CategoriesScreen.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String? _selectedCategoryId; // null = all categories

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(
        productsProvider(ProductQuery(categoryId: _selectedCategoryId)));

    return Column(
      children: <Widget>[
        SizedBox(height: 56, child: _categoryStrip(categoriesAsync)),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              failure: e is ApiFailure ? e : null,
              onRetry: () => ref.invalidate(
                  productsProvider(ProductQuery(categoryId: _selectedCategoryId))),
            ),
            data: (page) => page.items.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nothing here yet',
                    message: 'We are onboarding vendors for this category. '
                        'Check back next week.',
                  )
                : SingleChildScrollView(
                    child: PageBody(
                      maxWidth: 1080,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                        child: Wrap(
                          spacing: Gap.md,
                          runSpacing: Gap.md,
                          children: page.items
                              .map((p) => SizedBox(
                                  width: 168, child: _ProductCard(product: p)))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _categoryStrip(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const Center(
          child: SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) {
        final chips = <Widget>[_chip('All', null)];
        chips.addAll(cats.map((c) => _chip('${c.emoji ?? ''}  ${c.name}'.trim(), c.id)));
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: Gap.sm),
          itemBuilder: (_, i) => Center(child: chips[i]),
        );
      },
    );
  }

  Widget _chip(String label, String? categoryId) {
    final bool on = _selectedCategoryId == categoryId;
    return FilterChip(
      label: Text(label),
      selected: on,
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.14),
      side: BorderSide(color: on ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: on ? AppColors.forest : AppColors.textPrimary,
      ),
      onSelected: (_) => setState(() => _selectedCategoryId = categoryId),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  int _discountPercent() {
    final mrp = product.mrp, price = product.sellingPrice;
    if (mrp == null || price == null || mrp <= price) return 0;
    return ((mrp - price) / mrp * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Quantity already in the (real) basket, to show a live count on the card.
    final int qty = ref.watch(basketProvider).maybeWhen(
        data: (b) => b.items
            .where((i) => i.productId == product.id)
            .fold<int>(0, (s, i) => s + i.quantity),
        orElse: () => 0);
    final int discount = _discountPercent();

    return NsCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Center(child: ProduceAvatar(emoji: product.emoji ?? '🛒', size: 60)),
              if (discount > 0)
                Positioned(
                    left: 0,
                    top: 0,
                    child: StatusChip(label: '$discount% off', color: AppColors.carrot)),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Row(
            children: <Widget>[
              Text(product.unit,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (product.rating != null) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded, size: 13, color: AppColors.turmeric),
                Text(product.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          const SizedBox(height: Gap.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text('₹${(product.sellingPrice ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (product.mrp != null && product.mrp! > (product.sellingPrice ?? 0)) ...<Widget>[
                const SizedBox(width: 6),
                Text('₹${product.mrp!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough)),
              ],
            ],
          ),
          const SizedBox(height: Gap.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: product.inStock ? () => _add(context, ref) : null,
              child: Text(qty > 0 ? 'Added ($qty)' : 'Add'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(basketProvider.notifier).add(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} added to basket'), duration: const Duration(seconds: 1)),
        );
      }
    } on ApiFailure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.userMessage)));
      }
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.failure, required this.onRetry});
  final ApiFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(failure?.isOffline == true ? Icons.wifi_off : Icons.error_outline,
              size: 40, color: AppColors.textSecondary),
          const SizedBox(height: Gap.md),
          Text(failure?.userMessage ?? 'Could not load products.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: Gap.md),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
