import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/pantry_models.dart';
import 'pantry_providers.dart';

/// Dynamic pantry (Vol2 §6.4): items with backend-computed low-stock + expiry
/// status. "Smart suggestions" surfaces what's low or about to expire.
class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryAsync = ref.watch(pantryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pantry'),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => _addSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item'),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.forest,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: <Widget>[Tab(text: 'My pantry'), Tab(text: 'Smart suggestions')],
          ),
        ),
        body: pantryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(e is ApiFailure ? e.userMessage : 'Could not load your pantry.',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: Gap.md),
              FilledButton(
                  onPressed: () => ref.read(pantryProvider.notifier).refresh(),
                  child: const Text('Retry')),
            ]),
          ),
          data: (items) => TabBarView(
            children: <Widget>[
              _PantryList(
                items: items,
                emptyMessage:
                    'Add what you already have so the planner does not buy it twice.',
              ),
              _PantryList(
                items: items.where((i) => i.needsAttention).toList(),
                emptyMessage: 'Nothing is low or expiring soon. Nice and stocked.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSheet(BuildContext context, WidgetRef ref) async {
    final nameCtl = TextEditingController();
    final qtyCtl = TextEditingController(text: '1');
    final unitCtl = TextEditingController(text: 'kg');
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
            left: Gap.lg, right: Gap.lg, top: Gap.lg,
            bottom: MediaQuery.of(c).viewInsets.bottom + Gap.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Add a pantry item', style: Theme.of(c).textTheme.titleMedium),
          const SizedBox(height: Gap.md),
          TextField(controller: nameCtl, autofocus: true,
              decoration: const InputDecoration(labelText: 'Item name')),
          const SizedBox(height: Gap.sm),
          Row(children: <Widget>[
            Expanded(child: TextField(controller: qtyCtl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'))),
            const SizedBox(width: Gap.md),
            Expanded(child: TextField(controller: unitCtl,
                decoration: const InputDecoration(labelText: 'Unit (kg, L, pcs)'))),
          ]),
          const SizedBox(height: Gap.md),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Add to pantry'),
          )),
        ]),
      ),
    );
    if (added != true || nameCtl.text.trim().isEmpty) return;
    try {
      await ref.read(pantryProvider.notifier).add(
            name: nameCtl.text.trim(),
            quantity: double.tryParse(qtyCtl.text.trim()) ?? 1,
            unit: unitCtl.text.trim(),
          );
    } on ApiFailure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.userMessage)));
      }
    }
  }
}

class _PantryList extends ConsumerWidget {
  const _PantryList({required this.items, required this.emptyMessage});
  final List<PantryItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(
          icon: Icons.kitchen_outlined, title: 'Nothing here', message: emptyMessage);
    }
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 800,
        child: Column(children: <Widget>[
          const SizedBox(height: Gap.lg),
          NsCard(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Column(children: <Widget>[
              for (int i = 0; i < items.length; i++) ...<Widget>[
                _PantryRow(
                  item: items[i],
                  onRemove: () => ref.read(pantryProvider.notifier).remove(items[i].id),
                ),
                if (i != items.length - 1) const Divider(height: 1),
              ],
            ]),
          ),
          const SizedBox(height: Gap.section),
        ]),
      ),
    );
  }
}

class _PantryRow extends StatelessWidget {
  const _PantryRow({required this.item, required this.onRemove});
  final PantryItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(children: <Widget>[
        const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit ?? ''} left',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
          StatusChip(
            label: item.isLow ? 'Low stock' : 'In stock',
            color: item.isLow ? AppColors.carrot : AppColors.success,
          ),
          if (item.daysToExpiry != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.expiryStatus == 'EXPIRED'
                    ? 'Expired'
                    : '${item.daysToExpiry} days left',
                style: TextStyle(
                    fontSize: 11,
                    color: item.isExpiring ? AppColors.carrot : AppColors.textSecondary),
              ),
            ),
        ]),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.textSecondary,
          onPressed: onRemove,
        ),
      ]),
    );
  }
}
