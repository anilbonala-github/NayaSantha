import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe_models.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>(
    (ref) => RecipeRepository(ref.watch(apiClientProvider)));

final recipesProvider = FutureProvider<List<RecipeSummary>>(
    (ref) => ref.watch(recipeRepositoryProvider).list());

final recipeDetailProvider = FutureProvider.autoDispose.family<RecipeDetail, String>(
    (ref, id) => ref.watch(recipeRepositoryProvider).get(id));
