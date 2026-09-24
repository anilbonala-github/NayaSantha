import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/catalogue_models.dart';
import 'catalogue_providers.dart';
import 'product_widgets.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(productId));
    return Scaffold(
        appBar: AppBar(
            title: const Text('Product details'),
            leading: IconButton(
                tooltip: 'Back to products',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/categories');
                  }
                })),
        body: product.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(e is ApiFailure
                      ? e.userMessage
                      : 'Could not load this product.'),
                  TextButton(
                      onPressed: () =>
                          ref.invalidate(productProvider(productId)),
                      child: const Text('Retry'))
                ])),
            data: (p) => SingleChildScrollView(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: LayoutBuilder(builder: (context, c) {
                              final photo = ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: ProductPhoto(product: p, height: 320));
                              final details = _details(p);
                              if (c.maxWidth < 700)
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      photo,
                                      const SizedBox(height: 24),
                                      details
                                    ]);
                              return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: photo),
                                    const SizedBox(width: 32),
                                    Expanded(child: details)
                                  ]);
                            })))))),
        bottomNavigationBar: const BasketSummaryBar());
  }

  Widget _details(Product p) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(p.unit,
            style:
                const TextStyle(fontSize: 17, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Text(
            p.sellingPrice == null
                ? 'Price unavailable'
                : '₹${p.sellingPrice!.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.forest)),
        const SizedBox(height: 8),
        const Text('Fixed weekly price. Delivery fee is shown at checkout.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ProductQuantity(product: p),
        const SizedBox(height: 24),
        if (p.description?.isNotEmpty == true) ...[
          const Text('About this product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(p.description!, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 20)
        ],
        if (p.origin?.isNotEmpty == true) Text('Origin: ${p.origin}'),
        if (p.farmer?.isNotEmpty == true) Text('Producer: ${p.farmer}'),
        if (p.rating != null && p.ratingCount > 0)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                  '★ ${p.rating!.toStringAsFixed(1)} · ${p.ratingCount} reviews')),
      ]);
}
