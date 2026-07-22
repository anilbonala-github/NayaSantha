import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/order_models.dart';
import 'order_providers.dart';

/// Final bill + Sunday settlement (Vol2A §6.3–6.5). Shows estimate vs actual,
/// the within-cap auto-charge or the over-cap approval flow, and the final total.
class OrderBillScreen extends ConsumerStatefulWidget {
  const OrderBillScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderBillScreen> createState() => _OrderBillScreenState();
}

class _OrderBillScreenState extends ConsumerState<OrderBillScreen> {
  CustomerOrder? _order;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _run(() => ref.read(orderRepositoryProvider).get(widget.orderId));

  Future<void> _run(Future<CustomerOrder> Function() action) async {
    setState(() { _busy = true; _error = null; });
    try {
      final order = await action();
      if (mounted) setState(() { _order = order; _busy = false; });
    } on ApiFailure catch (f) {
      if (mounted) setState(() { _error = f.userMessage; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order & final bill')),
      body: _error != null
          ? _retry(_error!)
          : _order == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(children: <Widget>[
                  _body(_order!),
                  if (_busy)
                    const Positioned.fill(
                        child: ColoredBox(
                            color: Color(0x66FFFFFF),
                            child: Center(child: CircularProgressIndicator()))),
                ]),
    );
  }

  Widget _body(CustomerOrder o) {
    final repo = ref.read(orderRepositoryProvider);
    final bool settled = o.finalTotal != null;
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: PageBody(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: Gap.lg),
                  Row(children: <Widget>[
                    StatusChip(label: _statusLabel(o.status), color: _statusColor(o.status)),
                    const Spacer(),
                    if (o.deliverySlot != null)
                      Text(o.deliverySlot!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: Gap.lg),

                  // Over-cap exception banner (Vol2A §6.4).
                  if (o.awaitingApproval && o.exception != null) _exceptionBanner(o),

                  // Totals.
                  NsCard(
                    child: Column(children: <Widget>[
                      _row('Estimated total', '₹${o.estimatedTotal.toStringAsFixed(0)}'),
                      const SizedBox(height: Gap.sm),
                      _row('Guaranteed maximum', '₹${o.maximumPayable.toStringAsFixed(0)}',
                          color: AppColors.forest),
                      if (settled) ...<Widget>[
                        const Divider(height: Gap.xl),
                        _row('Final market total', '₹${o.finalTotal!.toStringAsFixed(0)}',
                            bold: true),
                        if (o.savings != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Gap.sm),
                            child: _row(
                              o.savings! >= 0 ? 'You saved' : 'Above estimate (within cap)',
                              '₹${o.savings!.abs().toStringAsFixed(0)}',
                              color: o.savings! >= 0 ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        if (o.hasRefund)
                          Padding(
                            padding: const EdgeInsets.only(top: Gap.sm),
                            child: _row('Refunded', '−₹${o.refundedAmount.toStringAsFixed(0)}',
                                color: AppColors.info, bold: true),
                          ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: Gap.lg),

                  // Estimate vs actual, item by item (Vol2A §6.3 transparency).
                  Text(settled ? 'Estimate vs actual' : 'Items',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Gap.sm),
                  NsCard(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    child: Column(children: <Widget>[
                      for (int i = 0; i < o.items.length; i++) ...<Widget>[
                        _ItemRow(line: o.items[i]),
                        if (i != o.items.length - 1) const Divider(height: 1),
                      ],
                    ]),
                  ),
                  const SizedBox(height: Gap.section),
                ],
              ),
            ),
          ),
        ),
        _actionBar(o, repo),
      ],
    );
  }

  Widget _actionBar(CustomerOrder o, repo) {
    final children = <Widget>[];
    switch (o.status) {
      case 'CONFIRMED':
      case 'LOCKED':
      case 'PURCHASING':
        children.add(FilledButton(
          onPressed: () => _run(() => repo.simulateSettlement(o.id)),
          child: const Text('Run Sunday settlement (demo)'),
        ));
      case 'AWAITING_APPROVAL':
        children.addAll(<Widget>[
          FilledButton(
              onPressed: () => _run(() => repo.decide(o.id, 'REMOVE_EXPENSIVE')),
              child: const Text('Remove expensive items (stay under cap)')),
          const SizedBox(height: Gap.sm),
          OutlinedButton(
              onPressed: () => _run(() => repo.decide(o.id, 'ACCEPT')),
              child: const Text('Accept & pay the higher amount')),
          const SizedBox(height: Gap.sm),
          TextButton(
              onPressed: () => _run(() => repo.decide(o.id, 'CANCEL')),
              child: const Text('Cancel order')),
        ]);
      case 'FINALIZED':
        children.add(FilledButton(
          onPressed: () => _run(() => repo.capture(o.id)),
          child: Text('Pay final amount · ₹${o.finalTotal!.toStringAsFixed(0)}'),
        ));
      case 'PAID':
        children.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.md)),
          child: Text('Paid ₹${o.finalTotal!.toStringAsFixed(0)} · out for Sunday delivery',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
        ));
      case 'CANCELLED':
        children.add(const Text('Order cancelled.', textAlign: TextAlign.center));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 868),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }

  Widget _exceptionBanner(CustomerOrder o) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Gap.lg),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
          color: AppColors.carrot.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Approval required',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.carrot)),
        const SizedBox(height: 4),
        Text(
          'The Sunday market total ₹${o.exception!.finalTotal.toStringAsFixed(0)} is above '
          'your maximum ₹${o.exception!.maxPayable.toStringAsFixed(0)}. Choose how to proceed — '
          'nothing is charged until you decide.',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ]),
    );
  }

  Widget _row(String label, String value,
      {Color color = AppColors.textPrimary, bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
      Text(label,
          style: TextStyle(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: bold ? 16 : 14)),
    ]);
  }

  Widget _retry(String message) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: Gap.md),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );

  String _statusLabel(String s) => switch (s) {
        'CONFIRMED' => 'Confirmed',
        'LOCKED' => 'Locked (Saturday cutoff)',
        'PURCHASING' => 'Sunday purchasing',
        'FINALIZED' => 'Ready to pay',
        'AWAITING_APPROVAL' => 'Approval required',
        'PAID' => 'Paid',
        'DELIVERED' => 'Delivered',
        'CANCELLED' => 'Cancelled',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'AWAITING_APPROVAL' => AppColors.carrot,
        'PAID' || 'DELIVERED' => AppColors.forest,
        'CANCELLED' => AppColors.textSecondary,
        _ => AppColors.primary,
      };
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.line});
  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final bool settled = line.actualRate != null;
    final bool removed = line.removed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(children: <Widget>[
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(line.name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: removed ? TextDecoration.lineThrough : null,
                    color: removed ? AppColors.textSecondary : AppColors.textPrimary)),
            Text(
              removed
                  ? (line.substitutionReason ?? 'Removed')
                  : settled
                      ? '${line.unit ?? ''} · forecast ₹${line.forecastRate.toStringAsFixed(0)} → actual ₹${line.actualRate!.toStringAsFixed(0)}'
                      : '${line.unit ?? ''} · x${line.quantity} · est. ₹${line.estimatedAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ]),
        ),
        if (settled && !removed)
          Text('₹${(line.finalAmount ?? 0).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
