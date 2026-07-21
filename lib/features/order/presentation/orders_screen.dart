import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/order_models.dart';
import 'order_providers.dart';

/// Order history (Vol2 §6.8): paginated cards from the backend, tap for the
/// final bill / settlement.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(e is ApiFailure ? e.userMessage : 'Could not load your orders.',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.md),
            FilledButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('Retry')),
          ]),
        ),
        data: (orders) => orders.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Approve a weekly plan and your orders will appear here.',
                actionLabel: 'Open weekly plan',
                onAction: () => context.go(Routes.weeklyPlan),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersProvider),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: PageBody(
                    maxWidth: 800,
                    child: Column(children: <Widget>[
                      const SizedBox(height: Gap.lg),
                      for (final o in orders) ...<Widget>[
                        _OrderCard(order: o),
                        const SizedBox(height: Gap.md),
                      ],
                      const SizedBox(height: Gap.section),
                    ]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final bool settled = order.finalTotal != null;
    return NsCard(
      onTap: () => context.go(Routes.orderBillPath(order.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          StatusChip(label: _label(order.status), color: _color(order.status)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
        const SizedBox(height: Gap.sm),
        Row(children: <Widget>[
          Expanded(
            child: Text(
              settled
                  ? 'Final ₹${order.finalTotal!.toStringAsFixed(0)}'
                  : 'Estimated ₹${order.estimatedTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          Text('max ₹${order.maximumPayable.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        if (order.deliverySlot != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(order.deliverySlot!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
      ]),
    );
  }

  String _label(String s) => switch (s) {
        'CONFIRMED' => 'Confirmed',
        'LOCKED' => 'Locked',
        'PURCHASING' => 'Purchasing',
        'FINALIZED' => 'Ready to pay',
        'AWAITING_APPROVAL' => 'Approval required',
        'PAID' => 'Paid',
        'DELIVERED' => 'Delivered',
        'CANCELLED' => 'Cancelled',
        _ => s,
      };

  Color _color(String s) => switch (s) {
        'AWAITING_APPROVAL' => AppColors.carrot,
        'PAID' || 'DELIVERED' => AppColors.forest,
        'CANCELLED' => AppColors.textSecondary,
        _ => AppColors.primary,
      };
}
