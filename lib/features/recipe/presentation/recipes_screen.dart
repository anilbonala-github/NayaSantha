import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../basket/presentation/basket_providers.dart';
import '../domain/recipe_models.dart';
import 'recipe_providers.dart';

/// Dynamic recipes: list from /recipes; tap opens ingredients + add-to-basket.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(recipesProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PageBody(maxWidth: 1000, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Recipes'),
            const Text('Tap a recipe to add its ingredients to your basket in one go.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.lg),
            async.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(Gap.section),
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => NsCard(
                borderColor: AppColors.danger,
                child: Row(children: <Widget>[
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(e is ApiFailure ? e.userMessage : 'Could not load recipes.')),
                  TextButton(onPressed: () => ref.invalidate(recipesProvider), child: const Text('Retry')),
                ]),
              ),
              data: (recipes) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 150,
                  crossAxisSpacing: Gap.md,
                  mainAxisSpacing: Gap.md,
                ),
                itemCount: recipes.length,
                itemBuilder: (c, i) => _recipeCard(context, recipes[i]),
              ),
            ),
            const SizedBox(height: Gap.section),
          ],
        )),
      ),
    );
  }

  Widget _recipeCard(BuildContext context, RecipeSummary r) {
    return NsCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
        builder: (_) => _RecipeSheet(recipeId: r.id),
      ),
      child: Row(children: <Widget>[
        Text(r.emoji ?? '🍽️', style: const TextStyle(fontSize: 34)),
        const SizedBox(width: Gap.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          if (r.cuisine != null)
            StatusChip(label: r.cuisine!, color: AppColors.forest),
          const SizedBox(height: 6),
          Text('${r.ingredientCount} ingredients · ${r.prepMinutes} min · serves ${r.servings}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]),
    );
  }
}

class _RecipeSheet extends ConsumerStatefulWidget {
  const _RecipeSheet({required this.recipeId});
  final String recipeId;
  @override
  ConsumerState<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends ConsumerState<_RecipeSheet> {
  bool _busy = false;

  Future<void> _addAll() async {
    setState(() => _busy = true);
    try {
      await ref.read(recipeRepositoryProvider).addToBasket(widget.recipeId);
      ref.invalidate(basketProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ingredients added to your basket'), backgroundColor: AppColors.success));
      }
    } on ApiFailure catch (f) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.userMessage), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recipeDetailProvider(widget.recipeId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scroll) => async.when(
        loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(
          height: 200,
          child: Center(child: Text(e is ApiFailure ? e.userMessage : 'Could not load recipe.')),
        ),
        data: (r) => Column(children: <Widget>[
          Expanded(child: ListView(controller: scroll, padding: const EdgeInsets.all(Gap.xl), children: <Widget>[
            Row(children: <Widget>[
              Text(r.emoji ?? '🍽️', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: Gap.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(r.title, style: Theme.of(context).textTheme.titleLarge),
                Text('${r.cuisine ?? ''} · ${r.prepMinutes} min · serves ${r.servings}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
            ]),
            if (r.description != null) ...<Widget>[
              const SizedBox(height: Gap.md),
              Text(r.description!, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
            ],
            const SizedBox(height: Gap.lg),
            const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: Gap.sm),
            for (final ing in r.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: <Widget>[
                  Text(ing.emoji ?? '•', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: Gap.md),
                  Expanded(child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('${ing.quantity} × ${ing.unit ?? ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              ),
          ])),
          SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _busy ? null : _addAll,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(_busy ? 'Adding…' : 'Add all to basket'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            )),
          )),
        ]),
      ),
    );
  }
}
