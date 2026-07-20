import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/plan_models.dart';

/// AI weekly plan operations (Vol2 §6.5). The server validates and owns totals.
class PlanRepository {
  PlanRepository(this._client);
  final ApiClient _client;

  Future<WeeklyPlan> generate() =>
      _wrap(() => _client.post('/weekly-plans/generate'));

  /// Returns null when the household has no plan yet (backend 404 NOT_FOUND).
  Future<WeeklyPlan?> current() async {
    try {
      return WeeklyPlan.fromJson(
          await _client.get('/weekly-plans/current') as Map<String, dynamic>);
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.errorCode == 'NOT_FOUND') return null;
      throw failure;
    }
  }

  Future<WeeklyPlan> setItemQuantity(
      String planId, String itemId, int quantity, {int? version}) {
    return _wrap(() => _client.patch('/weekly-plans/$planId/items/$itemId',
        body: {'quantity': quantity, if (version != null) 'version': version}));
  }

  Future<WeeklyPlan> _wrap(Future<dynamic> Function() call) async {
    try {
      return WeeklyPlan.fromJson(await call() as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
