import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/budget_models.dart';

/// Budget insights from the customer's order history.
class BudgetRepository {
  BudgetRepository(this._client);
  final ApiClient _client;

  Future<BudgetInsights> get() async {
    try {
      return BudgetInsights.fromJson(await _client.get('/budget-insights') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
