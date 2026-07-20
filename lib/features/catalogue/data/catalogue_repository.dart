import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/catalogue_models.dart';

/// Reads categories, products and search results from the backend (Vol2 §6.3).
class CatalogueRepository {
  CatalogueRepository(this._client);
  final ApiClient _client;

  Future<List<Category>> categories() async {
    try {
      final data = await _client.get('/categories') as List;
      return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<ProductPage> products({
    String? categoryId,
    String? query,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final data = await _client.get('/products', query: {
        if (categoryId != null) 'category': categoryId,
        if (query != null && query.isNotEmpty) 'query': query,
        'page': page,
        'size': size,
      });
      return ProductPage.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Product> product(String id) async {
    try {
      return Product.fromJson(await _client.get('/products/$id') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<Product>> suggestions(String query) async {
    if (query.trim().isEmpty) return const <Product>[];
    try {
      final data = await _client.get('/search/suggestions', query: {'query': query}) as List;
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
