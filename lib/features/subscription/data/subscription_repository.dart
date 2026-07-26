import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/subscription_models.dart';

/// Membership plans + subscription for the signed-in customer.
class SubscriptionRepository {
  SubscriptionRepository(this._client);
  final ApiClient _client;

  Future<List<MembershipPlan>> plans() async {
    try {
      final data = await _client.get('/subscription-plans') as List;
      return data.map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Current active membership, or null when on the free/basic plan.
  Future<CurrentSubscription?> current() async {
    try {
      final data = await _client.get('/subscriptions/current');
      return data == null ? null : CurrentSubscription.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> subscribe(String planCode) async {
    try {
      await _client.post('/subscriptions', body: {'planCode': planCode});
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> cancel() async {
    try {
      await _client.post('/subscriptions/cancel');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
