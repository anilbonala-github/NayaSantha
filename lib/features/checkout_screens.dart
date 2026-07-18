import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// 16 — Checkout: address, slot, order review.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const List<String> _slots = <String>[
    'Today, 3:00 PM – 5:00 PM',
    'Today, 6:00 PM – 8:00 PM',
    'Tomorrow, 7:00 AM – 9:00 AM',
    'Tomorrow, 10:00 AM – 12:00 PM',
  ];

  String _slot = _slots.first;
  final TextEditingController _instructions = TextEditingController();

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    if (app.basket.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.shopping_basket_outlined,
          title: 'Nothing to check out',
          message: 'Add items to your basket first.',
          actionLabel: 'Go to weekly plan',
          onAction: () => context.go(Routes.weeklyPlan),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.basket),
        ),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(title: 'Delivery address'),
              ...app.addresses.map(
                (Address a) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: NsCard(
                    borderColor:
                        a.isDefault ? AppColors.primary : AppColors.border,
                    onTap: () => app.setDefaultAddress(a.id),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.md, vertical: Gap.sm),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          a.isDefault
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: a.isDefault
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(a.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                a.oneLine,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Delivery slot'),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: _slots.map((String s) {
                  final bool on = s == _slot;
                  return ChoiceChip(
                    label: Text(s),
                    selected: on,
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withValues(alpha: 0.14),
                    side: BorderSide(
                        color: on ? AppColors.primary : AppColors.border),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on ? AppColors.forest : AppColors.textPrimary,
                    ),
                    onSelected: (_) => setState(() => _slot = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Delivery instructions'),
              TextField(
                controller: _instructions,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Gate code, landmark, or where to leave the box',
                ),
              ),
              const SizedBox(height: Gap.xl),
              SectionHeader(
                title: 'Order summary (${app.basketCount} items)',
                actionLabel: 'Edit',
                onAction: () => context.go(Routes.basket),
              ),
              NsCard(
                child: Column(
                  children: <Widget>[
                    ...app.basket.take(4).map(
                          (BasketLine l) => Padding(
                            padding: const EdgeInsets.only(bottom: Gap.sm),
                            child: Row(
                              children: <Widget>[
                                Text(l.product.emoji),
                                const SizedBox(width: Gap.sm),
                                Expanded(
                                  child: Text(
                                    '${l.product.name} × ${l.quantity}',
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ),
                                Text(money(l.total),
                                    style: const TextStyle(fontSize: 13.5)),
                              ],
                            ),
                          ),
                        ),
                    if (app.basket.length > 4)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+ ${app.basket.length - 4} more items',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    const Divider(height: Gap.xl),
                    _Line(label: 'Subtotal', value: money(app.basketSubtotal)),
                    _Line(
                      label: 'Delivery',
                      value: app.deliveryFee == 0
                          ? 'Free'
                          : money(app.deliveryFee),
                    ),
                    const SizedBox(height: Gap.sm),
                    _Line(
                        label: 'Total',
                        value: money(app.basketTotal),
                        bold: true),
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
              constraints: const BoxConstraints(maxWidth: 728),
              child: FilledButton(
                onPressed: () => context.go(Routes.payment),
                child: Text('Continue to payment · ${money(app.basketTotal)}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color:
                    bold ? AppColors.textPrimary : AppColors.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 17 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

/// 17 — Payment.
///
/// This screen never collects raw card details. In production, hand off to the
/// Razorpay SDK, which renders its own PCI-compliant sheet; NayaSantha only
/// receives the payment token and the result.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'UPI';
  bool _useWallet = false;
  bool _busy = false;

  static const List<(String, IconData, String)> _methods =
      <(String, IconData, String)>[
    ('UPI', Icons.qr_code_2, 'Google Pay, PhonePe, Paytm'),
    ('Card', Icons.credit_card, 'Visa, Mastercard, RuPay'),
    ('Net banking', Icons.account_balance, 'All major banks'),
    ('Cash on delivery', Icons.payments_outlined, 'Pay the rider'),
  ];

  Future<void> _pay() async {
    setState(() => _busy = true);
    final AppState app = context.read<AppState>();
    final Order order = await app.placeOrder(paymentMethod: _method);
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(Routes.orderSuccessPath(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final double walletApplied =
        _useWallet ? app.walletBalance.clamp(0, app.basketTotal) : 0;
    final double due = app.basketTotal - walletApplied;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.checkout),
        ),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (app.walletBalance > 0)
                NsCard(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('Use wallet balance',
                                style:
                                    TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${money(app.walletBalance)} available',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useWallet,
                        onChanged: (bool v) => setState(() => _useWallet = v),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Payment method'),
              ..._methods.map(
                ((String, IconData, String) m) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: NsCard(
                    borderColor: _method == m.$1
                        ? AppColors.primary
                        : AppColors.border,
                    onTap: () => setState(() => _method = m.$1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.md, vertical: Gap.sm),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _method == m.$1
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: _method == m.$1
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: Gap.md),
                        Icon(m.$2, size: 20, color: AppColors.forest),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(m.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                m.$3,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.xl),
              NsCard(
                child: Column(
                  children: <Widget>[
                    _Line(label: 'Order total', value: money(app.basketTotal)),
                    if (walletApplied > 0)
                      _Line(
                          label: 'Wallet applied',
                          value: '- ${money(walletApplied)}'),
                    const SizedBox(height: Gap.sm),
                    _Line(label: 'Amount due', value: money(due), bold: true),
                  ],
                ),
              ),
              const SizedBox(height: Gap.md),
              const Row(
                children: <Widget>[
                  Icon(Icons.lock_outline,
                      size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Payments are processed by Razorpay. Card details are '
                      'never stored by NayaSantha.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
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
              constraints: const BoxConstraints(maxWidth: 588),
              child: FilledButton(
                onPressed: _busy ? null : _pay,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Pay ${money(due)}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 18 — Order success.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final Order? order = context.watch<AppState>().orderById(orderId);

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          maxWidth: 480,
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    gradient: AppColors.leafGradient,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.check, size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(height: Gap.xl),
              Text(
                'Order placed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                order == null
                    ? 'We are preparing your basket.'
                    : 'Order #${order.id} · ${order.itemCount} items · ${money(order.total)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: Gap.xl),
              if (order != null)
                NsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Delivering to',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(order.address.label,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        order.address.oneLine,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const Divider(height: Gap.xl),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.schedule,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: Gap.sm),
                          Text(
                            'Expected by ${timeOnly(order.placedAt.add(const Duration(hours: 6)))}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(Routes.trackingPath(orderId)),
                child: const Text('Track this order'),
              ),
              const SizedBox(height: Gap.md),
              OutlinedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 19 — Delivery tracking.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final Order? order = context.watch<AppState>().orderById(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track order')),
        body: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'Order not found',
          message: 'We could not find order #$orderId.',
          actionLabel: 'See all orders',
          onAction: () => context.go(Routes.orders),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.orders),
        ),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NsCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StatusChip(
                            label: order.status.label,
                            color: order.status == OrderStatus.delivered
                                ? AppColors.success
                                : AppColors.info,
                          ),
                          const SizedBox(height: Gap.sm),
                          Text(
                            'Placed ${dayTime(order.placedAt)}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money(order.total),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              NsCard(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < order.timeline.length; i++)
                      _TimelineRow(
                        event: order.timeline[i],
                        isLast: i == order.timeline.length - 1,
                      ),
                  ],
                ),
              ),
              if (order.status == OrderStatus.outForDelivery) ...<Widget>[
                const SizedBox(height: Gap.lg),
                NsCard(
                  child: Row(
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.surfaceMuted,
                        child: Icon(Icons.person_outline,
                            color: AppColors.forest),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(order.riderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Text('Your delivery partner',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                                content:
                                    Text('Calling ${order.riderPhone}'))),
                        icon: const Icon(Icons.call, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.lg),
              SectionHeader(title: 'Items (${order.itemCount})'),
              NsCard(
                child: Column(
                  children: order.lines
                      .map(
                        (BasketLine l) => Padding(
                          padding: const EdgeInsets.only(bottom: Gap.sm),
                          child: Row(
                            children: <Widget>[
                              Text(l.product.emoji),
                              const SizedBox(width: Gap.sm),
                              Expanded(
                                child: Text(
                                  '${l.product.name} × ${l.quantity}',
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                              Text(money(l.total),
                                  style: const TextStyle(fontSize: 13.5)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final OrderEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color color =
        event.done ? AppColors.primary : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: event.done ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: event.done
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color),
                ),
            ],
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: event.done
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    event.note.isEmpty
                        ? dayTime(event.at)
                        : '${event.note} ${dayTime(event.at)}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Order history — reached from the sidebar and the profile screen.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = context.watch<AppState>().orders;

    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Your first weekly basket will show up here.',
        actionLabel: 'Open weekly plan',
        onAction: () => context.go(Routes.weeklyPlan),
      );
    }

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Your orders'),
            ...orders.map(
              (Order o) => Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: NsCard(
                  onTap: () => context.go(Routes.trackingPath(o.id)),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text('#${o.id}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: Gap.sm),
                                StatusChip(
                                  label: o.status.label,
                                  color: o.status == OrderStatus.delivered
                                      ? AppColors.success
                                      : AppColors.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${o.itemCount} items · ${dayTime(o.placedAt)}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(money(o.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: Gap.sm),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}
