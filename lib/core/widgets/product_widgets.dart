import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Grid card for catalogue and recommendation rails.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final int qty = app.quantityOf(product.id);

    return NsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Center(child: ProduceAvatar(emoji: product.emoji, size: 64)),
              if (product.discountPercent > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  child: StatusChip(
                    label: '${product.discountPercent.round()}% off',
                    color: AppColors.carrot,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Row(
            children: <Widget>[
              Text(
                product.unit,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (product.rating != null) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded,
                    size: 13, color: AppColors.turmeric),
                Text(
                  product.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: <Widget>[
              Text(
                money(product.price),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (product.mrp != null) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  money(product.mrp!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Gap.sm),
          SizedBox(
            height: 34,
            width: double.infinity,
            child: qty == 0
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(34),
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () => app.addToBasket(product),
                    child: const Text('Add'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      QuantityStepper(
                        quantity: qty,
                        compact: true,
                        onChanged: (int v) =>
                            app.setBasketQuantity(product.id, v),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Row layout used inside the basket and plan lists.
class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    this.subtitle,
    this.onTap,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.md),
        child: Row(
          children: <Widget>[
            ProduceAvatar(emoji: product.emoji, size: 46),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? '${product.unit} · ${money(product.price)}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            QuantityStepper(
              quantity: quantity,
              compact: true,
              onChanged: onQuantityChanged,
            ),
            const SizedBox(width: Gap.md),
            SizedBox(
              width: 64,
              child: Text(
                money(product.price * quantity),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive grid that keeps card width sensible from phone to desktop.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onOpen,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 236,
        crossAxisSpacing: Gap.md,
        mainAxisSpacing: Gap.md,
      ),
      itemCount: products.length,
      itemBuilder: (BuildContext c, int i) => ProductCard(
        product: products[i],
        onTap: () => onOpen(products[i]),
      ),
    );
  }
}
