import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/wallet_models.dart';

/// Wallet reads for the signed-in customer.
class WalletRepository {
  WalletRepository(this._client);
  final ApiClient _client;

  Future<Wallet> get() async {
    try {
      return Wallet.fromJson(await _client.get('/wallet') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<WalletTx>> transactions() async {
    try {
      final data = await _client.get('/wallet/transactions') as List;
      return data.map((e) => WalletTx.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
