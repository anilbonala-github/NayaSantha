import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/referral_models.dart';

/// Referral code + apply for the signed-in customer.
class ReferralRepository {
  ReferralRepository(this._client);
  final ApiClient _client;

  Future<ReferralInfo> code() async {
    try {
      return ReferralInfo.fromJson(await _client.get('/referrals/code') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<ApplyReferralResult> apply(String code) async {
    try {
      final data = await _client.post('/referrals/apply', body: {'code': code});
      return ApplyReferralResult.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
