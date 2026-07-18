import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// 11 — AI Weekly Plan. Two views: the shopping lines and the 21-meal calendar.
class WeeklyPlanScreen extends StatelessWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final WeeklyPlan? plan = app.plan;

    if (app.planLoading) {
      return const _PlanLoading();
    }

    if (plan == null) {
      return Center(
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'No plan for this week yet',
          message:
              'We will size quantities for your household and keep the total '
              'under ${money(app.weeklyBudget)}.',
          actionLabel: 'Create my plan',
          onAction: () => context.read<AppState>().generatePlan(),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Material(
            color: AppColors.surface,
            child: Column(
              children: <Widget>[
                PageBody(
                  maxWidth: 1080,
                  padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
                  child: _PlanSummary(plan: plan),
                ),
                const TabBar(
                  labelColor: AppColors.forest,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: <Widget>[
                    Tab(text: 'Shopping list'),
                    Tab(text: 'Meals'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _PlanLines(plan: plan),
                _MealCalendar(plan: plan),
              ],
            ),
          ),
          _PlanFooter(plan: plan),
        ],
      ),
    );
  }
}

class _PlanLoading extends StatelessWidget {
  const _PlanLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          SizedBox(height: Gap.xl),
          Text('Planning your week',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: Gap.sm),
          Text(
            'Balancing nutrition, budget and what is already in your pantry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(plan.headline,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const AiBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${shortDate(plan.weekStart)} – ${shortDate(plan.weekEnd)}',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: Gap.md),
        const _FamilyStrip(),
        const SizedBox(height: Gap.md),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: plan.rationale
              .map((String r) => StatusChip(
                    label: r,
                    color: AppColors.success,
                    icon: Icons.check,
                  ))
              .toList(),
        ),
        const SizedBox(height: Gap.md),
      ],
    );
  }
}

class _PlanLines extends StatelessWidget {
  const _PlanLines({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 1080,
        child: Column(
          children: <Widget>[
            ...plan.lines.map(
              (PlanLine line) => Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: NsCard(
                  padding: const EdgeInsets.all(Gap.md),
                  onTap: () =>
                      context.go(Routes.productPath(line.product.id)),
                  child: Row(
                    children: <Widget>[
                      ProduceAvatar(emoji: line.product.emoji, size: 44),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              line.product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${line.quantity} × ${line.product.unit} · ${money(line.total)}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                const Icon(Icons.auto_awesome,
                                    size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    line.reason,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      QuantityStepper(
                        quantity: line.quantity,
                        compact: true,
                        onChanged: (int v) => app.updatePlanLineQuantity(
                            line.product.id, v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.xl),
            _TopRecommendations(plan: plan),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

class _MealCalendar extends StatelessWidget {
  const _MealCalendar({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final List<String> days = <String>[];
    for (final Meal m in plan.meals) {
      if (!days.contains(m.day)) days.add(m.day);
    }

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 1080,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...days.map((String day) {
              final List<Meal> meals =
                  plan.meals.where((Meal m) => m.day == day).toList();
              final int total =
                  meals.fold<int>(0, (int a, Meal m) => a + m.calories);
              return Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: NsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(day,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const Spacer(),
                          Text(
                            '$total kcal per person',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Divider(height: Gap.xl),
                      ...meals.map(
                        (Meal m) => Padding(
                          padding: const EdgeInsets.only(bottom: Gap.md),
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 76,
                                child: Text(
                                  m.slot,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(m.name,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                              Text(
                                '${m.calories} kcal',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

class _PlanFooter extends StatelessWidget {
  const _PlanFooter({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    final double total =
        plan.lines.fold<double>(0, (double a, PlanLine l) => a + l.total);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: PageBody(
          maxWidth: 1080,
          padding: const EdgeInsets.all(Gap.lg),
          child: Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    money(total),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${plan.itemCount} items · saves ${money(plan.savings)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    app.addPlanToBasket();
                    context.go(Routes.basket);
                  },
                  child: const Text('Add all to basket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows who the plan was sized for. Quantities are meaningless without this
/// context, so it sits directly under the headline.
class _FamilyStrip extends StatelessWidget {
  const _FamilyStrip();

  @override
  Widget build(BuildContext context) {
    final List<FamilyMember> family = context.watch<AppState>().family;
    return Row(
      children: <Widget>[
        Text(
          'Planned for your family (${family.length})',
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
        const SizedBox(width: Gap.md),
        ...family.take(6).map(
              (FamilyMember m) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: '${m.name} · ${m.ageGroup.label}',
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.surfaceMuted,
                    child: Text(
                      m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Items the planner considered but did not add — one tap to include them.
class _TopRecommendations extends StatelessWidget {
  const _TopRecommendations({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Set<String> inPlan =
        plan.lines.map((PlanLine l) => l.product.id).toSet();
    final List<Product> extras = app.recommended
        .where((Product p) => !inPlan.contains(p.id))
        .toList();

    if (extras.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Top recommendations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: Gap.sm),
            const AiBadge(),
          ],
        ),
        const SizedBox(height: Gap.sm),
        const Text(
          'Considered for this week but not added yet.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: Gap.md),
        ...extras.take(4).map(
              (Product p) => Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: NsCard(
                  padding: const EdgeInsets.all(Gap.md),
                  child: Row(
                    children: <Widget>[
                      ProduceAvatar(emoji: p.emoji, size: 40),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${p.unit} · ${money(p.price)}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(70, 34),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () {
                          app.addToBasket(p);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${p.name} added')),
                          );
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
