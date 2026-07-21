import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/ops_models.dart';
import 'ops_providers.dart';

/// Vol3/Vol2A ops & admin portal. Mirrors the admin mockup's left-nav
/// (Dashboard, Order Cutoff, Market Purchase, Price Capture, Packing, Delivery,
/// Reports, Settings). ADMIN-only — the backend rejects non-admin tokens.
class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

enum _Section { dashboard, cutoff, purchase, capture, packing, delivery, reports, settings }

class _NavItem {
  const _NavItem(this.section, this.label, this.icon, {this.ready = true});
  final _Section section;
  final String label;
  final IconData icon;
  final bool ready;
}

const List<_NavItem> _nav = <_NavItem>[
  _NavItem(_Section.dashboard, 'Dashboard', Icons.dashboard_outlined),
  _NavItem(_Section.cutoff, 'Order Cutoff', Icons.lock_clock_outlined),
  _NavItem(_Section.purchase, 'Market Purchase', Icons.shopping_cart_outlined),
  _NavItem(_Section.capture, 'Price Capture', Icons.price_change_outlined),
  _NavItem(_Section.packing, 'Packing', Icons.inventory_2_outlined, ready: false),
  _NavItem(_Section.delivery, 'Delivery', Icons.local_shipping_outlined, ready: false),
  _NavItem(_Section.reports, 'Reports', Icons.bar_chart_outlined, ready: false),
  _NavItem(_Section.settings, 'Settings', Icons.settings_outlined, ready: false),
];

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen> {
  _Section _section = _Section.dashboard;
  final Map<String, TextEditingController> _rate = <String, TextEditingController>{};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _rate.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(opsSummaryProvider);
    ref.invalidate(purchaseListProvider);
    ref.invalidate(cutoffProvider);
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.profile);
    }
  }

  TextEditingController _controllerFor(PurchaseLine line) => _rate.putIfAbsent(line.productId, () {
        final seed = line.capturedRate ?? line.forecastRate;
        return TextEditingController(text: seed == 0 ? '' : seed.toStringAsFixed(2));
      });

  // --- actions ----------------------------------------------------------------
  Future<void> _savePrices(List<PurchaseLine> lines) async {
    final Map<String, double> rates = <String, double>{};
    for (final line in lines) {
      final raw = _rate[line.productId]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final v = double.tryParse(raw);
      if (v == null || v < 0) {
        _snack('Enter a valid rate for ${line.name}', error: true);
        return;
      }
      rates[line.productId] = v;
    }
    if (rates.isEmpty) {
      _snack('Enter at least one rate first', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref.read(opsRepositoryProvider).capturePrices(rates);
      _snack('Saved ${r.captured} market rate(s)');
      _refresh();
    } on ApiFailure catch (f) {
      _snack(f.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finalize(OpsSummary s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish final prices & finalize?'),
        content: Text('This settles all ${s.lockedOrders} locked order(s) against the captured '
            'market rates. Orders over their cap move to the customer for a decision. This cannot be undone.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(opsRepositoryProvider).finalizeWeek();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Week finalized'),
          content: Text('Processed ${r.ordersProcessed} order(s).\n'
              '• Finalized within cap: ${r.finalized}\n'
              '• Awaiting customer approval: ${r.awaitingApproval}\n'
              'Total charged: ${money(r.totalFinal)}'),
          actions: <Widget>[TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      _refresh();
    } on ApiFailure catch (f) {
      _snack(f.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  // --- shell ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final bool wide = c.maxWidth >= 760;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.forestDark,
          foregroundColor: AppColors.textOnDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _exit,
          ),
          title: Row(children: <Widget>[
            const Icon(Icons.storefront, size: 20),
            const SizedBox(width: Gap.sm),
            Text('NayaSantha Admin · ${_nav.firstWhere((n) => n.section == _section).label}'),
          ]),
          actions: <Widget>[
            IconButton(onPressed: _busy ? null : _refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
          ],
        ),
        drawer: wide ? null : Drawer(child: SafeArea(child: _navList(inDrawer: true))),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (wide)
              Container(width: 210, color: AppColors.forestDark, child: _navList(inDrawer: false)),
            Expanded(child: _sectionBody()),
          ],
        ),
      );
    });
  }

  Widget _navList({required bool inDrawer}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      children: <Widget>[
        for (final item in _nav)
          _NavTile(
            item: item,
            selected: item.section == _section,
            onTap: () {
              setState(() => _section = item.section);
              if (inDrawer) Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  Widget _sectionBody() {
    switch (_section) {
      case _Section.dashboard:
        return _dashboard();
      case _Section.cutoff:
        return _cutoffSection();
      case _Section.purchase:
        return _purchaseSection();
      case _Section.capture:
        return _captureSection();
      case _Section.packing:
        return _placeholder('Packing', Icons.inventory_2_outlined,
            'Household packing waves by apartment, route and delivery window. Needs the packing/route backend (Vol2A §7.4) — not built yet.');
      case _Section.delivery:
        return _placeholder('Delivery', Icons.local_shipping_outlined,
            'Route batches, apartment drops and proof of delivery. Needs the delivery backend (Vol1 §14) — not built yet.');
      case _Section.reports:
        return _placeholder('Reports', Icons.bar_chart_outlined,
            'Fill rate, variance, on-time delivery and reconciliation reports. Needs the reporting backend — not built yet.');
      case _Section.settings:
        return _placeholder('Settings', Icons.settings_outlined,
            'Margins, buffer %, cutoff time, variance thresholds and price policy. Configurable settings — not built yet.');
    }
  }

  // --- Dashboard --------------------------------------------------------------
  Widget _dashboard() {
    final summaryAsync = ref.watch(opsSummaryProvider);
    final listAsync = ref.watch(purchaseListProvider);
    return _scroll(child: summaryAsync.when(
      loading: _loading,
      error: _error,
      data: (s) {
        final lines = listAsync.asData?.value ?? const <PurchaseLine>[];
        final itemsToPurchase = lines.fold<int>(0, (a, b) => a + b.buyQuantity);
        final alerts = lines.where((l) => l.isPriceAlert).length;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text('Week of ${s.weekStart}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Gap.md),
          Wrap(spacing: Gap.md, runSpacing: Gap.md, children: <Widget>[
            _tile('Confirmed orders', '${s.lockedOrders}', Icons.receipt_long, AppColors.forest),
            _tile('Estimated GMV', money(s.totalEstimated), Icons.payments, AppColors.info),
            _tile('Items to purchase', '$itemsToPurchase', Icons.shopping_basket, AppColors.carrot),
            _tile('Price alerts', '$alerts', Icons.warning_amber, alerts > 0 ? AppColors.danger : AppColors.success),
          ]),
          const SizedBox(height: Gap.lg),
          NsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Procurement progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            Text('${s.pricesCaptured} of ${s.distinctProducts} product rates captured · '
                '${s.households} household(s) · guaranteed max ${money(s.totalMaxPayable)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.md),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: (_busy || s.lockedOrders == 0) ? null : () => _finalize(s),
              icon: const Icon(Icons.lock_clock),
              label: Text(_busy ? 'Working…' : 'Publish final prices (${s.lockedOrders})'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            )),
          ])),
        ]);
      },
    ));
  }

  // --- Order Cutoff -----------------------------------------------------------
  Widget _cutoffSection() {
    final cutoffAsync = ref.watch(cutoffProvider);
    return _scroll(child: cutoffAsync.when(
      loading: _loading,
      error: _error,
      data: (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        const NsCard(
          color: AppColors.surfaceMuted,
          borderColor: AppColors.surfaceMuted,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Cutoff: Saturday 10:00 PM',
                style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 4),
            Text('Orders lock at cutoff. Customers can edit until then.',
                style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: Gap.md),
        Wrap(spacing: Gap.md, runSpacing: Gap.md, children: <Widget>[
          _tile('Approved', '${c.approved}', Icons.check_circle, AppColors.success),
          _tile('Pending', '${c.pending}', Icons.hourglass_bottom, AppColors.warning),
          _tile('Needs attention', '${c.needsAttention}', Icons.error_outline, AppColors.danger),
          _tile('Cancelled', '${c.cancelled}', Icons.cancel, AppColors.textSecondary),
        ]),
        const SizedBox(height: Gap.lg),
        SectionHeader(title: 'Exceptions queue (${c.exceptions.length})'),
        if (c.exceptions.isEmpty)
          const NsCard(child: EmptyState(
            icon: Icons.verified_outlined,
            title: 'No exceptions',
            message: 'Every confirmed order is within its cap and has valid payment authorization.',
          ))
        else
          NsCard(padding: const EdgeInsets.symmetric(vertical: Gap.sm), child: Column(children: <Widget>[
            for (int i = 0; i < c.exceptions.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              _exceptionRow(c.exceptions[i]),
            ],
          ])),
      ]),
    ));
  }

  Widget _exceptionRow(CutoffException ex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(children: <Widget>[
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(ex.orderRef, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(ex.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        const SizedBox(width: Gap.sm),
        StatusChip(label: ex.type.replaceAll('_', ' '), color: AppColors.warning),
      ]),
    );
  }

  // --- Market Purchase --------------------------------------------------------
  Widget _purchaseSection() {
    final listAsync = ref.watch(purchaseListProvider);
    return _scroll(child: listAsync.when(
      loading: _loading,
      error: _error,
      data: (lines) {
        if (lines.isEmpty) return _emptyBuyList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          SectionHeader(
            title: 'Consolidated purchase list',
            actionLabel: 'Export CSV',
            onAction: () => _exportCsv(lines),
          ),
          NsCard(
            padding: const EdgeInsets.all(Gap.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: Gap.xl,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Required')),
                  DataColumn(label: Text('Buffer')),
                  DataColumn(label: Text('Buy qty')),
                  DataColumn(label: Text('Max rate')),
                  DataColumn(label: Text('Status')),
                ],
                rows: <DataRow>[
                  for (final l in lines)
                    DataRow(cells: <DataCell>[
                      DataCell(Text(l.name)),
                      DataCell(Text('${l.totalQuantity} ${l.unit ?? ''}')),
                      DataCell(Text('${l.bufferPercent}%')),
                      DataCell(Text('${l.buyQuantity} ${l.unit ?? ''}')),
                      DataCell(Text(money(l.maxRate))),
                      DataCell(l.capturedRate != null
                          ? const StatusChip(label: 'Captured', color: AppColors.success)
                          : const StatusChip(label: 'Pending', color: AppColors.warning)),
                    ]),
                ],
              ),
            ),
          ),
        ]);
      },
    ));
  }

  void _exportCsv(List<PurchaseLine> lines) {
    final b = StringBuffer('Item,Unit,Required,Buffer%,BuyQty,ForecastRate,MaxRate,CapturedRate\n');
    for (final l in lines) {
      b.writeln('"${l.name}",${l.unit ?? ''},${l.totalQuantity},${l.bufferPercent},'
          '${l.buyQuantity},${l.forecastRate},${l.maxRate},${l.capturedRate ?? ''}');
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    _snack('Purchase list copied to clipboard as CSV');
  }

  // --- Price Capture ----------------------------------------------------------
  Widget _captureSection() {
    final summaryAsync = ref.watch(opsSummaryProvider);
    final listAsync = ref.watch(purchaseListProvider);
    return _scroll(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      summaryAsync.when(
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => _errorCard(e),
        data: (s) => Wrap(spacing: Gap.md, runSpacing: Gap.md, children: <Widget>[
          _tile('Rates captured', '${s.pricesCaptured}/${s.distinctProducts}', Icons.fact_check,
              s.pricesPending == 0 ? AppColors.success : AppColors.warning),
          _tile('Estimated GMV', money(s.totalEstimated), Icons.payments, AppColors.info),
        ]),
      ),
      const SizedBox(height: Gap.md),
      SectionHeader(
        title: 'Sunday market price capture',
        actionLabel: _busy ? null : 'Save',
        onAction: _busy ? null : () {
          final l = listAsync.asData?.value;
          if (l != null) _savePrices(l);
        },
      ),
      listAsync.when(
        loading: _loading,
        error: _error,
        data: (lines) => lines.isEmpty
            ? _emptyBuyList()
            : NsCard(padding: const EdgeInsets.symmetric(vertical: Gap.sm), child: Column(children: <Widget>[
                for (int i = 0; i < lines.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _captureRow(lines[i]),
                ],
              ])),
      ),
      const SizedBox(height: Gap.md),
      summaryAsync.maybeWhen(
        data: (s) => SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: (_busy || s.lockedOrders == 0) ? null : () => _finalize(s),
          icon: const Icon(Icons.publish),
          label: Text(_busy ? 'Working…' : 'Publish final prices'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
        )),
        orElse: () => const SizedBox.shrink(),
      ),
      const SizedBox(height: Gap.section),
    ]));
  }

  Widget _captureRow(PurchaseLine line) {
    final v = line.variance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(children: <Widget>[
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(line.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text('${line.totalQuantity} × ${line.unit ?? 'unit'} · forecast ${money(line.forecastRate)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        if (v != null) ...<Widget>[
          StatusChip(
            label: '${v >= 0 ? '+' : ''}${(v * 100).toStringAsFixed(1)}%',
            color: line.isPriceAlert ? AppColors.danger : AppColors.textSecondary,
            icon: line.isPriceAlert ? Icons.warning_amber : null,
          ),
          const SizedBox(width: Gap.sm),
        ],
        SizedBox(
          width: 104,
          child: TextField(
            controller: _controllerFor(line),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: '₹',
              isDense: true,
              labelText: 'actual',
              border: const OutlineInputBorder(),
              filled: line.capturedRate != null,
              fillColor: AppColors.surfaceMuted,
            ),
          ),
        ),
      ]),
    );
  }

  // --- shared bits ------------------------------------------------------------
  Widget _scroll({required Widget child}) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageBody(maxWidth: 980, child: child),
        ),
      );

  Widget _loading() => const Padding(
      padding: EdgeInsets.all(Gap.section), child: Center(child: CircularProgressIndicator()));

  Widget _error(Object e, StackTrace _) => _errorCard(e);

  Widget _tile(String label, String value, IconData icon, Color color) => Container(
        width: 190,
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Icon(icon, size: 18, color: color),
            const Spacer(),
          ]),
          const SizedBox(height: Gap.sm),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      );

  Widget _emptyBuyList() => const NsCard(child: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No locked orders yet',
        message: 'Once customers lock their weekly plans, the consolidated buy list appears here for Sunday procurement.',
      ));

  Widget _placeholder(String title, IconData icon, String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: EmptyState(icon: icon, title: title, message: message),
        ),
      );

  Widget _errorCard(Object e) {
    final msg = e is ApiFailure ? e.userMessage : 'Something went wrong';
    return NsCard(
      borderColor: AppColors.danger,
      child: Row(children: <Widget>[
        const Icon(Icons.error_outline, color: AppColors.danger),
        const SizedBox(width: Gap.sm),
        Expanded(child: Text(msg)),
        TextButton(onPressed: _refresh, child: const Text('Retry')),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.forest : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(item.icon, size: 20, color: AppColors.textOnDark),
        title: Text(item.label,
            style: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        trailing: item.ready
            ? null
            : const Text('soon', style: TextStyle(color: Color(0x99F3F8F1), fontSize: 10)),
        onTap: onTap,
      ),
    );
  }
}
