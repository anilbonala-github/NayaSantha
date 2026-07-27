import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/budget_models.dart';
import 'budget_providers.dart';

/// Dynamic budget insights computed from the customer's own order history.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const List<Color> _palette = <Color>[
    AppColors.leaf,
    AppColors.info,
    AppColors.turmeric,
    AppColors.carrot,
    AppColors.primary,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(budgetInsightsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(budgetInsightsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PageBody(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(title: 'Budget insights'),
              async.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(Gap.section),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => NsCard(
                  borderColor: AppColors.danger,
                  child: Row(children: <Widget>[
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                        child: Text(e is ApiFailure
                            ? e.userMessage
                            : 'Could not load budget insights.')),
                    TextButton(
                        onPressed: () => ref.invalidate(budgetInsightsProvider),
                        child: const Text('Retry')),
                  ]),
                ),
                data: (b) => _content(context, b),
              ),
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, BudgetInsights b) {
    if (!b.hasData) {
      return NsCard(
        color: AppColors.surfaceMuted,
        borderColor: AppColors.surfaceMuted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('No spend history yet',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.sm),
            const Text(
                'Once your first weekly order is delivered and settled, you’ll see '
                'your spend trend and category breakdown here.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            if (b.weeklyBudget > 0) ...<Widget>[
              const SizedBox(height: Gap.md),
              Text('Your weekly budget: ${money(b.weeklyBudget)}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      );
    }

    final bool underBudget =
        b.weeklyBudget > 0 && b.avgWeeklySpend <= b.weeklyBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: 'Weekly budget',
                value: b.weeklyBudget > 0 ? money(b.weeklyBudget) : '—',
                icon: Icons.savings_outlined,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: _StatCard(
                label: 'Avg weekly spend',
                value: money(b.avgWeeklySpend),
                icon: Icons.timeline,
                color: b.weeklyBudget <= 0
                    ? AppColors.textPrimary
                    : (underBudget ? AppColors.success : AppColors.danger),
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: 'Last order',
                value: money(b.lastSpend),
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: _StatCard(
                label: 'Total saved',
                value: money(b.totalSaved),
                icon: Icons.trending_down,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        if (b.weeklyBudget > 0) ...<Widget>[
          const SizedBox(height: Gap.md),
          NsCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    'Within budget on ${(b.withinBudgetRate * 100).round()}% of your '
                    '${b.ordersSettled} settled ${b.ordersSettled == 1 ? 'order' : 'orders'}.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        NsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Spend by order',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: Gap.lg),
              MiniBarChart(
                values: b.recentSpend.map((p) => p.amount).toList(),
                labels: b.recentSpend.map((p) => p.label).toList(),
              ),
            ],
          ),
        ),
        if (b.categorySpend.isNotEmpty) ...<Widget>[
          const SizedBox(height: Gap.lg),
          _categoryCard(b),
        ],
      ],
    );
  }

  Widget _categoryCard(BudgetInsights b) {
    final double total =
        b.categorySpend.fold<double>(0, (s, c) => s + c.amount);
    return NsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Where it went',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: Gap.lg),
          ...List<Widget>.generate(b.categorySpend.length, (i) {
            final CategorySpend c = b.categorySpend[i];
            final double frac = total <= 0 ? 0 : c.amount / total;
            final Color color = _palette[i % _palette.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: Text(c.category,
                              style: const TextStyle(fontSize: 13.5))),
                      Text(money(c.amount),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 7,
                      backgroundColor: AppColors.surfaceMuted,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: Gap.md),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
