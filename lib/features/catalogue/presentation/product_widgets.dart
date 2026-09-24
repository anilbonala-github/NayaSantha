import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../basket/presentation/basket_providers.dart';
import '../domain/catalogue_models.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({super.key, required this.product, this.height = 150});
  final Product product;
  final double height;
  @override
  Widget build(BuildContext context) {
    final path = product.imageUrl;
    final url =
        path?.startsWith('/') == true ? '${ApiConfig.baseUrl}$path' : path;
    final fallback = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(product.emoji ?? '🥬', style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 6),
      const Text('Photo coming soon',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]));
    return SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
            color: const Color(0xFFF0F5EC),
            child: url == null || url.isEmpty
                ? fallback
                : Image.network(url,
                    fit: BoxFit.cover,
                    semanticLabel: product.name,
                    errorBuilder: (_, __, ___) => fallback)));
  }
}

class ProductQuantity extends ConsumerStatefulWidget {
  const ProductQuantity({super.key, required this.product});
  final Product product;
  @override
  ConsumerState<ProductQuantity> createState() => _ProductQuantityState();
}

class _ProductQuantityState extends ConsumerState<ProductQuantity> {
  bool _busy = false;
  Future<void> _change(int change) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(basketRepositoryProvider);
      final basket = await repo.current();
      final matches =
          basket.items.where((i) => i.productId == widget.product.id);
      if (change > 0) {
        await repo.addItem(widget.product.id);
      } else if (matches.isNotEmpty) {
        final item = matches.first;
        if (item.quantity <= 1) {
          await repo.removeItem(item.id);
        } else {
          await repo.updateItem(item.id,
              quantity: item.quantity - 1, version: item.version);
        }
      }
      await ref.read(basketProvider.notifier).refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiFailure
                ? e.userMessage
                : 'Could not update your basket. Try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(basketProvider);
    final qty = state.valueOrNull?.items
            .where((i) => i.productId == widget.product.id)
            .fold<int>(0, (a, i) => a + i.quantity) ??
        0;
    final available =
        widget.product.inStock && widget.product.sellingPrice != null;
    if (!available)
      return const SizedBox(
          height: 44,
          child: Center(
              child: Text('Unavailable',
                  style: TextStyle(color: AppColors.textSecondary))));
    if (qty == 0)
      return SizedBox(
          height: 44,
          width: double.infinity,
          child: FilledButton(
              onPressed: _busy ? null : () => _change(1),
              child: Text(_busy ? 'Adding…' : 'Add')));
    return Container(
        height: 44,
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              tooltip: 'Remove one ${widget.product.name}',
              onPressed: _busy ? null : () => _change(-1),
              icon: const Icon(Icons.remove, size: 18)),
          Text(_busy ? '…' : '$qty',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
              tooltip: 'Add one ${widget.product.name}',
              onPressed: _busy ? null : () => _change(1),
              icon: const Icon(Icons.add, size: 18)),
        ]));
  }
}

class BasketSummaryBar extends ConsumerWidget {
  const BasketSummaryBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(basketProvider).valueOrNull;
    if (b == null || b.isEmpty) return const SizedBox.shrink();
    return SafeArea(
        top: false,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilledButton.icon(
                onPressed: () => context.push('/basket'),
                icon: const Icon(Icons.shopping_basket_outlined),
                label: Text(
                    'View basket · ${b.itemCount} items · ₹${b.estimatedTotal.toStringAsFixed(2)}'))));
  }
}
