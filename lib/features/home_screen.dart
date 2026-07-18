import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../core/widgets/product_widgets.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../state/assistant_state.dart';

/// 10 — Dashboard. The week at a glance: plan status, delivery, quick reorder.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final bool wide = Breakpoints.isDesktop(context);

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 1180,
        padding: EdgeInsets.all(wide ? Gap.xl : Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!wide) _MobileHeader(app: app),
            if (!wide) const SizedBox(height: Gap.lg),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 7, child: _MainColumn(app: app)),
                  const SizedBox(width: Gap.xl),
                  SizedBox(width: 300, child: _SideColumn(app: app)),
                ],
              )
            else ...<Widget>[
              _MainColumn(app: app),
              const SizedBox(height: Gap.xl),
              _SideColumn(app: app),
            ],
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Hello, ${app.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      app.defaultAddress.line2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go(Routes.search),
          icon: const Icon(Icons.search),
        ),
        Stack(
          children: <Widget>[
            IconButton(
              onPressed: () => context.go(Routes.notifications),
              icon: const Icon(Icons.notifications_none),
            ),
            if (app.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.tomato,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _PlanBanner(),
        const SizedBox(height: Gap.xl),
        SectionHeader(
          title: 'Shop by category',
          actionLabel: 'View all',
          onAction: () => context.go(Routes.categories),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisExtent: 104,
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
          ),
          itemCount: MockData.categories.length,
          itemBuilder: (BuildContext c, int i) {
            final Category cat = MockData.categories[i];
            return NsCard(
              padding: const EdgeInsets.all(Gap.sm),
              onTap: () => context.go('${Routes.categories}?id=${cat.id}'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ProduceAvatar(
                    emoji: cat.emoji,
                    size: 44,
                    background: cat.tint.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: Gap.xl),
        const SectionHeader(title: 'Best for you'),
        ProductGrid(
          products: app.recommended,
          onOpen: (Product p) => context.go(Routes.productPath(p.id)),
        ),
      ],
    );
  }
}

class _PlanBanner extends StatelessWidget {
  const _PlanBanner();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final WeeklyPlan? plan = app.plan;

    return Container(
      padding: const EdgeInsets.all(Gap.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFFEAF6E6), Color(0xFFF6FBF4)],
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AiBadge(label: 'AI weekly plan'),
              const Spacer(),
              if (plan != null)
                Text(
                  '${shortDate(plan.weekStart)} – ${shortDate(plan.weekEnd)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            plan == null
                ? 'Plan your week in one tap'
                : 'Your plan is ready for ${app.family.length}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppColors.forest),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            plan == null
                ? 'We size every quantity to your household and keep the total '
                    'under ${money(app.weeklyBudget)}.'
                : plan.rationale.take(2).join(' · '),
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: Gap.lg),
          if (plan != null)
            Row(
              children: <Widget>[
                _Metric(label: 'Items', value: '${plan.itemCount}'),
                const SizedBox(width: Gap.xl),
                _Metric(
                    label: 'Estimated', value: money(plan.estimatedCost)),
                const SizedBox(width: Gap.xl),
                _Metric(
                  label: 'You save',
                  value: money(plan.savings),
                  color: AppColors.success,
                ),
              ],
            ),
          if (plan != null) const SizedBox(height: Gap.lg),
          Row(
            children: <Widget>[
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 44),
                ),
                onPressed: () async {
                  if (plan == null) {
                    await context.read<AppState>().generatePlan();
                  }
                  if (context.mounted) context.go(Routes.weeklyPlan);
                },
                child: Text(plan == null ? 'Create my plan' : 'View plan'),
              ),
              const SizedBox(width: Gap.md),
              if (app.planLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final Order? active = app.activeOrder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (active != null) ...<Widget>[
          NsCard(
            onTap: () => context.go(Routes.trackingPath(active.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('Upcoming delivery',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    StatusChip(
                      label: active.status.label,
                      color: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  'Order #${active.id} · ${active.itemCount} items',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: <Widget>[
                    const Icon(Icons.schedule,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Today, ${timeOnly(active.placedAt.add(const Duration(hours: 9)))}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
        ],
        if (app.expiringSoon.isNotEmpty) ...<Widget>[
          NsCard(
            onTap: () => context.go(Routes.pantry),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.kitchen_outlined,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: Gap.sm),
                    const Text('Use these first',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    StatusChip(
                      label: '${app.expiringSoon.length}',
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                ...app.expiringSoon.take(3).map(
                      (PantryItem p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: <Widget>[
                            Text(p.product.emoji),
                            const SizedBox(width: Gap.sm),
                            Expanded(
                              child: Text(p.product.name,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Text(
                              p.daysLeft <= 0
                                  ? 'Today'
                                  : '${p.daysLeft} days',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
        ],
        const _AssistantCard(),
      ],
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard();

  @override
  Widget build(BuildContext context) {
    return NsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppColors.leafGradient,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: Gap.md),
              const Expanded(
                child: Text('AI assistant',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          const Text(
            'Ask about meals, budgets or what to cook tonight.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: Gap.md),
          ...AssistantState.quickPrompts.map(
            (String p) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.sm),
                onTap: () {
                  context.read<AssistantState>().send(p);
                  context.go(Routes.assistant);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Gap.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(p,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
