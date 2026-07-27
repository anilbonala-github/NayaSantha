import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/coupon_models.dart';

/// Coupon catalogue for the offers screen.
class CouponRepository {
  CouponRepository(this._client);
  final ApiClient _client;

  Future<List<Coupon>> list() async {
    try {
      final data = await _client.get('/coupons') as List;
      return data.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
