import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../catalogue/presentation/catalogue_providers.dart';
import '../../pantry/presentation/pantry_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../profile/presentation/profile_providers.dart';

/// Dynamic dashboard (Vol2 §6.2): composed from the plan, pantry and catalogue
/// providers. Replaces the mock HomeScreen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).maybeWhen(
        data: (p) => p.displayName, orElse: () => 'there');
    final suggestions = ref.watch(pantrySuggestionsProvider);

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: Gap.lg),
            Text('Hello, $name',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.forest)),
            const Text('Here is your week at a glance.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.lg),

            _PlanCard(),
            const SizedBox(height: Gap.lg),

            if (suggestions.isNotEmpty) ...<Widget>[
              _PantryAlertCard(count: suggestions.length,
                  names: suggestions.take(3).map((i) => i.name).toList()),
              const SizedBox(height: Gap.lg),
            ],

            _BrowseCard(),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weeklyPlanProvider);
    return NsCard(
      onTap: () => context.go(Routes.weeklyPlan),
      child: planAsync.when(
        loading: () => const SizedBox(
            height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => _cta(context, ref, 'Plan your week',
            'Generate an AI weekly basket within your budget.'),
        data: (plan) => plan == null
            ? _cta(context, ref, 'Plan your week',
                'Generate an AI weekly basket within your budget.')
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(children: <Widget>[
                  const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('This week\'s AI plan',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  StatusChip(
                      label: plan.aiSource == 'GEMINI' ? 'Gemini' : 'Smart plan',
                      color: AppColors.forest),
                ]),
                const SizedBox(height: Gap.md),
                Row(children: <Widget>[
                  _metric('Estimated', '₹${plan.estimatedTotal.toStringAsFixed(0)}'),
                  const SizedBox(width: Gap.xl),
                  _metric('Guaranteed max', '₹${plan.maximumPayable.toStringAsFixed(0)}'),
                  const SizedBox(width: Gap.xl),
                  _metric('Items', '${plan.itemCount}'),
                ]),
                const SizedBox(height: Gap.md),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('Review & approve  →',
                      style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w700)),
                ),
              ]),
      ),
    );
  }

  Widget _cta(BuildContext context, WidgetRef ref, String title, String body) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: Gap.md),
      FilledButton(
        onPressed: () => ref.read(weeklyPlanProvider.notifier).generate(),
        child: const Text('Generate weekly plan'),
      ),
    ]);
  }

  Widget _metric(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _PantryAlertCard extends StatelessWidget {
  const _PantryAlertCard({required this.count, required this.names});
  final int count;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return NsCard(
      onTap: () => context.go(Routes.pantry),
      child: Row(children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.carrot.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Radii.md)),
          child: const Icon(Icons.notifications_active_outlined, color: AppColors.carrot),
        ),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('$count pantry item${count == 1 ? '' : 's'} need attention',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(names.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]),
    );
  }
}

class _BrowseCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return NsCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          const Text('Browse the market', style: TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(
              onPressed: () => context.go(Routes.categories),
              child: const Text('See all')),
        ]),
        categoriesAsync.when(
          loading: () => const SizedBox(
              height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
          data: (cats) => Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: cats
                .map((c) => ActionChip(
                      label: Text('${c.emoji ?? ''} ${c.name}'.trim()),
                      backgroundColor: AppColors.surfaceMuted,
                      onPressed: () => context.go(Routes.categories),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }
}
