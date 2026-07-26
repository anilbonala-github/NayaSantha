import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/recipe_models.dart';

/// Recipes + add-ingredients-to-basket.
class RecipeRepository {
  RecipeRepository(this._client);
  final ApiClient _client;

  Future<List<RecipeSummary>> list() async {
    try {
      final data = await _client.get('/recipes') as List;
      return data.map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<RecipeDetail> get(String id) async {
    try {
      return RecipeDetail.fromJson(await _client.get('/recipes/$id') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Adds all of a recipe's ingredients to the basket.
  Future<void> addToBasket(String id) async {
    try {
      await _client.post('/recipes/$id/add-to-basket');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
