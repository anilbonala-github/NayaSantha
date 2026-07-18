import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../core/widgets/product_widgets.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// 12 — Basket review.
class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    if (app.basket.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Basket')),
        body: EmptyState(
          icon: Icons.shopping_basket_outlined,
          title: 'Your basket is empty',
          message:
              'Generate a weekly plan and we will fill it with the right '
              'quantities for your household.',
          actionLabel: 'Open weekly plan',
          onAction: () => context.go(Routes.weeklyPlan),
        ),
      );
    }

    final double remaining =
        AppState.freeDeliveryThreshold - app.basketSubtotal;

    return Scaffold(
      appBar: AppBar(
        title: Text('Basket (${app.basketCount} items)'),
        actions: <Widget>[
          TextButton(
            onPressed: () => _confirmClear(context, app),
            child: const Text('Clear'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (remaining > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Gap.md),
                  margin: const EdgeInsets.only(bottom: Gap.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    'Add ${money(remaining)} more for free delivery',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest),
                  ),
                ),
              NsCard(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < app.basket.length; i++) ...<Widget>[
                      ProductRow(
                        product: app.basket[i].product,
                        quantity: app.basket[i].quantity,
                        onTap: () => context
                            .go(Routes.productPath(app.basket[i].product.id)),
                        onQuantityChanged: (int v) => app.setBasketQuantity(
                            app.basket[i].product.id, v),
                      ),
                      if (i != app.basket.length - 1) const Divider(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              NsCard(
                child: Column(
                  children: <Widget>[
                    _SummaryRow(
                        label: 'Subtotal', value: money(app.basketSubtotal)),
                    const SizedBox(height: Gap.sm),
                    _SummaryRow(
                      label: 'Delivery',
                      value: app.deliveryFee == 0
                          ? 'Free'
                          : money(app.deliveryFee),
                      valueColor: app.deliveryFee == 0
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(height: Gap.sm),
                    _SummaryRow(
                      label: 'You save',
                      value: money(app.basketSavings),
                      valueColor: AppColors.success,
                    ),
                    const Divider(height: Gap.xl),
                    _SummaryRow(
                      label: 'Total',
                      value: money(app.basketTotal),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 868),
              child: FilledButton(
                onPressed: () => context.go(Routes.checkout),
                child: Text('Proceed to checkout · ${money(app.basketTotal)}'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, AppState app) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Clear the basket?'),
        content: const Text('This removes every item. Your plan stays intact.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep items')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Clear basket')),
        ],
      ),
    );
    if (yes == true) app.clearBasket();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final bool bold;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// 13 — Product details.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    Product? product;
    for (final Product p in MockData.products) {
      if (p.id == productId) product = p;
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: EmptyState(
          icon: Icons.search_off,
          title: 'Product not found',
          message: 'This item is no longer in the catalogue.',
          actionLabel: 'Browse categories',
          onAction: () => context.go(Routes.categories),
        ),
      );
    }

    final Product p = product;
    final int qty = app.quantityOf(p.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: const Text('Product details'),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(child: ProduceAvatar(emoji: p.emoji, size: 140)),
              const SizedBox(height: Gap.xl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(p.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (p.inStock)
                    const StatusChip(label: 'In stock', color: AppColors.success)
                  else
                    const StatusChip(
                        label: 'Out of stock', color: AppColors.danger),
                ],
              ),
              const SizedBox(height: 4),
              Text(p.unit,
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (p.rating != null) ...<Widget>[
                const SizedBox(height: Gap.sm),
                Row(
                  children: <Widget>[
                    const Icon(Icons.star_rounded,
                        size: 18, color: AppColors.turmeric),
                    const SizedBox(width: 4),
                    Text(
                      p.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${ratingCountLabel(p.ratingCount)} ratings)',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              if (p.badges.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.md),
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  children: p.badges
                      .map((String b) => StatusChip(
                            label: b,
                            color: AppColors.success,
                            icon: Icons.verified_outlined,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: Gap.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    money(p.price),
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  if (p.mrp != null) ...<Widget>[
                    const SizedBox(width: Gap.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        money(p.mrp!),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: StatusChip(
                        label: '${p.discountPercent.round()}% off',
                        color: AppColors.carrot,
                      ),
                    ),
                  ],
                ],
              ),
              if (p.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.lg),
                Text(
                  p.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.5),
                ),
              ],
              const SizedBox(height: Gap.xl),
              NsCard(
                child: Column(
                  children: <Widget>[
                    _DetailRow(label: 'Origin', value: p.origin),
                    if (p.farmer != null) ...<Widget>[
                      const Divider(height: Gap.xl),
                      _DetailRow(label: 'Sourced from', value: p.farmer!),
                    ],
                  ],
                ),
              ),
              if (p.nutritionPer100g.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.xl),
                const SectionHeader(title: 'Nutrition per 100 g'),
                NsCard(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0;
                          i < p.nutritionPer100g.length;
                          i++) ...<Widget>[
                        _DetailRow(
                          label: p.nutritionPer100g.keys.elementAt(i),
                          value: p.nutritionPer100g.values.elementAt(i),
                        ),
                        if (i != p.nutritionPer100g.length - 1)
                          const Divider(height: Gap.xl),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 688),
              child: qty == 0
                  ? FilledButton(
                      onPressed:
                          p.inStock ? () => app.addToBasket(p) : null,
                      child: Text(
                          p.inStock ? 'Add to basket' : 'Notify me when back'),
                    )
                  : Row(
                      children: <Widget>[
                        QuantityStepper(
                          quantity: qty,
                          onChanged: (int v) =>
                              app.setBasketQuantity(p.id, v),
                        ),
                        const SizedBox(width: Gap.lg),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.go(Routes.basket),
                            child: Text('Go to basket · ${money(p.price * qty)}'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label,
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// 14 — Search.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  static const List<String> _suggestions = <String>[
    'Tomato',
    'Milk',
    'Brown rice',
    'Paneer',
    'Spinach',
    'Toor dal',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<Product> results = app.search(_query);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: SizedBox(
          height: 42,
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search products and recipes',
              prefixIcon: Icon(Icons.search, size: 19),
              contentPadding: EdgeInsets.zero,
              fillColor: AppColors.background,
            ),
            onChanged: (String v) => setState(() => _query = v),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_query.isEmpty) ...<Widget>[
                const SectionHeader(title: 'Popular searches'),
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  children: _suggestions
                      .map(
                        (String s) => ActionChip(
                          label: Text(s),
                          onPressed: () {
                            _controller.text = s;
                            setState(() => _query = s);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: Gap.xl),
                const SectionHeader(title: 'Best for you'),
                ProductGrid(
                  products: app.recommended,
                  onOpen: (Product p) =>
                      context.go(Routes.productPath(p.id)),
                ),
              ] else if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.section),
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Nothing matched "$_query"',
                    message:
                        'Try a shorter word, or browse the category it belongs to.',
                    actionLabel: 'Browse categories',
                    onAction: () => context.go(Routes.categories),
                  ),
                )
              else ...<Widget>[
                SectionHeader(
                    title:
                        '${results.length} result${results.length == 1 ? "" : "s"}'),
                ProductGrid(
                  products: results,
                  onOpen: (Product p) =>
                      context.go(Routes.productPath(p.id)),
                ),
              ],
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
    );
  }
}

/// 15 — Categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late String _selected =
      widget.initialCategoryId ?? MockData.categories.first.id;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<Product> products = app.search('', categoryId: _selected);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            itemCount: MockData.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: Gap.sm),
            itemBuilder: (BuildContext c, int i) {
              final Category cat = MockData.categories[i];
              final bool on = cat.id == _selected;
              return Center(
                child: FilterChip(
                  label: Text('${cat.emoji}  ${cat.name}'),
                  selected: on,
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.14),
                  side: BorderSide(
                      color: on ? AppColors.primary : AppColors.border),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: on ? AppColors.forest : AppColors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _selected = cat.id),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: PageBody(
              maxWidth: 1080,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: Gap.section),
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Nothing here yet',
                        message:
                            'We are onboarding vendors for this category. '
                            'Check back next week.',
                      ),
                    )
                  else
                    ProductGrid(
                      products: products,
                      onOpen: (Product p) =>
                          context.go(Routes.productPath(p.id)),
                    ),
                  const SizedBox(height: Gap.section),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
