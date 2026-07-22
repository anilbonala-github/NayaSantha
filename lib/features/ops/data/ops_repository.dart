import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/ops_models.dart';

/// Vol3 ops portal endpoints (ADMIN-only on the backend). All money math stays
/// server-owned; this repo only reports the buy list and submits captured rates.
class OpsRepository {
  OpsRepository(this._client);
  final ApiClient _client;

  Future<OpsSummary> summary() async {
    try {
      return OpsSummary.fromJson(await _client.get('/ops/summary') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<PurchaseLine>> purchaseList() async {
    try {
      final data = await _client.get('/ops/purchase-list') as List;
      return data.map((e) => PurchaseLine.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Cutoff> cutoff() async {
    try {
      return Cutoff.fromJson(await _client.get('/ops/cutoff') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Upsert the real Sunday rates ({productId: actualRate}).
  Future<CaptureResult> capturePrices(Map<String, double> rates) async {
    try {
      final prices = rates.entries
          .map((e) => {'productId': e.key, 'actualRate': e.value})
          .toList();
      final data = await _client.post('/ops/prices', body: {'prices': prices});
      return CaptureResult.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<FinalizeResult> finalizeWeek() async {
    try {
      final data = await _client.post('/ops/finalize');
      return FinalizeResult.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Manually fire the Saturday cutoff reminders. Returns how many were sent.
  Future<int> runReminder() async {
    try {
      final data = await _client.post('/ops/run-reminder') as Map<String, dynamic>;
      return (data['remindersSent'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Manually run the cutoff — lock all confirmed orders. Returns how many were locked.
  Future<int> runCutoff() async {
    try {
      final data = await _client.post('/ops/run-cutoff') as Map<String, dynamic>;
      return (data['ordersLocked'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PackingSummary> packing() async {
    try {
      return PackingSummary.fromJson(await _client.get('/ops/packing') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<DeliverySummary> delivery() async {
    try {
      return DeliverySummary.fromJson(await _client.get('/ops/delivery') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> pack(String orderId) => _act('/ops/orders/$orderId/pack');
  Future<void> dispatch(String orderId) => _act('/ops/orders/$orderId/dispatch');
  Future<void> deliver(String orderId) => _act('/ops/orders/$orderId/deliver');

  Future<void> _act(String path) async {
    try {
      await _client.post(path);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
