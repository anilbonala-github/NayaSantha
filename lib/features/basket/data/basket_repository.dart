import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/basket_models.dart';

/// Persistent basket operations (Vol2 §6.3 add, §6.6 review). Every mutation
/// returns the full basket with server-recalculated estimate + maximum.
class BasketRepository {
  BasketRepository(this._client);
  final ApiClient _client;

  Future<Basket> current() => _wrap(() => _client.get('/baskets/current'));

  Future<Basket> addItem(String productId, {int quantity = 1}) => _wrap(
      () => _client.post('/baskets/current/items',
          body: {'productId': productId, 'quantity': quantity}));

  Future<Basket> updateItem(String itemId, {required int quantity, int? version}) =>
      _wrap(() => _client.patch('/baskets/current/items/$itemId',
          body: {'quantity': quantity, if (version != null) 'version': version}));

  Future<Basket> removeItem(String itemId) async {
    try {
      final res = await _client.patch('/baskets/current/items/$itemId',
          body: {'quantity': 0});
      return Basket.fromJson(res as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Basket> _wrap(Future<dynamic> Function() call) async {
    try {
      return Basket.fromJson(await call() as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
