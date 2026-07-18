import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../state/assistant_state.dart';

/// 20 — AI assistant.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    context.read<AssistantState>().send(text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AssistantState assistant = context.watch<AssistantState>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: const Row(
          children: <Widget>[
            Text('AI assistant'),
            SizedBox(width: Gap.sm),
            AiBadge(label: 'Beta'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Start a new conversation',
            icon: const Icon(Icons.refresh),
            onPressed: assistant.clear,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(Gap.lg),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ...assistant.messages.map(_bubble),
                        if (assistant.thinking) _thinking(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (assistant.messages.length <= 1)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                children: AssistantState.quickPrompts
                    .map(
                      (String p) => Padding(
                        padding: const EdgeInsets.only(right: Gap.sm),
                        child: ActionChip(
                          label: Text(p),
                          onPressed: () => _send(p),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _input,
                            textInputAction: TextInputAction.send,
                            decoration: const InputDecoration(
                              hintText: 'Ask about meals, budget or orders',
                              fillColor: AppColors.background,
                            ),
                            onSubmitted: _send,
                          ),
                        ),
                        const SizedBox(width: Gap.sm),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(50, 50),
                          ),
                          onPressed: () => _send(_input.text),
                          icon: const Icon(Icons.arrow_upward, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final bool user = m.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: Gap.md),
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg, vertical: Gap.md),
        decoration: BoxDecoration(
          color: user ? AppColors.forest : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.lg),
            topRight: const Radius.circular(Radii.lg),
            bottomLeft: Radius.circular(user ? Radii.lg : 4),
            bottomRight: Radius.circular(user ? 4 : Radii.lg),
          ),
          border: Border.all(
            color: user ? AppColors.forest : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              m.text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: user ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (m.bullets.isNotEmpty) ...<Widget>[
              const SizedBox(height: Gap.md),
              ...List<Widget>.generate(
                m.bullets.length,
                (int i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      Expanded(
                        child: Text(m.bullets[i],
                            style: const TextStyle(fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (m.action != null) ...<Widget>[
              const SizedBox(height: Gap.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => _runAction(m.action!),
                  icon: Icon(m.action!.icon, size: 17),
                  label: Text(m.action!.label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Assistant suggestions are only useful if acting on them is one tap.
  void _runAction(ChatAction action) {
    if (action.productIds.isNotEmpty) {
      final AppState app = context.read<AppState>();
      for (final String id in action.productIds) {
        app.addToBasket(MockData.byId(id));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${action.productIds.length} items added to your basket'),
          action: SnackBarAction(
            label: 'View basket',
            textColor: Colors.white,
            onPressed: () => context.go(Routes.basket),
          ),
        ),
      );
      return;
    }
    final String? route = action.route;
    if (route != null) context.go(route);
  }

  Widget _thinking() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.md),
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg, vertical: Gap.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: Gap.md),
            Text('Thinking',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// 21 — Pantry. Two views: what you hold now, and what the planner thinks
/// you should restock.
class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    if (app.pantry.isEmpty) {
      return EmptyState(
        icon: Icons.kitchen_outlined,
        title: 'Your pantry is empty',
        message:
            'Add what you already have so the planner does not buy it twice.',
        actionLabel: 'Add an item',
        onAction: () => _addSheet(context, app),
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
                  maxWidth: 900,
                  padding:
                      const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Pantry (${app.pantry.length})',
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      TextButton.icon(
                        onPressed: () => _addSheet(context, app),
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: AppColors.forest,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: <Widget>[
                    Tab(text: 'My pantry'),
                    Tab(text: 'Smart suggestions'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _PantryList(app: app),
                _SmartSuggestions(app: app),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _addSheet(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (BuildContext c) => SizedBox(
        height: MediaQuery.sizeOf(c).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Text('Add to pantry',
                  style: Theme.of(c).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                children: MockData.products
                    .map(
                      (Product p) => ListTile(
                        leading: ProduceAvatar(emoji: p.emoji, size: 38),
                        title: Text(p.name),
                        subtitle: Text(p.unit),
                        onTap: () {
                          app.addPantryItem(
                            PantryItem(
                              product: p,
                              quantityLabel: p.unit,
                              expiresOn: DateTime.now()
                                  .add(const Duration(days: 14)),
                            ),
                          );
                          Navigator.of(c).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryList extends StatelessWidget {
  const _PantryList({required this.app});

  final AppState app;

  Color _stockColor(StockLevel s) => switch (s) {
        StockLevel.good => AppColors.success,
        StockLevel.low => AppColors.carrot,
        StockLevel.out => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NsCard(
              color: AppColors.surfaceMuted,
              borderColor: AppColors.surfaceMuted,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.notifications_active_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: Gap.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Never run out again',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text(
                          'Track what you hold and we will restock it in '
                          'the next plan before it runs out.',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
            NsCard(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < app.pantry.length; i++) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md),
                      child: Row(
                        children: <Widget>[
                          ProduceAvatar(
                              emoji: app.pantry[i].product.emoji, size: 42),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(app.pantry[i].product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  app.pantry[i].quantityLabel,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              StatusChip(
                                label: app.pantry[i].stock.label,
                                color: _stockColor(app.pantry[i].stock),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                app.pantry[i].daysLeft <= 0
                                    ? 'Use today'
                                    : '${app.pantry[i].daysLeft} days left',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: app.pantry[i].isExpiringSoon
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 17),
                            onPressed: () => app
                                .removePantryItem(app.pantry[i].product.id),
                          ),
                        ],
                      ),
                    ),
                    if (i != app.pantry.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

/// Restock suggestions, derived from stock level and expiry rather than
/// generic bestsellers — the reason is always shown so the advice is auditable.
class _SmartSuggestions extends StatelessWidget {
  const _SmartSuggestions({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final List<PantryItem> flagged = app.pantry
        .where((PantryItem p) => p.needsAttention)
        .toList();

    if (flagged.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Nothing needs restocking',
        message:
            'Everything in your pantry is stocked and well inside its date.',
      );
    }

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('${flagged.length} items to act on',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: Gap.sm),
                const AiBadge(),
              ],
            ),
            const SizedBox(height: Gap.md),
            ...flagged.map(
              (PantryItem item) => Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: NsCard(
                  child: Row(
                    children: <Widget>[
                      ProduceAvatar(emoji: item.product.emoji, size: 44),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              item.stock != StockLevel.good
                                  ? 'Running low — ${item.quantityLabel}'
                                  : 'Expires in ${item.daysLeft} days',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(78, 36),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () {
                          app.addToBasket(item.product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${item.product.name} added to basket')),
                          );
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
            FilledButton.icon(
              onPressed: () {
                for (final PantryItem item in flagged) {
                  app.addToBasket(item.product);
                }
                context.go(Routes.basket);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text('Add all ${flagged.length} to basket'),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

/// 22 — Recipes.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Recipes from your pantry'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 178,
                crossAxisSpacing: Gap.md,
                mainAxisSpacing: Gap.md,
              ),
              itemCount: MockData.recipes.length,
              itemBuilder: (BuildContext c, int i) {
                final Recipe r = MockData.recipes[i];
                return NsCard(
                  onTap: () => _openRecipe(context, r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          ProduceAvatar(emoji: r.emoji, size: 44),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(r.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                Text(
                                  '${r.minutes} min · serves ${r.servings} · ${r.calories} kcal',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: r.tags
                            .map((String t) => StatusChip(
                                label: t, color: AppColors.primary))
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }

  void _openRecipe(BuildContext context, Recipe r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (BuildContext c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (BuildContext c, ScrollController sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(Gap.xl),
          children: <Widget>[
            Row(
              children: <Widget>[
                ProduceAvatar(emoji: r.emoji, size: 54),
                const SizedBox(width: Gap.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(r.name,
                          style: Theme.of(c).textTheme.headlineSmall),
                      Text(
                        '${r.minutes} min · serves ${r.servings} · ${r.calories} kcal per serving',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const Text('Ingredients',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: Gap.md),
            ...r.ingredients.map(
              (String i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('· '),
                    Expanded(child: Text(i)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.xl),
            const Text('Method',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: Gap.md),
            ...List<Widget>.generate(
              r.steps.length,
              (int i) => Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                        child: Text(r.steps[i],
                            style: const TextStyle(height: 1.5))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
          ],
        ),
      ),
    );
  }
}

/// 23 — Budget insights.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    const List<double> weekly = <double>[1420, 1180, 1560, 1286];
    const List<String> labels = <String>['W1', 'W2', 'W3', 'W4'];
    final double avg =
        weekly.reduce((double a, double b) => a + b) / weekly.length;

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Budget insights'),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'Weekly budget',
                    value: money(app.weeklyBudget),
                    icon: Icons.savings_outlined,
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: _StatCard(
                    label: '4-week average',
                    value: money(avg),
                    icon: Icons.timeline,
                    color: avg <= app.weeklyBudget
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            NsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Spend by week',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Gap.lg),
                  const MiniBarChart(values: weekly, labels: labels),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
            NsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text('Where it went',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const AiBadge(),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  ...const <(String, double, Color)>[
                    ('Fruits & Veg', 0.35, AppColors.leaf),
                    ('Dairy & Eggs', 0.24, AppColors.info),
                    ('Grains & Pulses', 0.22, AppColors.turmeric),
                    ('Snacks & Other', 0.19, AppColors.carrot),
                  ].map(
                    ((String, double, Color) row) => Padding(
                      padding: const EdgeInsets.only(bottom: Gap.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                  child: Text(row.$1,
                                      style: const TextStyle(fontSize: 13.5))),
                              Text(
                                '${(row.$2 * 100).round()}%',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: LinearProgressIndicator(
                              value: row.$2,
                              minHeight: 7,
                              backgroundColor: AppColors.surfaceMuted,
                              color: row.$3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
            NsCard(
              color: AppColors.surfaceMuted,
              borderColor: AppColors.surfaceMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.lightbulb_outline,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: Gap.sm),
                      const Text('Ways to save next week',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  ...const <String>[
                    'Buy atta in the 5 kg pack — saves ₹38 a month',
                    'Tomato prices are down 18% this week',
                    'You bought 2 L more milk than you used last week',
                  ].map(
                    (String s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.arrow_right,
                              size: 18, color: AppColors.textSecondary),
                          Expanded(
                            child: Text(s,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
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
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
