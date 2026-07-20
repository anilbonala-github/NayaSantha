import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/pantry_models.dart';

/// Pantry CRUD (Vol2 §6.4). Stock/expiry status comes from the server.
class PantryRepository {
  PantryRepository(this._client);
  final ApiClient _client;

  Future<List<PantryItem>> list() async {
    try {
      final data = await _client.get('/pantry') as List;
      return data.map((e) => PantryItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PantryItem> add({
    required String name,
    required double quantity,
    String? unit,
    String? productId,
    double lowStockThreshold = 1,
    String? expiryDate,
  }) async {
    try {
      final data = await _client.post('/pantry/items', body: {
        'name': name,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (productId != null) 'productId': productId,
        'lowStockThreshold': lowStockThreshold,
        if (expiryDate != null) 'expiryDate': expiryDate,
      });
      return PantryItem.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PantryItem> updateQuantity(
      {required String id, required String name, required double quantity, int? version}) async {
    try {
      final data = await _client.patch('/pantry/items/$id', body: {
        'name': name,
        'quantity': quantity,
        if (version != null) 'version': version,
      });
      return PantryItem.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> remove(String id) => _client.delete('/pantry/items/$id');
}
