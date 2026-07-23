import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/order_models.dart';

/// Order lifecycle operations (Vol2A §11): approve, settlement, decision, capture.
class OrderRepository {
  OrderRepository(this._client);
  final ApiClient _client;

  /// Approve a plan with price consent → creates the order (Vol2A §6.2).
  Future<CustomerOrder> approve(
    String planId, {
    required String pricePreference,
    double? maxPayable,
    bool substitutionConsent = true,
    String? deviceInfo,
  }) =>
      _wrap(() => _client.post('/weekly-plans/$planId/approve', body: {
            'pricePreference': pricePreference,
            if (maxPayable != null) 'maxPayable': maxPayable,
            'substitutionConsent': substitutionConsent,
            if (deviceInfo != null) 'deviceInfo': deviceInfo,
          }));

  Future<CustomerOrder> get(String orderId) =>
      _wrap(() => _client.get('/orders/$orderId'));

  Future<List<CustomerOrder>> list() async {
    try {
      final data = await _client.get('/orders') as List;
      return data.map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// DEV: simulate the Sunday market settlement (real ops portal is Vol3).
  Future<CustomerOrder> simulateSettlement(String orderId) =>
      _wrap(() => _client.post('/orders/$orderId/simulate-settlement'));

  Future<CustomerOrder> decide(String orderId, String decision) =>
      _wrap(() => _client.post('/orders/$orderId/price-decision', body: {'decision': decision}));

  Future<CustomerOrder> capture(String orderId) =>
      _wrap(() => _client.post('/payments/$orderId/capture'));

  /// Ask the backend to create a Razorpay order for this order's final amount.
  /// Returns {configured, keyId, razorpayOrderId, amount, currency, ...}.
  Future<Map<String, dynamic>> createRazorpayOrder(String orderId) async {
    try {
      final data = await _client.post('/payments/razorpay/order', body: {'orderId': orderId});
      return (data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Post the checkout signature back for server-side verification + capture.
  Future<void> verifyRazorpay({
    required String orderId,
    required String razorpayOrderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      await _client.post('/payments/razorpay/verify', body: {
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': paymentId,
        'razorpaySignature': signature,
      });
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<CustomerOrder> _wrap(Future<dynamic> Function() call) async {
    try {
      return CustomerOrder.fromJson(await call() as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
