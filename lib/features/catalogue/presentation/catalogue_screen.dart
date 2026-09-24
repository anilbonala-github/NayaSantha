import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/catalogue_models.dart';
import 'catalogue_providers.dart';
import 'product_widgets.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key, this.initialCategoryId});
  final String? initialCategoryId;
  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String? _category;
  String _query = '';
  int _page = 0;
  Timer? _debounce;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _category = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _changePage(int page) {
    setState(() => _page = page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final filter =
        ProductQuery(categoryId: _category, query: _query, page: _page);
    final products = ref.watch(productsProvider(filter));
    final categories = ref.watch(categoriesProvider);
    return Column(children: [
      Expanded(
          child: CustomScrollView(controller: _scroll, slivers: [
        SliverToBoxAdapter(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shop groceries',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Choose your essentials. Prices stay fixed for the week.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 20),
                              TextField(
                                  decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search),
                                      hintText:
                                          'Search vegetables, rice, milk…',
                                      labelText: 'Search products'),
                                  onChanged: (v) {
                                    _debounce?.cancel();
                                    _debounce = Timer(
                                        const Duration(milliseconds: 300), () {
                                      if (mounted)
                                        setState(() {
                                          _query = v.trim();
                                          _page = 0;
                                        });
                                    });
                                  }),
                              const SizedBox(height: 16),
                              categories.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => TextButton.icon(
                                      onPressed: () =>
                                          ref.invalidate(categoriesProvider),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reload categories')),
                                  data: (cats) => Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _chip('All products', null),
                                            ...cats
                                                .map((c) => _chip(c.name, c.id))
                                          ])),
                            ]))))),
        SliverToBoxAdapter(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: products.when(
                          loading: () => const Padding(
                              padding: EdgeInsets.all(48),
                              child:
                                  Center(child: CircularProgressIndicator())),
                          error: (e, _) => Column(children: [
                            Text(e is ApiFailure
                                ? e.userMessage
                                : 'Could not load products.'),
                            TextButton(
                                onPressed: () =>
                                    ref.invalidate(productsProvider(filter)),
                                child: const Text('Try again'))
                          ]),
                          data: (page) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${page.totalElements} products',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 12),
                                if (page.items.isEmpty)
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 48),
                                      child: Text(
                                          'No products found. Try another search or category.')),
                                LayoutBuilder(builder: (context, c) {
                                  final columns = c.maxWidth < 600
                                      ? 2
                                      : c.maxWidth < 900
                                          ? 3
                                          : 4;
                                  final width =
                                      (c.maxWidth - 12 * (columns - 1)) /
                                          columns;
                                  return Wrap(
                                      spacing: 12,
                                      runSpacing: 16,
                                      children: page.items
                                          .map((p) => SizedBox(
                                              width: width,
                                              child: _ProductCard(product: p)))
                                          .toList());
                                }),
                                if (page.totalPages > 1)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                                tooltip: 'Previous page',
                                                onPressed: _page > 0
                                                    ? () =>
                                                        _changePage(_page - 1)
                                                    : null,
                                                icon: const Icon(
                                                    Icons.chevron_left)),
                                            Text(
                                                'Page ${_page + 1} of ${page.totalPages}'),
                                            IconButton(
                                                tooltip: 'Next page',
                                                onPressed: page.hasMore
                                                    ? () =>
                                                        _changePage(_page + 1)
                                                    : null,
                                                icon: const Icon(
                                                    Icons.chevron_right)),
                                          ])),
                              ]),
                        ))))),
      ])),
      const BasketSummaryBar(),
    ]);
  }

  Widget _chip(String name, String? id) => ChoiceChip(
      label: Text(name),
      selected: _category == id,
      onSelected: (_) => setState(() {
            _category = id;
            _page = 0;
          }));
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
              onTap: () => context.push('/product/${product.id}'),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductPhoto(product: product),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: 42,
                                  child: Text(product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700))),
                              Text(product.unit,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text(
                                  product.sellingPrice == null
                                      ? 'Price unavailable'
                                      : '₹${product.sellingPrice!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                            ])),
                  ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: ProductQuantity(product: product)),
        ]));
  }
}
