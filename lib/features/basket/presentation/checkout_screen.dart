import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../order/presentation/order_providers.dart';
import '../domain/checkout_preview.dart';
import 'basket_providers.dart';

class BasketCheckoutScreen extends ConsumerStatefulWidget {
  const BasketCheckoutScreen({super.key});
  @override
  ConsumerState<BasketCheckoutScreen> createState() =>
      _BasketCheckoutScreenState();
}

class _BasketCheckoutScreenState extends ConsumerState<BasketCheckoutScreen> {
  CheckoutPreview? _review;
  String? _error;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  String _message(Object e) => e is ApiFailure
      ? e.userMessage
      : 'Could not complete this request. Please try again.';
  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
      _review = null;
    });
    try {
      final review = await ref.read(basketRepositoryProvider).checkoutPreview();
      if (mounted) setState(() => _review = review);
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy || _review == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref.read(basketRepositoryProvider).checkout(_review!);
      ref.invalidate(basketProvider);
      ref.invalidate(ordersProvider);
      if (mounted) context.go(Routes.orderBillPath(order.id));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _message(e);
          // A rejected review must be refreshed. Keep the same basket/token
          // after transport failures so retrying can recover the existing order.
          if (e is ApiFailure && e.errorCode == 'VALIDATION_ERROR') {
            _review = null;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _address() => context.go('${Routes.address}?edit=true&from=checkout');
  Widget _row(String label, double amount, {bool total = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Row(children: [
        Expanded(child: Text(label)),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: total ? FontWeight.w800 : FontWeight.w600,
                fontSize: total ? 18 : 14))
      ]));
  @override
  Widget build(BuildContext context) {
    final review = _review;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Review your order'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _busy ? null : () => context.go(Routes.basket))),
      body: review == null && _busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: PageBody(
                  maxWidth: 800,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          NsCard(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                Text(_error!,
                                    style: const TextStyle(
                                        color: AppColors.danger)),
                                const SizedBox(height: Gap.sm),
                                OutlinedButton(
                                    onPressed: _busy ? null : _load,
                                    child: const Text('Refresh review')),
                              ])),
                          const SizedBox(height: Gap.lg),
                        ],
                        NsCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Delivery',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: Gap.sm),
                              Text(review?.deliveryAddress ??
                                  'Choose a serviceable delivery address.'),
                              if (review?.deliverySlot != null)
                                Text(review!.deliverySlot!),
                              TextButton(
                                  onPressed: _busy ? null : _address,
                                  child: const Text('Change delivery address')),
                            ])),
                        if (review != null) ...[
                          const SizedBox(height: Gap.lg),
                          NsCard(
                              child: Column(children: [
                            for (final line in review.items)
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: Gap.sm),
                                  child: Row(children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(line.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          Text(
                                              '${line.quantity} × ${line.unit} · ₹${line.unitPrice.toStringAsFixed(2)} each',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary)),
                                        ])),
                                    const SizedBox(width: Gap.sm),
                                    Text('₹${line.amount.toStringAsFixed(2)}')
                                  ])),
                          ])),
                          const SizedBox(height: Gap.lg),
                          NsCard(
                              child: Column(children: [
                            _row('Items', review.subtotal),
                            _row('Delivery fee', review.deliveryFee),
                            const Divider(),
                            _row('Order total', review.total, total: true)
                          ])),
                          const SizedBox(height: Gap.lg),
                          const Text(
                              'Your confirmed item prices stay fixed. Payment is requested after the store prepares your order.'),
                          const SizedBox(height: Gap.lg),
                        ],
                      ]))),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 768),
                      child: FilledButton(
                          onPressed: _busy || review == null ? null : _confirm,
                          child: Text(_busy
                              ? 'Please wait…'
                              : review == null
                                  ? 'Review required'
                                  : 'Confirm order · ₹${review.total.toStringAsFixed(2)}')))))),
    );
  }
}
