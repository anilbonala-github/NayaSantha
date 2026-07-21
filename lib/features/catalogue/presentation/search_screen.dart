import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../basket/presentation/basket_providers.dart';
import 'catalogue_providers.dart';

/// Dynamic search (Vol2 §6.3): queries the backend catalogue as you type.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, size: 20),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: _query.isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Search the market',
              message: 'Type a product name — tomato, milk, rice…')
          : _results(),
    );
  }

  Widget _results() {
    final resultsAsync = ref.watch(productsProvider(ProductQuery(query: _query)));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Search failed. Try again.')),
      data: (page) => page.items.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No matches',
              message: 'Nothing found for "$_query".')
          : ListView.separated(
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = page.items[i];
                return ListTile(
                  leading: ProduceAvatar(emoji: p.emoji ?? '🛒', size: 36),
                  title: Text(p.name),
                  subtitle: Text('${p.unit} · ₹${(p.sellingPrice ?? 0).toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: () => ref.read(basketProvider.notifier).add(p.id),
                  ),
                  onTap: () => context.go(Routes.productPath(p.id)),
                );
              },
            ),
    );
  }
}
