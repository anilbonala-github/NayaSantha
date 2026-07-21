import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/ops_models.dart';
import 'ops_providers.dart';

/// Vol3 ops/admin portal. Sunday procurement flow: review the consolidated buy
/// list, capture the real market rates, then finalize every locked order against
/// them. ADMIN-only — the backend rejects non-admin tokens.
class OpsScreen extends ConsumerStatefulWidget {
  const OpsScreen({super.key});

  @override
  ConsumerState<OpsScreen> createState() => _OpsScreenState();
}

class _OpsScreenState extends ConsumerState<OpsScreen> {
  final Map<String, TextEditingController> _rate = <String, TextEditingController>{};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _rate.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(PurchaseLine line) {
    return _rate.putIfAbsent(line.productId, () {
      final seed = line.capturedRate ?? line.forecastRate;
      return TextEditingController(text: seed == 0 ? '' : seed.toStringAsFixed(2));
    });
  }

  void _refresh() {
    ref.invalidate(opsSummaryProvider);
    ref.invalidate(purchaseListProvider);
  }

  Future<void> _savePrices(List<PurchaseLine> lines) async {
    final Map<String, double> rates = <String, double>{};
    for (final line in lines) {
      final raw = _rate[line.productId]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final value = double.tryParse(raw);
      if (value == null || value < 0) {
        _snack('Enter a valid rate for ${line.name}', error: true);
        return;
      }
      rates[line.productId] = value;
    }
    if (rates.isEmpty) {
      _snack('Enter at least one rate first', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(opsRepositoryProvider).capturePrices(rates);
      _snack('Saved ${result.captured} market rate(s)');
      _refresh();
    } on ApiFailure catch (f) {
      _snack(f.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finalize(OpsSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize the week?'),
        content: Text(
          'This settles all ${summary.lockedOrders} locked order(s) against the '
          'captured market rates. Orders over their cap will move to the customer '
          'for a decision. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalize')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final r = await ref.read(opsRepositoryProvider).finalizeWeek();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Week finalized'),
          content: Text(
            'Processed ${r.ordersProcessed} order(s).\n'
            '• Finalized within cap: ${r.finalized}\n'
            '• Awaiting customer approval: ${r.awaitingApproval}\n'
            'Total charged: ${money(r.totalFinal)}',
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
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

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(opsSummaryProvider);
    final listAsync = ref.watch(purchaseListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ops portal'),
        backgroundColor: AppColors.forestDark,
        foregroundColor: AppColors.textOnDark,
        actions: <Widget>[
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageBody(
            maxWidth: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                summaryAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(Gap.xl),
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => _errorCard(e),
                  data: _summaryCard,
                ),
                const SizedBox(height: Gap.lg),
                SectionHeader(
                  title: 'Consolidated buy list',
                  actionLabel: _busy ? null : 'Save prices',
                  onAction: _busy
                      ? null
                      : () {
                          final lines = listAsync.asData?.value;
                          if (lines != null) _savePrices(lines);
                        },
                ),
                listAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(Gap.xl),
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => _errorCard(e),
                  data: _buyList,
                ),
                const SizedBox(height: Gap.section),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(OpsSummary s) {
    return NsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.event_note, color: AppColors.forest),
              const SizedBox(width: Gap.sm),
              Text('Week of ${s.weekStart}',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              StatusChip(
                label: s.readyToFinalize ? 'Ready to finalize' : '${s.pricesPending} rates pending',
                color: s.readyToFinalize ? AppColors.success : AppColors.warning,
                icon: s.readyToFinalize ? Icons.check_circle : Icons.pending,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Wrap(
            spacing: Gap.xl,
            runSpacing: Gap.md,
            children: <Widget>[
              _stat('Locked orders', '${s.lockedOrders}'),
              _stat('Households', '${s.households}'),
              _stat('Products', '${s.distinctProducts}'),
              _stat('Rates captured', '${s.pricesCaptured}/${s.distinctProducts}'),
              _stat('Estimated total', money(s.totalEstimated)),
              _stat('Guaranteed max', money(s.totalMaxPayable)),
            ],
          ),
          const SizedBox(height: Gap.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_busy || s.lockedOrders == 0) ? null : () => _finalize(s),
              icon: const Icon(Icons.lock_clock),
              label: Text(_busy ? 'Working…' : 'Finalize week (${s.lockedOrders})'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            ),
          ),
          if (!s.readyToFinalize && s.distinctProducts > 0)
            Padding(
              padding: const EdgeInsets.only(top: Gap.sm),
              child: Text(
                'Tip: capture all ${s.distinctProducts} rates below for an accurate settlement. '
                'Missing rates fall back to the forecast price.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buyList(List<PurchaseLine> lines) {
    if (lines.isEmpty) {
      return const NsCard(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No locked orders yet',
          message: 'Once customers lock their weekly plans, the consolidated buy '
              'list appears here for Sunday procurement.',
        ),
      );
    }
    return NsCard(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < lines.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _buyRow(lines[i]),
          ],
        ],
      ),
    );
  }

  Widget _buyRow(PurchaseLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(line.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${line.totalQuantity} × ${line.unit ?? 'unit'} · '
                  'forecast ${money(line.forecastRate)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.md),
          SizedBox(
            width: 108,
            child: TextField(
              controller: _controllerFor(line),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.right,
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
        ],
      ),
    );
  }

  Widget _errorCard(Object e) {
    final msg = e is ApiFailure ? e.userMessage : 'Something went wrong';
    return NsCard(
      borderColor: AppColors.danger,
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: Gap.sm),
          Expanded(child: Text(msg)),
          TextButton(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }
}
